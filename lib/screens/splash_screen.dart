import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'welcome_screen.dart';

/// Opening screen with the VUE & OR logo, then moves on to the shop.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const logo = AssetImage('assets/images/logo.png');

  bool started = false;
  bool left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      // Only a plain timer decides when to leave, started once the first frame
      // is drawn, so the splash can never wait on anything else.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 2500), _leave);
      });
      precacheImage(logo, context).catchError((_) {});
    }
  }

  void _leave() {
    if (!mounted || left) return;
    left = true;
    final next = afterSplash(AppScope.read(context));
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = (MediaQuery.sizeOf(context).width * 0.7).clamp(0.0, 320.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.brandCreamLight, AppColors.brandCream],
          ),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(image: logo, width: logoWidth, semanticLabel: 'VUE & OR'),
              const SizedBox(height: 28),
              const _GoldDivider(),
              const SizedBox(height: 20),
              Text(
                'FINE JEWELLERY',
                style: AppText.sans(size: 12, weight: FontWeight.w500, letterSpacing: 6, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin gold line with a small diamond in the middle.
class _GoldDivider extends StatelessWidget {
  const _GoldDivider();

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(width: 56, height: 1, color: AppColors.goldBright);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(width: 6, height: 6, color: AppColors.goldBright),
          ),
        ),
        line(),
      ],
    );
  }
}
