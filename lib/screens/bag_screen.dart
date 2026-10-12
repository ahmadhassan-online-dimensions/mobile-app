import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'checkout_screen.dart';
import 'main_shell.dart';
import 'product_screen.dart';

/// Wireframe 7 — Your bag (GET/PUT/DELETE /cart).
class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  final busy = <String>{};

  Future<void> _run(CartLine line, Future<void> Function() action) async {
    setState(() => busy.add(line.product.id));
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy.remove(line.product.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cart = state.cart;

    Widget body;
    if (!state.signedIn) {
      body = _Empty(
        title: 'Your bag is waiting.',
        text: 'Sign in to keep your pieces and check out securely.',
        action: 'SIGN IN',
        onAction: () => ensureSignedIn(context),
      );
    } else if (cart.isEmpty) {
      body = _Empty(
        title: 'Your bag is empty.',
        text: 'Two pieces. Two ways to see.',
        action: 'ENTER THE COLLECTION',
        onAction: () => ShellScope.go(context, AppTab.shop),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: state.refreshCart,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            for (final line in cart.items)
              _Line(
                line: line,
                options: state.optionsFor(line.product),
                busy: busy.contains(line.product.id),
                onQty: (q) => _run(line, () => state.setQuantity(line, q)),
                onRemove: () => _run(line, () => state.removeFromBag(line)),
              ),
            const SizedBox(height: 24),
            _Row('Subtotal', formatAed(cart.totalAmount)),
            const SizedBox(height: 10),
            _Row('Delivery', 'Calculated at checkout'),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('TOTAL', style: AppText.caps(color: AppColors.ink, size: 12.5)),
                const Spacer(),
                Text(formatAed(cart.totalAmount), style: AppText.serif(size: 34)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text('SECURE CHECKOUT'),
            ),
            const SizedBox(height: 8),
            Center(child: UnderlineLink('Continue shopping', onTap: () => ShellScope.go(context, AppTab.shop))),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: capsAppBar(context, cart.isEmpty || !state.signedIn ? 'Your bag' : 'Your bag · ${cart.totalItems}'),
      body: body,
    );
  }
}

class _Line extends StatelessWidget {
  final CartLine line;
  final PieceOptions options;
  final bool busy;
  final ValueChanged<int> onQty;
  final VoidCallback onRemove;

  const _Line({
    required this.line,
    required this.options,
    required this.busy,
    required this.onQty,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = line.product;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: busy ? 0.5 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductScreen(product: p))),
              child: SizedBox(width: 100, height: 122, child: Photo(p.photo, semanticLabel: p.name)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: Text(p.name, style: AppText.serif(size: 26))),
                      Text(formatAed(line.lineTotal), style: AppText.sans(size: 14, color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(options.summary, style: AppText.sans(size: 13.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      QtyStepper(value: line.quantity, max: p.stock.clamp(1, 10), onChanged: busy ? null : onQty),
                      const Spacer(),
                      UnderlineLink('Remove', onTap: busy ? null : onRemove, size: 13.5),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.sans(size: 15)),
        Text(value, style: AppText.sans(size: 15, color: AppColors.ink)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String text;
  final String action;
  final VoidCallback onAction;

  const _Empty({required this.title, required this.text, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.gold),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: AppText.h2()),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: AppText.body()),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onAction, child: Text(action)),
            ),
          ],
        ),
      ),
    );
  }
}
