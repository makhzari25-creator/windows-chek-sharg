// تست خواندن فایل اکسل نمونه با ExcelService جدید
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:check_hall_charge/services/excel_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('read sample xlsx', () async {
    final service = ExcelService();
    final products = await service.readProducts(
        '/home/z/my-project/download/sample_charge_list.xlsx');
    debugPrint('Loaded ${products.length} products:');
    for (final p in products) {
      debugPrint('  code=${p.code}, title=${p.title}, count=${p.requiredCount}');
    }
    expect(products.length, 10);
    expect(products.first.code, '6291234567890');
    expect(products.first.requiredCount, 4);
  });

  test('read openpyxl xlsx (with /xl/ prefix bug)', () async {
    final service = ExcelService();
    final products = await service.readProducts(
        '/home/z/my-project/download/sample_openpyxl.xlsx');
    debugPrint('Loaded ${products.length} products from openpyxl file:');
    for (final p in products) {
      debugPrint('  code=${p.code}, title=${p.title}, count=${p.requiredCount}');
    }
    expect(products.length, 3);
    expect(products.first.code, '6291234567890');
    expect(products.first.requiredCount, 4);
  });

  test('read sharedStrings xlsx (MS Office style)', () async {
    final service = ExcelService();
    final products = await service.readProducts(
        '/home/z/my-project/download/sample_sharedstrings.xlsx');
    debugPrint('Loaded ${products.length} products from sharedStrings file:');
    for (final p in products) {
      debugPrint('  code=${p.code}, title=${p.title}, count=${p.requiredCount}');
    }
    expect(products.length, 3);
    expect(products.first.code, '6291234567890');
    expect(products.first.title, 'بسته شکلات');
    expect(products.first.requiredCount, 4);
  });
}
