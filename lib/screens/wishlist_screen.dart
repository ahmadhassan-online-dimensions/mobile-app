import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'product_screen.dart';

/// Pieces saved with the heart (kept on this phone).
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = state.wishlistProducts;

    return Scaffold(
      appBar: capsAppBar(context, 'Wishlist', back: true),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border, color: AppColors.gold, size: 36),
                    const SizedBox(height: 16),
                    Text('Nothing saved yet.', style: AppText.h2()),
                    const SizedBox(height: 8),
                    Text('Tap the heart on a piece to keep it here.', style: AppText.body()),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => ShellScope.go(context, AppTab.shop),
                      child: const Text('THE COLLECTION'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final p in items)
                  InkWell(
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(product: p))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.line)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 88, height: 106, child: Photo(p.photo)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.categoryLabel.toUpperCase(), style: AppText.caps(size: 10.5)),
                                const SizedBox(height: 4),
                                Text(p.name, style: AppText.serif(size: 26)),
                                Text(formatAed(p.price), style: AppText.sans(size: 14, color: AppColors.ink)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove from wishlist',
                            icon: const Icon(Icons.favorite, color: AppColors.gold),
                            onPressed: () => state.toggleWishlist(p),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
