import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../photos.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'product_screen.dart';
import 'transformation_screen.dart';

/// Wireframe 2 — Home.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const heroHeight = 560.0;
  final scroll = ScrollController();
  bool pastHero = false;

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      final past = scroll.offset > heroHeight - 40;
      if (past != pastHero) setState(() => pastHero = past);
    });
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void _open(Product p) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(product: p)));

  void _watch() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransformationScreen()));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: pastHero ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: state.loadProducts,
              edgeOffset: top,
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.zero,
                children: [
                  _Hero(
                    top: top,
                    height: heroHeight,
                    onDiscover: () => ShellScope.go(context, AppTab.shop),
                    onWatch: _watch,
                  ),
                  _TwoPieces(state: state, onOpen: _open),
                  _TwoWays(onHow: _watch),
                  _Finishes(onTap: () => ShellScope.go(context, AppTab.shop)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: _LensCard(onTap: () => ShellScope.go(context, AppTab.lenses)),
                  ),
                ],
              ),
            ),
            // Status-bar backing once the dark hero has scrolled away.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: top,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: pastHero ? 1 : 0,
                  child: const ColoredBox(color: AppColors.cream),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final double top;
  final double height;
  final VoidCallback onDiscover;
  final VoidCallback onWatch;

  const _Hero({required this.top, required this.height, required this.onDiscover, required this.onWatch});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Photo(Photos.wornLight, alignment: Alignment(0.2, -0.2), semanticLabel: 'Model 01 worn as a necklace'),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.28, 0.6, 1],
                colors: [Color(0xCC1A1612), Color(0x401A1612), Color(0xCC1A1612), Color(0xFA1A1612)],
              ),
            ),
          ),
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: 56),
                  const Expanded(
                    child: Center(child: Wordmark(size: 19, color: AppColors.onDark)),
                  ),
                  BagButton(onPressed: () => ShellScope.go(context, AppTab.bag), color: AppColors.onDark),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('The convertible collection', color: AppColors.goldBright),
                const SizedBox(height: 14),
                SplitHeading(
                  'Jewelry, with\nanother ',
                  italic: 'point of\nview.',
                  style: ({Color color = AppColors.ink, bool italic = false}) =>
                      AppText.display(color: color, italic: italic, size: 44),
                  color: AppColors.onDark,
                ),
                const SizedBox(height: 14),
                Text(
                  'An elegant necklace designed to transform into eyewear whenever you need it.',
                  style: AppText.body(color: AppColors.onDarkMuted),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cream,
                          foregroundColor: AppColors.ink,
                          textStyle: AppText.button(color: AppColors.ink),
                        ),
                        onPressed: onDiscover,
                        child: const Text('DISCOVER'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onDark,
                          side: BorderSide(color: AppColors.onDark.withValues(alpha: 0.6)),
                          minimumSize: const Size(48, 56),
                          textStyle: AppText.button(color: AppColors.onDark),
                        ),
                        onPressed: onWatch,
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('WATCH'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoPieces extends StatelessWidget {
  final AppState state;
  final ValueChanged<Product> onOpen;

  const _TwoPieces({required this.state, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    Widget list;
    if (state.products.isEmpty && state.productsError != null) {
      list = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ErrorRetry(message: state.productsError!, onRetry: state.loadProducts),
      );
    } else if (state.products.isEmpty) {
      list = const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    } else {
      list = SizedBox(
        height: 268 + 92 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: state.products.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final p = state.products[i];
            return SizedBox(
              width: 262,
              child: Semantics(
                button: true,
                label: '${p.name}, ${p.categoryLabel}, ${formatAed(p.price)}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onOpen(p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 268, width: double.infinity, child: Photo(p.photo)),
                      const SizedBox(height: 14),
                      Text(
                        p.categoryLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caps(size: 10.5),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.serif(size: 28),
                            ),
                          ),
                          Text(formatAed(p.price), style: AppText.sans(size: 13, color: AppColors.ink)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 48, bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Two pieces'),
                SizedBox(height: 14),
                SplitHeading('A necklace first. Eyewear whenever you need it.', style: _h2),
              ],
            ),
          ),
          const SizedBox(height: 26),
          list,
        ],
      ),
    );
  }

  static TextStyle _h2({Color color = AppColors.ink, bool italic = false}) => AppText.h2(color: color, italic: italic);
}

class _TwoWays extends StatelessWidget {
  final VoidCallback onHow;
  const _TwoWays({required this.onHow});

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('I', 'Wear it as a necklace', Photos.wornCollar),
      ('II', 'Transform in a moment', Photos.model02),
      ('III', 'See, then return it', Photos.wornReturn),
    ];
    return Container(
      color: AppColors.sand,
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SplitHeading('One piece,\n', italic: 'two ways to see.', style: _TwoPieces._h2),
              ),
              UnderlineLink('HOW', onTap: onHow, color: AppColors.ink, size: 12),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(aspectRatio: 0.82, child: Photo(steps[i].$3)),
                      const SizedBox(height: 12),
                      Text(steps[i].$1, style: AppText.serif(size: 20, color: AppColors.gold)),
                      const SizedBox(height: 4),
                      Text(steps[i].$2, style: AppText.sans(size: 13, color: AppColors.ink, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Finishes extends StatelessWidget {
  final VoidCallback onTap;
  const _Finishes({required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget tile(Finish f, String photo, Color dot) => Expanded(
      child: Semantics(
        button: true,
        label: '${f.label}. ${f.line}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.82,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Photo(photo),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: dot,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(f.label, style: AppText.serif(size: 22)),
              const SizedBox(height: 2),
              Text(f.line, style: AppText.sans(size: 12.5, height: 1.4)),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Two finishes'),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tile(Finish.solidGold, Photos.finishSolidGold, AppColors.goldBright),
              const SizedBox(width: 12),
              tile(Finish.goldPlated, Photos.finishGoldPlated, AppColors.plated),
            ],
          ),
        ],
      ),
    );
  }
}

class _LensCard extends StatelessWidget {
  final VoidCallback onTap;
  const _LensCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dark,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Lens guide', color: AppColors.goldBright),
                    const SizedBox(height: 10),
                    Text(
                      'Plain, prescription or reading — find your lens.',
                      style: AppText.serif(size: 24, color: AppColors.onDark, height: 1.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward, color: AppColors.onDark, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
