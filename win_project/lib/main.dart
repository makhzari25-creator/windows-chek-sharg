import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/charge_hall_screen.dart';
import 'screens/check_charge_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'چک شارژ سالن',
      debugShowCheckedModeBanner: false,

      // تنظیمات راست‌چین و فارسی
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // تم برنامه
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkGray,

        // فونت فارسی Vazirmatn
        fontFamily: 'Vazirmatn',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w900,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w500,
          ),
        ),

        // پالت رنگی برند: فیروزه‌ای روشن / آبی‌سبز تیره / مشکی
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.cyan,
          primary: AppColors.cyan,
          secondary: AppColors.teal,
          surface: AppColors.darkGray,
        ),

        // تنظیمات دکمه‌ها
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            minimumSize: const Size(double.infinity, 70),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // تنظیمات appbar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),

      // مسیرهای برنامه
      home: const SplashScreen(nextScreen: HomeScreen()),
      routes: {
        '/charge_hall': (_) => const ChargeHallScreen(),
        '/check_charge': (_) => const CheckChargeScreen(),
      },
    );
  }
}
