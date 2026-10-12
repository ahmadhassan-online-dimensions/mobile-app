import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'product_screen.dart';

/// Wireframe 3 — The collection.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

enum _Filter { all, wearable, handheld }

class _ShopScreenState extends State<ShopScreen> {
  _Filter filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = state.products
        .where(
          (p) => switch (filter) {
            _Filter.all => true,
            _Filter.wearable => p.isWearable,
            _Filter.handheld => !p.isWearable,
          },
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        shape: const Border(),
        title: const Wordmark(size: 18),
        actions: [
          BagButton(onPressed: () => ShellScope.go(context, AppTab.bag)),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.loadProducts,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('The collection'),
                  const SizedBox(height: 14),
                  const SplitHeading('Two ways to see.\n', italic: 'Two finishes.'),
                  const SizedBox(height: 14),
                  Text('Each piece is a necklace first, and eyewear whenever you need it.', style: AppText.body()),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _Tabs(value: filter, count: items.length, onChanged: (f) => setState(() => filter = f)),
            if (state.products.isEmpty && state.productsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ErrorRetry(message: state.productsError!, onRetry: state.loadProducts),
              )
            else if (state.products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final p in items) _PieceCard(product: p),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final _Filter value;
  final int count;
  final ValueChanged<_Filter> onChanged;

  const _Tabs({required this.value, required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final (f, label) in const [
            (_Filter.all, 'ALL'),
            (_Filter.wearable, 'WEARABLE'),
            (_Filter.handheld, 'HANDHELD'),
          ])
            Semantics(
              selected: value == f,
              button: true,
              child: InkWell(
                onTap: () => onChanged(f),
                child: Container(
                  height: 48,
                  margin: const EdgeInsets.only(right: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: value == f ? AppColors.ink : Colors.transparent, width: 2),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppText.sans(
                      size: 12.5,
                      weight: value == f ? FontWeight.w700 : FontWeight.w500,
                      color: value == f ? AppColors.ink : AppColors.muted,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'piece' : 'pieces'}',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: AppText.sans(size: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieceCard extends StatelessWidget {
  final Product product;
  const _PieceCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = product;
    final saved = state.isWishlisted(p);
    final number = p.name.replaceAll('Model', 'MODEL');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Semantics(
        button: true,
        label: '${p.name}, ${p.categoryLabel}, from ${formatAed(p.price)}',
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(product: p))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.78,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(tag: 'piece-${p.id}', child: Photo(p.photo)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Color(0x40000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                    Positioned(left: 16, top: 18, child: FrameLabel('$number · necklace mode', color: Colors.white)),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
                        style: IconButton.styleFrom(backgroundColor: AppColors.paper),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: Icon(
                            saved ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(saved),
                            size: 18,
                            color: saved ? AppColors.gold : AppColors.ink,
                          ),
                        ),
                        onPressed: () => state.toggleWishlist(p),
                      ),
                    ),
                    const Positioned(left: 14, bottom: 14, child: _FinishPill()),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(p.categoryLabel.toUpperCase(), style: AppText.caps(size: 10.5)),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: Text(p.name, style: AppText.serif(size: 34))),
                  Text('From ${formatAed(p.price)}', style: AppText.serif(size: 19)),
                ],
              ),
              const SizedBox(height: 6),
              Text(p.tagline, style: AppText.body(size: 14.5)),
              if (!p.inStock) ...[
                const SizedBox(height: 8),
                Text('SOLD OUT', style: AppText.caps(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FinishPill extends StatelessWidget {
  const _FinishPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 6, backgroundColor: AppColors.goldBright),
          const SizedBox(width: 4),
          const CircleAvatar(radius: 6, backgroundColor: AppColors.plated),
          const SizedBox(width: 8),
          Text('2 FINISHES', style: AppText.caps(color: AppColors.ink, size: 10)),
        ],
      ),
    );
  }
}
