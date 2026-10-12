import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'order_screen.dart';
import 'orders_screen.dart';
import 'prescription_screen.dart';
import 'wishlist_screen.dart';

/// Wireframe 8 — Account (GET /users/profile, GET /orders).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Future<List<Order>>? orders;
  String? loadedFor;

  void _reload() => setState(() => orders = AppScope.read(context).orders());

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) {
    if (mounted) _reload();
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user;

    if (user != null && loadedFor != user.id) {
      loadedFor = user.id;
      orders = state.orders();
    } else if (user == null) {
      loadedFor = null;
      orders = null;
    }

    if (user == null) {
      return Scaffold(
        appBar: capsAppBar(context, 'Account'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Wordmark(size: 26),
                const SizedBox(height: 22),
                const SplitHeading('Your ', italic: 'VUE & OR.', style: _h2),
                const SizedBox(height: 10),
                Text(
                  'Sign in to follow your orders and keep your bag on every device.',
                  textAlign: TextAlign.center,
                  style: AppText.body(),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () => ensureSignedIn(context), child: const Text('SIGN IN')),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _push(const WishlistScreen()),
                    child: Text('WISHLIST · ${state.prefs.wishlist.length}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: capsAppBar(context, 'Account'),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            SplitHeading('$_greeting\n', italic: '${user.firstName}.', style: _h1),
            if (user.createdAt != null) ...[
              const SizedBox(height: 8),
              Text('Client since ${user.createdAt!.year}', style: AppText.sans(size: 15)),
            ],
            const SizedBox(height: 28),
            FutureBuilder<List<Order>>(
              future: orders,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                }
                if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _reload);
                final list = snap.data ?? [];
                if (list.isEmpty) return const SizedBox.shrink();
                return _LatestOrder(
                  order: list.first,
                  onTap: () => _push(OrderScreen(orderId: list.first.id, initial: list.first)),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuRow('Orders and returns', () => _push(const OrdersScreen())),
            _MenuRow(
              'Saved prescriptions',
              () => _push(const PrescriptionScreen()),
              trailing: state.prescription == null ? null : 'Saved',
            ),
            _MenuRow(
              'Wishlist',
              () => _push(const WishlistScreen()),
              trailing: state.prefs.wishlist.isEmpty ? null : '${state.prefs.wishlist.length}',
            ),
            _MenuRow('Addresses', () => _push(const _AddressScreen()), trailing: state.savedAddress?.city),
            _MenuRow('Client care', () => launchUrl(Uri.parse('mailto:hello@vueandor.com'))),
            const SizedBox(height: 26),
            Align(
              alignment: Alignment.centerLeft,
              child: UnderlineLink(
                'Sign out',
                onTap: () async {
                  await state.signOut();
                  if (context.mounted) showMessage(context, 'You are signed out.');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _h1({Color color = AppColors.ink, bool italic = false}) => AppText.h1(color: color, italic: italic);
  static TextStyle _h2({Color color = AppColors.ink, bool italic = false}) => AppText.h2(color: color, italic: italic);
}

class _LatestOrder extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _LatestOrder({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final products = AppScope.of(context).products;
    final first = order.items.isEmpty ? null : order.items.first;
    final product = first == null ? null : products.where((p) => p.id == first.productId).firstOrNull;

    return Material(
      color: AppColors.paper,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Eyebrow('Latest order'),
                  const Spacer(),
                  Text('#${order.number}', style: AppText.sans(size: 13, color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(width: 70, height: 82, child: product == null ? const Hatch() : Photo(product.photo)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first == null
                              ? 'Order'
                              : '${first.name}${order.itemCount > 1 ? ' + ${order.itemCount - 1}' : ''}',
                          style: AppText.serif(size: 24),
                        ),
                        const SizedBox(height: 2),
                        Text(order.statusLabel, style: AppText.sans(size: 13.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              StageBar(stage: order.isCancelled ? 0 : order.stage),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placed · Atelier · Shipped · Delivered.
class StageBar extends StatelessWidget {
  final int stage;
  const StageBar({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    const labels = ['Placed', 'Atelier', 'Shipped', 'Delivered'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 3, color: i < stage ? AppColors.ink : AppColors.stone),
                const SizedBox(height: 8),
                Text(labels[i], style: AppText.sans(size: 12, color: i < stage ? AppColors.ink : AppColors.muted)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  const _MenuRow(this.label, this.onTap, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppText.sans(size: 16, color: AppColors.ink)),
            ),
            if (trailing != null) ...[Text(trailing!, style: AppText.sans(size: 13.5)), const SizedBox(width: 10)],
            const Icon(Icons.chevron_right, size: 20, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _AddressScreen extends StatelessWidget {
  const _AddressScreen();

  @override
  Widget build(BuildContext context) {
    final address = AppScope.of(context).savedAddress;
    return Scaffold(
      appBar: capsAppBar(context, 'Addresses', back: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: address == null
            ? Text('Your delivery address is saved here after your first checkout.', style: AppText.body())
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Eyebrow('Delivery address'),
                    const SizedBox(height: 12),
                    for (final l in address.lines.where((l) => l.isNotEmpty))
                      Text(l, style: AppText.sans(size: 15, color: AppColors.ink, height: 1.6)),
                    const SizedBox(height: 8),
                    Text('Used to fill in checkout. You can change it there.', style: AppText.sans(size: 13)),
                  ],
                ),
              ),
      ),
    );
  }
}
