import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/excel_service.dart';
import '../services/storage_service.dart';

/// مدیریت central state اپلیکیشن
/// - نگهداری لیست کالاها
/// - نگهداری شمارنده‌های اسکن
/// - عملیات: بارگذاری فایل، اسکن، ریست
class AppState extends ChangeNotifier {
  final ExcelService _excelService = ExcelService();
  final StorageService _storageService = StorageService();

  List<Product> _products = [];
  Map<String, int> _scanCounts = {};
  String? _excelFileName;
  bool _loading = false;
  String? _error;

  // کش برای جستجوی سریع بارکد در کالاها
  final Map<String, Product> _productsByCode = {};

  List<Product> get products => List.unmodifiable(_products);
  Map<String, int> get scanCounts => Map.unmodifiable(_scanCounts);
  String? get excelFileName => _excelFileName;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasFile => _products.isNotEmpty;

  /// آیا همه کالاها به تعداد لازم اسکن شده‌اند؟
  bool get isFullyComplete {
    if (_products.isEmpty) return false;
    for (final p in _products) {
      if (scannedCountFor(p.code) < p.requiredCount) return false;
    }
    return true;
  }

  /// بارگذاری وضعیت ذخیره‌شده در ابتدای برنامه
  Future<void> initialize() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _storageService.loadProducts();
      _scanCounts = await _storageService.loadScanStates();
      _excelFileName = await _storageService.getExcelFileName();
      _rebuildCache();
    } catch (e) {
      _error = 'خطا در بارگذاری داده‌ها: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// بارگذاری فایل اکسل جدید (جایگزین فایل قبلی)
  /// اگر قبلاً کالایی اسکن شده بود، شمارنده برای کالای جدید صفر می‌شود
  Future<bool> loadExcelFile(String filePath, {String? fileName}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final products = await _excelService.readProducts(filePath);

      // ذخیره شمارنده‌های قدیمی برای کالاهایی که در فایل جدید هم هستند
      final oldCounts = Map<String, int>.from(_scanCounts);
      final newCounts = <String, int>{};
      for (final p in products) {
        newCounts[p.code] = oldCounts[p.code] ?? 0;
      }

      _products = products;
      _scanCounts = newCounts;
      _excelFileName = fileName ?? filePath.split('/').last;
      _rebuildCache();

      await _storageService.saveProducts(_products, fileName: _excelFileName);
      await _storageService.saveScanStates(_scanCounts);
      _loading = false;
      notifyListeners();
      return true;
    } on ExcelException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'خطا در بارگذاری فایل: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// جستجوی کالا با کد
  /// بازگشت: کالا یا null اگر پیدا نشد
  Product? findProduct(String code) {
    if (code.isEmpty) return null;
    return _productsByCode[code];
  }

  /// ثبت یک اسکن برای کالای مشخص
  /// بازگشت:
  /// - ScanResult.notFound : کالا در شارژ سالن نیست
  /// - ScanResult.alreadyComplete : شارژ این کالا قبلاً کامل شده
  /// - ScanResult.scanned : با موفقیت اسکن شد (شمارنده افزایش پیدا کرد)
  /// - ScanResult.justCompleted : این اسکن باعث تکمیل شارژ شد
  Future<ScanResult> recordScan(String code) async {
    final product = findProduct(code);
    if (product == null) {
      return ScanResult.notFound;
    }

    final required = product.requiredCount;
    final current = _scanCounts[code] ?? 0;

    if (required > 0 && current >= required) {
      return ScanResult.alreadyComplete;
    }

    final newCount = current + 1;
    _scanCounts[code] = newCount;
    await _storageService.saveScanStates(_scanCounts);
    notifyListeners();

    if (required > 0 && newCount >= required) {
      return ScanResult.justCompleted;
    }
    return ScanResult.scanned;
  }

  /// تعداد اسکن‌شده برای یک کالا
  int scannedCountFor(String code) => _scanCounts[code] ?? 0;

  /// ریست شمارنده‌ها (لیست کالاها باقی می‌ماند)
  Future<void> resetCounters() async {
    _scanCounts.clear();
    await _storageService.resetScanStates();
    notifyListeners();
  }

  /// حذف کامل داده‌ها (لیست کالاها و شمارنده‌ها)
  Future<void> clearAll() async {
    _products = [];
    _scanCounts = {};
    _excelFileName = null;
    _productsByCode.clear();
    await _storageService.clearAll();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _rebuildCache() {
    _productsByCode.clear();
    for (final p in _products) {
      if (p.code.isNotEmpty) {
        _productsByCode[p.code] = p;
      }
    }
  }
}

/// نتیجه عملیات اسکن
enum ScanResult {
  /// کالا پیدا نشد
  notFound,

  /// اسکن شد و شمارنده افزایش یافت
  scanned,

  /// این اسکن باعث تکمیل شارژ شد
  justCompleted,

  /// شارژ این کالا قبلاً کامل شده و افزایش نمی‌یابد
  alreadyComplete,
}
