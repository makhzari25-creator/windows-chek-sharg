import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// سرویس خواندن فایل اکسل
///
/// این سرویس به‌جای استفاده از پکیج `excel` که در نسخه 4.0.6 باگ دارد
/// (در فایل‌هایی که مسیر شیت با `/` ابتدایی در workbook.xml.rels ذخیره شده)،
/// مستقیم فایل XLSX را با استفاده از پکیج `archive` و XML parsing می‌خواند.
///
/// پشتیبانی:
/// - فرمت XLSX (Office Open XML)
/// - Strings در sharedStrings.xml و inlineStr
/// - ستون‌ها از روی نام تشخیص داده می‌شوند نه شماره ستون
class ExcelService {
  // نام‌های ممکن برای ستون کد محصول
  static const _codeHeaders = [
    'کد محصول', 'كد محصول', 'کد کالا', 'كد كالا', 'کد', 'كد',
    'barcode', 'code', 'product code', 'sku',
  ];

  // نام‌های ممکن برای ستون عنوان محصول
  static const _titleHeaders = [
    'عنوان محصول', 'عنوان', 'نام محصول', 'نام کالا', 'نام', 'توضیحات',
    'product', 'title', 'name', 'description',
  ];

  // نام‌های ممکن برای ستون تعداد
  static const _countHeaders = [
    'تعداد', 'تعداد مورد نیاز', 'تعداد اسکن', 'مقدار', 'تعداد لازم',
    'count', 'quantity', 'qty', 'amount',
  ];

  /// خواندن فایل اکسل و بازگشت لیست کالاها
  Future<List<Product>> readProducts(String filePath) async {
    try {
      final ext = filePath.toLowerCase().split('.').last;

      if (ext == 'xls') {
        // فرمت xls قدیمی (BIFF) پشتیبانی نمی‌شود
        throw ExcelException(
          'فرمت xls قدیمی پشتیبانی نمی‌شود. '
          'لطفاً فایل را در Excel/LibreOffice با فرمت xlsx ذخیره کنید.',
        );
      } else if (ext == 'xlsx') {
        return await _readXlsx(filePath);
      } else {
        throw ExcelException('فرمت فایل پشتیبانی نمی‌شود: .$ext');
      }
    } on ExcelException {
      rethrow;
    } catch (e) {
      throw ExcelException('خطا در خواندن فایل: $e');
    }
  }

