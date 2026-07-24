import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

/// سرویس ذخیره‌سازی دائمی وضعیت کالاها و شمارنده‌ها
/// با بستن برنامه اطلاعات از بین نمی‌رود
class StorageService {
  static const _productsKey = 'products_list';
  static const _scanStatesKey = 'scan_states';
  static const _excelFileNameKey = 'excel_file_name';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// ذخیره لیست کالاها (همراه با اطلاعات فایل اکسل)
  Future<void> saveProducts(List<Product> products, {String? fileName}) async {
    final prefs = await _getPrefs();
    final jsonList = products.map((p) => p.toJson()).toList();
    await prefs.setString(_productsKey, jsonEncode(jsonList));
    if (fileName != null) {
      await prefs.setString(_excelFileNameKey, fileName);
    }
  }

  /// بارگذاری لیست کالاها
  Future<List<Product>> loadProducts() async {
    final prefs = await _getPrefs();
    final str = prefs.getString(_productsKey);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// ذخیره شمارنده‌های اسکن
  Future<void> saveScanStates(Map<String, int> scanCounts) async {
    final prefs = await _getPrefs();
    final list = scanCounts.entries
        .map((e) => ScanState(code: e.key, scannedCount: e.value).toJson())
        .toList();
    await prefs.setString(_scanStatesKey, jsonEncode(list));
  }

  /// بارگذاری شمارنده‌های اسکن
  Future<Map<String, int>> loadScanStates() async {
    final prefs = await _getPrefs();
    final str = prefs.getString(_scanStatesKey);
    if (str == null) return {};
    try {
      final list = jsonDecode(str) as List;
      final map = <String, int>{};
      for (final e in list) {
        final s = ScanState.fromJson(e as Map<String, dynamic>);
        map[s.code] = s.scannedCount;
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  /// نام فایل اکسل بارگذاری‌شده
  Future<String?> getExcelFileName() async {
    final prefs = await _getPrefs();
    return prefs.getString(_excelFileNameKey);
  }

  /// ریست کامل شمارنده‌ها (بدون حذف لیست کالاها)
  Future<void> resetScanStates() async {
    final prefs = await _getPrefs();
    await prefs.remove(_scanStatesKey);
  }

  /// حذف کامل داده‌ها (ریست کامل + حذف فایل اکسل)
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_productsKey);
    await prefs.remove(_scanStatesKey);
    await prefs.remove(_excelFileNameKey);
  }
}
