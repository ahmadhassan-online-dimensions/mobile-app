import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../photos.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth_screen.dart';
import 'main_shell.dart';

/// Wireframe 1 — "Jewelry, with another point of view." Full-bleed film loop
/// (three slow photographs, 6 s), then Enter the collection / Sign in.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  static const slides = Photos.welcomeFilm;
  late final AnimationController film = AnimationController(
    vsync: this,
    duration: Duration(seconds: 2 * slides.length),
  )..repeat();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final s in slides) {
      precacheImage(AssetImage(s), context).catchError((_) {});
    }
  }

  @override
  void dispose() {
    film.dispose();
    super.dispose();
  }

  void _enter() => Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (_, _, _) => const MainShell(),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ),
  );

  Future<void> _signIn() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AuthScreen(), fullscreenDialog: true));
    if (ok == true && mounted) _enter();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // The film: each slide fades in and drifts slowly.
            AnimatedBuilder(
              animation: film,
              builder: (context, _) {
                final t = reduceMotion ? 0.0 : film.value * slides.length;
                final index = t.floor() % slides.length;
                final local = t - t.floor();
                final next = (index + 1) % slides.length;
                final fade = ((local - 0.75) / 0.25).clamp(0.0, 1.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _slide(slides[index], 1.06 + local * 0.06),
                    Opacity(opacity: fade, child: _slide(slides[next], 1.06)),
                  ],
                );
              },
            ),
            // Dark wash so type stays legible over any frame.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.3, 0.62, 1],
                  colors: [Color(0xCC1A1612), Color(0x661A1612), Color(0xE61A1612), Color(0xFF1A1612)],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Wordmark(size: 30, color: AppColors.onDark, spacing: 9),
                          const SizedBox(height: 18),
                          Container(width: 34, height: 1, color: AppColors.goldBright),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: film,
                      builder: (context, _) => Row(
                        children: [
                          for (var i = 0; i < slides.length; i++) ...[
                            _Dash(progress: ((film.value * slides.length) - i).clamp(0.0, 1.0)),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    const SplitHeading(
                      'Jewelry, with\nanother ',
                      italic: 'point of\nview.',
                      style: _display,
                      color: AppColors.onDark,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Each piece is a necklace first, and eyewear whenever you need it.',
                      style: AppText.body(color: AppColors.onDarkMuted, size: 16),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cream,
                          foregroundColor: AppColors.ink,
                          textStyle: AppText.button(color: AppColors.ink),
                        ),
                        onPressed: _enter,
                        child: const Text('ENTER THE COLLECTION'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text('Already a client?', style: AppText.sans(size: 15, color: AppColors.onDarkMuted)),
                          UnderlineLink('Sign in', onTap: _signIn, color: AppColors.onDark, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _display({Color color = AppColors.ink, bool italic = false}) =>
      AppText.display(color: color, italic: italic, size: 48);

  Widget _slide(String asset, double scale) => Transform.scale(
    scale: scale,
    child: Photo(asset, alignment: const Alignment(0, -0.3)),
  );
}

class _Dash extends StatelessWidget {
  final double progress;
  const _Dash({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 2,
      child: Stack(
        children: [
          Container(color: AppColors.onDark.withValues(alpha: 0.3)),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(color: AppColors.onDark),
          ),
        ],
      ),
    );
  }
}

/// Where the splash goes: straight to the shop for signed-in clients,
/// otherwise the welcome film.
Widget afterSplash(AppState state) => state.signedIn ? const MainShell() : const WelcomeScreen();