  /// خواندن فایل XLSX با استفاده از پکیج archive و parsing مستقیم XML
  Future<List<Product>> _readXlsx(String filePath) async {
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    // پیدا کردن workbook.xml و sharedStrings.xml
    final workbookFile = _findFile(archive, 'xl/workbook.xml');
    if (workbookFile == null) {
      throw ExcelException('فایل اکسل معتبر نیست: workbook.xml یافت نشد.');
    }

    final workbookContent = utf8.decode(workbookFile.content as List<int>);
    final workbookXml = _parseXml(workbookContent);

    // پیدا کردن نام شیت‌ها و ترتیب آن‌ها
    final sheetNames = <String>[];
    final workbookRels = <String, String>{}; // rId -> target

    final wbRoot = _findChild(workbookXml, 'workbook') ?? workbookXml;
    final sheetsEl = _findChild(wbRoot, 'sheets');
    if (sheetsEl != null) {
      for (final sheetEl in _findChildren(sheetsEl, 'sheet')) {
        final name = sheetEl.getAttribute('name');
        final rId = sheetEl.getAttribute(
            'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
            'id');
        if (name != null) {
          sheetNames.add(name);
          if (rId != null) workbookRels[name] = rId;
        }
      }
    }

    if (sheetNames.isEmpty) {
      throw ExcelException('هیچ شیتی در فایل اکسل پیدا نشد.');
    }

    // خواندن workbook.xml.rels برای پیدا کردن مسیر فایل‌های شیت
    final relsFile = _findFile(archive, 'xl/_rels/workbook.xml.rels');
    final rIdToTarget = <String, String>{};
    if (relsFile != null) {
      final relsContent = utf8.decode(relsFile.content as List<int>);
      final relsXml = _parseXml(relsContent);
      for (final relEl in _findChildren(relsXml, 'Relationship')) {
        final id = relEl.getAttribute('Id');
        final target = relEl.getAttribute('Target');
        if (id != null && target != null) {
          // نرمال‌سازی مسیر: حذف "/" ابتدایی و prefix "xl/"
          String normalizedTarget = target;
          if (normalizedTarget.startsWith('/')) {
            normalizedTarget = normalizedTarget.substring(1);
          }
          // اگر مسیر نسبی است (مثل worksheets/sheet1.xml)، با xl/ ترکیب می‌شود
          if (!normalizedTarget.startsWith('xl/') &&
              !normalizedTarget.startsWith('/xl/')) {
            normalizedTarget = 'xl/$normalizedTarget';
          }
          rIdToTarget[id] = normalizedTarget;
        }
      }
    }

    // پیدا کردن sharedStrings.xml (اگر وجود دارد)
    final sharedStrings = <String>[];
    final ssFile = _findFile(archive, 'xl/sharedStrings.xml');
    if (ssFile != null) {
      final ssContent = utf8.decode(ssFile.content as List<int>);
      final ssXml = _parseXml(ssContent);
      // rootElement خودش ممکن است sst باشد (با یا بدون پیشوند namespace مثل x:sst)
      final sstEl =
          _localName(ssXml.name) == 'sst' ? ssXml : _findChild(ssXml, 'sst');
      if (sstEl != null) {
        for (final siEl in _findChildren(sstEl, 'si')) {
          sharedStrings.add(_extractStringFromSi(siEl));
        }
      }
    }

    // استفاده از اولین شیت
    final firstSheetName = sheetNames.first;
    final firstRId = workbookRels[firstSheetName];
    String? sheetPath;
    if (firstRId != null && rIdToTarget.containsKey(firstRId)) {
      sheetPath = rIdToTarget[firstRId];
    } else {
      // fallback: جستجوی مستقیم فایل sheet1.xml
      sheetPath = 'xl/worksheets/sheet1.xml';
    }

    final sheetFile = _findFile(archive, sheetPath!);
    if (sheetFile == null) {
      // fallback: جستجوی هر فایلی که با worksheet/sheet شروع می‌شود
      for (final f in archive) {
        if (f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml')) {
          sheetPath = f.name;
          break;
        }
      }
      final fallbackFile = _findFile(archive, sheetPath!);
      if (fallbackFile == null) {
        throw ExcelException('فایل شیت اکسل پیدا نشد.');
      }
      return _parseSheet(utf8.decode(fallbackFile.content as List<int>),
          sharedStrings);
    }

    final sheetContent = utf8.decode(sheetFile.content as List<int>);
    return _parseSheet(sheetContent, sharedStrings);
  }

