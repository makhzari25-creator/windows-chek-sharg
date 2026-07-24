/// مدل کالای بارکد‌دار
/// هر کالا شامل کد، عنوان و تعداد مورد نیاز اسکن است
class Product {
  final String code;
  final String title;
  final int requiredCount;

  Product({
    required this.code,
    required this.title,
    required this.requiredCount,
  });

  factory Product.empty() => Product(code: '', title: '', requiredCount: 0);

  bool get isEmpty => code.isEmpty && title.isEmpty;

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'requiredCount': requiredCount,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        requiredCount: json['requiredCount'] as int? ?? 0,
      );
}

/// وضعیت اسکن یک کالا
class ScanState {
  final String code;
  final int scannedCount;

  ScanState({required this.code, required this.scannedCount});

  Map<String, dynamic> toJson() => {
        'code': code,
        'scannedCount': scannedCount,
      };

  factory ScanState.fromJson(Map<String, dynamic> json) => ScanState(
        code: json['code'] as String? ?? '',
        scannedCount: json['scannedCount'] as int? ?? 0,
      );
}
