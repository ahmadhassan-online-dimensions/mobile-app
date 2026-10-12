import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../photos.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';

/// Wireframe 5 — See how it transforms. A three-scene film (photographs with
/// slow movement) synced to the I · II · III steps.
class TransformationScreen extends StatefulWidget {
  const TransformationScreen({super.key});

  @override
  State<TransformationScreen> createState() => _TransformationScreenState();
}

class _TransformationScreenState extends State<TransformationScreen> with SingleTickerProviderStateMixin {
  static const scenes = [
    (
      'I',
      'Worn as a necklace',
      'The pendant rests at the collarbone on its fine chain — jewelry first, nothing to suggest otherwise.',
      Photos.wornCollar,
    ),
    (
      'II',
      'The transformation',
      'Lift the pendant and it opens: wearable temples unfold, or the handheld lens rises to the eyes.',
      Photos.model02,
    ),
    (
      'III',
      'Worn as eyewear',
      'Read the menu, the message, the label. Then close it, and it becomes a necklace again.',
      Photos.wornReturn,
    ),
  ];

  late final AnimationController film = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void initState() {
    super.initState();
    film.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() {});
    });
  }

  @override
  void dispose() {
    film.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (film.isAnimating) {
        film.stop();
      } else {
        if (film.isCompleted) film.reset();
        film.forward();
      }
    });
  }

  int get scene => (film.value * scenes.length).floor().clamp(0, scenes.length - 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.onDark,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const Border(),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('THE TRANSFORMATION', style: AppText.caps(color: AppColors.onDarkMuted, size: 12)),
      ),
      body: AnimatedBuilder(
        animation: film,
        builder: (context, _) {
          final active = scene;
          final local = film.value * scenes.length - active;
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              SplitHeading(
                'See how it\n',
                italic: 'transforms.',
                color: AppColors.onDark,
                italicColor: AppColors.goldBright,
              ),
              const SizedBox(height: 14),
              Text(
                'A necklace first. Eyewear in a single, quiet gesture.',
                style: AppText.body(color: AppColors.onDarkMuted),
              ),
              const SizedBox(height: 28),

              // ---- the film -------------------------------------------
              Semantics(
                label: 'Transformation film, scene ${active + 1} of 3: ${scenes[active].$2}',
                button: true,
                child: GestureDetector(
                  onTap: _toggle,
                  child: AspectRatio(
                    aspectRatio: 0.82,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          child: Transform.scale(
                            key: ValueKey(active),
                            scale: 1.04 + 0.08 * (film.isAnimating ? local : 0),
                            child: Photo(scenes[active].$4),
                          ),
                        ),
                        Container(color: Color.fromRGBO(26, 22, 18, film.isAnimating ? 0.15 : 0.45)),
                        Positioned(
                          left: 18,
                          top: 18,
                          child: FrameLabel('Film · scene ${scenes[active].$1}', color: AppColors.onDark),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: film.isAnimating ? 0 : 1,
                          child: Center(
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.onDark.withValues(alpha: 0.7)),
                                color: const Color(0x331A1612),
                              ),
                              child: Icon(
                                film.isCompleted ? Icons.replay : Icons.play_arrow,
                                color: AppColors.onDark,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Stack(
                            children: [
                              Container(height: 2, color: AppColors.onDark.withValues(alpha: 0.25)),
                              FractionallySizedBox(
                                widthFactor: film.value,
                                child: Container(height: 2, color: AppColors.goldBright),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ---- steps ----------------------------------------------
              for (var i = 0; i < scenes.length; i++)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: film.value == 0 || i == active ? 1 : 0.45,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0x26F3EDE4))),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(scenes[i].$1, style: AppText.serif(size: 26, color: AppColors.goldBright)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(scenes[i].$2, style: AppText.serif(size: 24, color: AppColors.onDark)),
                              const SizedBox(height: 6),
                              Text(scenes[i].$3, style: AppText.body(color: AppColors.onDarkMuted, size: 14.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(height: 1, color: const Color(0x26F3EDE4)),
              const SizedBox(height: 36),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cream,
                  foregroundColor: AppColors.ink,
                  textStyle: AppText.button(color: AppColors.ink),
                ),
                onPressed: () => ShellScope.go(context, AppTab.shop),
                child: const Text('SHOP THE COLLECTION'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ShellScope.go(context, AppTab.lenses),
                child: Text('EXPLORE LENS OPTIONS', style: AppText.button(color: AppColors.goldBright)),
              ),
            ],
          );
        },
      ),
    );
  }
}
