import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// اسپلش اسکرین برند MA LABS
/// - پس‌زمینه کاملاً مشکی
/// - یک نور فیروزه‌ای از پایین افق صفحه طلوع و درخشش می‌کند
/// - لوگوی MA به‌آرامی Fade In و بزرگ می‌شود
/// - متن «MA LABS» و «BUILT ON TRUST» زیر لوگو نمایان می‌شوند
/// - در پایان با Fade Out نرم به صفحه اصلی برنامه منتقل می‌شود
class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _exitController;

  late final Animation<double> _beamOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _swooshProgress;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _beamOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _swooshProgress = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeInOut),
    );

    _textOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _entranceController.forward();
    // مکث کوتاه با لوگوی کامل روی صفحه (مجموع زمان حدود ۱.۵ تا ۲ ثانیه)
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await _exitController.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, anim, __) =>
            FadeTransition(opacity: anim, child: widget.nextScreen),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_entranceController, _exitController]),
        builder: (context, _) {
          final exitOpacity = 1.0 - _exitController.value;
          return Opacity(
            opacity: exitOpacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // نور فیروزه‌ای طلوع‌کننده از پایین افق
                Opacity(
                  opacity: _beamOpacity.value,
                  child: CustomPaint(
                    painter: _HorizonGlowPainter(),
                    size: Size.infinite,
                  ),
                ),

                // لوگو + متن‌ها در مرکز صفحه
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: _MaWordmark(
                              swooshProgress: _swooshProgress.value),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            const Text(
                              'MA LABS',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 6,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'BUILT ON TRUST',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 4,
                                color: AppColors.cyan.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// نور محو فیروزه‌ای که از پایین صفحه بالا می‌آید (شبیه طلوع نور در افق)
class _HorizonGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.62;

    // درخشش عمودی (ستون نور) از پایین به سمت بالا
    final beamRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height),
      width: size.width * 0.9,
      height: size.height * 1.1,
    );
    final beamPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.cyan.withOpacity(0.35),
          AppColors.cyan.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(beamRect);
    canvas.drawRect(beamRect, beamPaint);

    // خط افق درخشان
    final horizonPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.cyan.withOpacity(0.0),
          AppColors.cyan.withOpacity(0.9),
          AppColors.cyan.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromLTWH(0, horizonY - 2, size.width, 4),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(Rect.fromLTWH(0, horizonY - 2, size.width, 4),
        horizonPaint);
  }

  @override
  bool shouldRepaint(covariant _HorizonGlowPainter oldDelegate) => false;
}

/// لوگوی متنی MA با گرادیان فلزی و یک قوس نور فیروزه‌ای زیر آن (Swoosh)
class _MaWordmark extends StatelessWidget {
  final double swooshProgress;

  const _MaWordmark({required this.swooshProgress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFB0BEC5),
                Colors.white,
              ],
              stops: [0.0, 0.55, 1.0],
            ).createShader(rect),
            child: const Text(
              'MA',
              style: TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            bottom: 28,
            child: CustomPaint(
              painter: _SwooshPainter(progress: swooshProgress),
              size: const Size(190, 30),
            ),
          ),
        ],
      ),
    );
  }
}

/// قوس نور فیروزه‌ای زیر لوگو که به‌تدریج رسم می‌شود
class _SwooshPainter extends CustomPainter {
  final double progress;

  _SwooshPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.6,
      size.width,
      size.height * 0.15,
    );

    final metrics = path.computeMetrics().first;
    final extracted = metrics.extractPath(0, metrics.length * progress);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [AppColors.teal, AppColors.cyan],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(covariant _SwooshPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
