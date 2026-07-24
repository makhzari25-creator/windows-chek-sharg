import 'package:flutter/material.dart';

/// صفحه شارژ سالن
/// فعلاً فقط نمایش "به‌زودی"
/// این صفحه به‌گونه‌ای طراحی شده که بعداً قابل توسعه باشد
class ChargeHallScreen extends StatelessWidget {
  const ChargeHallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شارژ سالن'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF9800),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 72,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'به‌زودی',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'این بخش در نسخه‌های آینده اضافه خواهد شد.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'برای ثبت شارژ سالن فعلاً از روش سنتی استفاده کنید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