  /// parse کردن محتوای شیت و استخراج کالاها
  List<Product> _parseSheet(String sheetContent, List<String> sharedStrings) {
    final sheetXml = _parseXml(sheetContent);
    final worksheetEl = _localName(sheetXml.name) == 'worksheet'
        ? sheetXml
        : _findChild(sheetXml, 'worksheet') ?? sheetXml;
    final sheetDataEl = _findChild(worksheetEl, 'sheetData');
    if (sheetDataEl == null) {
      throw ExcelException('هیچ داده‌ای در شیت اکسل پیدا نشد.');
    }

    final rows = _findChildren(sheetDataEl, 'row');
    if (rows.isEmpty) {
      throw ExcelException('شیت اکسل خالی است.');
    }

    // یافتن سطر هدر
    int headerRowIndex = -1;
    int? codeCol;
    int? titleCol;
    int? countCol;

    for (int r = 0; r < rows.length; r++) {
      final cells = _findChildren(rows[r], 'c');
      int? foundCode, foundTitle, foundCount;

      for (final cell in cells) {
        final ref = cell.getAttribute('r') ?? '';
        final colLetter = _extractColLetter(ref);
        if (colLetter.isEmpty) continue;
        final colIdx = _colLetterToIndex(colLetter);

        final value = _getCellValue(cell, sharedStrings);
        final normalizedValue = _normalizeHeader(value);

        if (foundCode == null &&
            _codeHeaders
                .map(_normalizeHeader)
                .contains(normalizedValue)) {
          foundCode = colIdx;
        }
        if (foundTitle == null &&
            _titleHeaders
                .map(_normalizeHeader)
                .contains(normalizedValue)) {
          foundTitle = colIdx;
        }
        if (foundCount == null &&
            _countHeaders
                .map(_normalizeHeader)
                .contains(normalizedValue)) {
          foundCount = colIdx;
        }
      }

      if (foundCode != null && foundTitle != null) {
        headerRowIndex = r;
        codeCol = foundCode;
        titleCol = foundTitle;
        countCol = foundCount;
        break;
      }
    }

    if (headerRowIndex == -1 || codeCol == null || titleCol == null) {
      throw ExcelException(
        'ستون‌های مورد نیاز پیدا نشدند. '
        'باید ستون‌های "کد محصول" و "عنوان محصول" در فایل وجود داشته باشند.',
      );
    }

    // خواندن داده‌ها از سطرهای بعد از هدر
    final products = <Product>[];
    for (int r = headerRowIndex + 1; r < rows.length; r++) {
      final cells = _findChildren(rows[r], 'c');

      // ساخت map از colIdx -> value برای این سطر
      final cellMap = <int, String>{};
      for (final cell in cells) {
        final ref = cell.getAttribute('r') ?? '';
        final colLetter = _extractColLetter(ref);
        if (colLetter.isEmpty) continue;
        final colIdx = _colLetterToIndex(colLetter);
        cellMap[colIdx] = _getCellValue(cell, sharedStrings);
      }

      final code = (cellMap[codeCol] ?? '').trim();
      final title = (cellMap[titleCol] ?? '').trim();
      final countStr = (cellMap[countCol] ?? '').trim();

      if (code.isEmpty && title.isEmpty) continue;

      int requiredCount = 0;
      if (countStr.isNotEmpty) {
        requiredCount =
            int.tryParse(countStr.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
      }

      products.add(Product(
        code: code,
        title: title.isEmpty ? '-' : title,
        requiredCount: requiredCount,
      ));
    }

    if (products.isEmpty) {
      throw ExcelException('هیچ کالایی در فایل پیدا نشد.');
    }

    debugPrint('ExcelService: ${products.length} کالا از فایل خوانده شد.');
    return products;
  }

  /// استخراج مقدار یک سلول
  String _getCellValue(XmlElement cell, List<String> sharedStrings) {
    final type = cell.getAttribute('t');

    // اگر نوع inlineStr است، داخل <is><t>value</t></is> قرار دارد
    if (type == 'inlineStr') {
      final isEl = _findChild(cell, 'is');
      if (isEl != null) {
        return _extractStringFromSi(isEl);
      }
    }

    // اگر نوع "s" (shared string) است، داخل <v>index</v> قرار دارد
    if (type == 's') {
      final vEl = _findChild(cell, 'v');
      if (vEl != null) {
        final idx = int.tryParse(vEl.text.trim());
        if (idx != null && idx >= 0 && idx < sharedStrings.length) {
          return sharedStrings[idx];
        }
      }
      return '';
    }

    // در غیر این صورت، مقدار داخل <v> قرار دارد (عدد، تاریخ، ...)
    final vEl = _findChild(cell, 'v');
    if (vEl != null) {
      return vEl.text;
    }

    return '';
  }

  /// استخراج متن از یک عنصر <si> یا <is>
  /// ممکن است شامل چند <t> باشد (rich text)
  String _extractStringFromSi(XmlElement siEl) {
    final buffer = StringBuffer();

    void collectText(XmlElement el) {
      // اگر این عنصر خودش <t> است (با یا بدون پیشوند namespace مثل x:t)
      if (_localName(el.name) == 't') {
        buffer.write(el.text);
      }
      // پیمایش فرزندان
      for (final child in el.children) {
        if (child is XmlElement) {
          collectText(child);
        }
      }
    }

    collectText(siEl);
    return buffer.toString();
  }

  /// حذف پیشوند namespace از نام تگ (مثلاً "x:row" -> "row")
  /// بعضی فایل‌های اکسل (مثل خروجی برخی نرم‌افزارها) همه تگ‌ها را با
  /// پیشوند namespace ذخیره می‌کنند (x:worksheet, x:row, x:c, x:sst, x:si, x:t ...)
  /// و بدون این تابع، مقایسه نام‌ها با تساوی دقیق شکست می‌خورد.
  String _localName(String name) {
    final idx = name.indexOf(':');
    return idx == -1 ? name : name.substring(idx + 1);
  }

  /// پیدا کردن اولین فرزند با نام مشخص (مستقل از پیشوند namespace)
  XmlElement? _findChild(XmlElement parent, String name) {
    for (final child in parent.children) {
      if (child is XmlElement && _localName(child.name) == name) {
        return child;
      }
    }
    return null;
  }

  /// پیدا کردن همه فرزندان با نام مشخص (مستقل از پیشوند namespace)
  List<XmlElement> _findChildren(XmlElement parent, String name) {
    final result = <XmlElement>[];
    for (final child in parent.children) {
      if (child is XmlElement && _localName(child.name) == name) {
        result.add(child);
      }
    }
    return result;
  }

  /// پیدا کردن فایل در archive با نام دقیق یا case-insensitive
  ArchiveFile? _findFile(Archive archive, String path) {
    // جستجوی دقیق
    for (final f in archive) {
      if (f.name == path) return f;
    }
    // جستجوی case-insensitive
    for (final f in archive) {
      if (f.name.toLowerCase() == path.toLowerCase()) return f;
    }
    return null;
  }

  /// استخراج حروف ستون از مرجع سلول (مثلاً "B12" -> "B")
  String _extractColLetter(String ref) {
    final buffer = StringBuffer();
    for (int i = 0; i < ref.length; i++) {
      final ch = ref[i];
      if ((ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) ||
          (ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122)) {
        buffer.write(ch.toUpperCase());
      } else {
        break;
      }
    }
    return buffer.toString();
  }

  /// تبدیل حرف ستون به ایندکس (A=0, B=1, ..., Z=25, AA=26, ...)
  int _colLetterToIndex(String letter) {
    int result = 0;
    for (int i = 0; i < letter.length; i++) {
      result = result * 26 + (letter.codeUnitAt(i) - 64);
    }
    return result - 1;
  }

  String _normalizeHeader(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک');
  }

  /// parser ساده XML - نیازی به پکیج اضافی ندارد چون از xml در dart:core استفاده می‌کنیم
  /// اما برای سادگی، از پکیج xml استفاده می‌کنیم که در dart:core نیست
  /// بنابراین یک parser دستی می‌نویسیم
  XmlElement _parseXml(String content) {
    return XmlDocument.parse(content).rootElement;
  }
}

/// کلاس‌های ساده XML برای parsing
abstract class XmlNode {}

class XmlElement extends XmlNode {
  final String name;
  final List<XmlNode> children = [];
  final Map<String, String> _attributes = {};

  XmlElement(this.name);

  void setAttribute(String name, String value) {
    _attributes[name] = value;
  }

  String? getAttribute(String name, [String? namespace]) {
    if (namespace != null) {
      final namespacedKey = '$namespace:$name';
      if (_attributes.containsKey(namespacedKey)) {
        return _attributes[namespacedKey];
      }
    }
    // جستجوی attribute با همین نام محلی
    for (final entry in _attributes.entries) {
      // attr name می‌تواند به صورت "namespace:name" یا فقط "name" باشد
      if (entry.key == name ||
          entry.key.endsWith(':$name')) {
        return entry.value;
      }
    }
    return _attributes[name];
  }

  String get text {
    final buffer = StringBuffer();
    for (final child in children) {
      if (child is XmlText) {
        buffer.write(child.text);
      } else if (child is XmlElement) {
        buffer.write(child.text);
      }
    }
    return buffer.toString();
  }
}

class XmlText extends XmlNode {
  final String text;
  XmlText(this.text);
}

class XmlDocument {
  final XmlElement rootElement;
  XmlDocument(this.rootElement);

  static XmlDocument parse(String input) {
    final parser = _SimpleXmlParser(input);
    return parser.parse();
  }
}

/// Parser ساده XML که برای نیازهای ما کافی است
class _SimpleXmlParser {
  final String input;
  int pos = 0;

  _SimpleXmlParser(this.input);

  XmlDocument parse() {
    // skip XML declaration و DOCTYPE و comments و processing instructions
    while (pos < input.length) {
      _skipWhitespace();
      if (pos >= input.length) break;
      if (input[pos] == '<') {
        if (_startsWith('<?xml')) {
          _skipUntil('?>');
          pos += 2;
        } else if (_startsWith('<!--')) {
          _skipUntil('-->');
          pos += 3;
        } else if (_startsWith('<!')) {
          _skipUntil('>');
          pos += 1;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    _skipWhitespace();
    final root = _parseElement();
    return XmlDocument(root);
  }

  XmlElement _parseElement() {
    if (pos >= input.length || input[pos] != '<') {
      throw Exception('Expected < at position $pos');
    }
    pos++; // skip <
    final name = _parseName();
    final element = XmlElement(name);

    // parse attributes
    while (true) {
      _skipWhitespace();
      if (pos >= input.length) break;
      if (input[pos] == '/') {
        // self-closing tag
        pos++; // skip /
        if (pos < input.length && input[pos] == '>') pos++;
        return element;
      }
      if (input[pos] == '>') {
        pos++; // skip >
        break;
      }
      // parse attribute
      final attrName = _parseName();
      _skipWhitespace();
      if (pos < input.length && input[pos] == '=') {
        pos++; // skip =
        _skipWhitespace();
        final attrValue = _parseAttributeValue();
        element.setAttribute(attrName, attrValue);
      }
    }

      // parse children
    while (true) {
      // پیدا کردن شروع فرزند یا تگ پایان
      while (pos < input.length) {
        if (input[pos] == '<') {
          if (_startsWith('<!--')) {
            _skipUntil('-->');
            pos += 3;
          } else if (_startsWith('<![CDATA[')) {
            pos += 9; // skip <![CDATA[
            final end = input.indexOf(']]>', pos);
            if (end == -1) {
              element.children.add(XmlText(input.substring(pos)));
              pos = input.length;
            } else {
              element.children.add(XmlText(input.substring(pos, end)));
              pos = end + 3;
            }
          } else if (pos + 1 < input.length && input[pos + 1] == '/') {
            // end tag
            pos += 2; // skip </
            _parseName(); // consume tag name
            _skipWhitespace();
            if (pos < input.length && input[pos] == '>') pos++;
            return element;
          } else {
            // child element
            final child = _parseElement();
            element.children.add(child);
          }
        } else {
          // text content
          final textStart = pos;
          while (pos < input.length && input[pos] != '<') {
            pos++;
          }
          final text = _decodeXmlEntities(input.substring(textStart, pos));
          if (text.trim().isNotEmpty) {
            element.children.add(XmlText(text));
          }
        }
      }
      if (pos >= input.length) break;
    }

    return element;
  }

  String _parseName() {
    final start = pos;
    while (pos < input.length) {
      final code = input.codeUnitAt(pos);
      // حروف، اعداد، زیرخط، خط تیره، نقطه، دو نقطه، و کاراکترهای غیر ASCII (مثل فارسی)
      final isAlphaNumeric =
          (code >= 65 && code <= 90) ||   // A-Z
          (code >= 97 && code <= 122) ||  // a-z
          (code >= 48 && code <= 57) ||   // 0-9
          code == 58 ||                    // :
          code == 95 ||                    // _
          code == 45 ||                    // -
          code == 46 ||                    // .
          code > 127;                      // unicode chars
      if (isAlphaNumeric) {
        pos++;
      } else {
        break;
      }
    }
    return input.substring(start, pos);
  }

  String _parseAttributeValue() {
    if (pos >= input.length) return '';
    final quote = input[pos];
    if (quote != '"' && quote != "'") {
      // unquoted - rare
      final start = pos;
      while (pos < input.length) {
        final code = input.codeUnitAt(pos);
        if (code == 32 || code == 62 || code == 47) break; // space, >, /
        pos++;
      }
      return _decodeXmlEntities(input.substring(start, pos));
    }
    pos++; // skip quote
    final start = pos;
    while (pos < input.length && input[pos] != quote) {
      pos++;
    }
    final value = input.substring(start, pos);
    if (pos < input.length) pos++; // skip closing quote
    return _decodeXmlEntities(value);
  }

  void _skipWhitespace() {
    while (pos < input.length) {
      final code = input.codeUnitAt(pos);
      if (code == 32 || code == 9 || code == 10 || code == 13) {
        // space, tab, newline, carriage return
        pos++;
      } else {
        break;
      }
    }
  }

  void _skipUntil(String marker) {
    final idx = input.indexOf(marker, pos);
    if (idx == -1) {
      pos = input.length;
    } else {
      pos = idx;
    }
  }

  bool _startsWith(String prefix) {
    if (pos + prefix.length > input.length) return false;
    return input.substring(pos, pos + prefix.length) == prefix;
  }

  String _decodeXmlEntities(String s) {
    // ابتدا entityهای استاندارد
    var result = s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');

    // سپس entityهای عددی مثل &#1705; یا &#x06A9;
    final numericPattern = RegExp(r'&#(x?[0-9a-fA-F]+);');
    result = result.replaceAllMapped(numericPattern, (match) {
      final codeStr = match.group(1)!;
      int code;
      if (codeStr.startsWith('x') || codeStr.startsWith('X')) {
        code = int.parse(codeStr.substring(1), radix: 16);
      } else {
        code = int.parse(codeStr);
      }
      return String.fromCharCode(code);
    });

    return result;
  }
}

class ExcelException implements Exception {
  final String message;
  ExcelException(this.message);

  @override
  String toString() => message;
}
