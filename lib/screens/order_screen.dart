import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'account_screen.dart';
import 'main_shell.dart';

/// Order confirmation / status. Re-checks GET /orders/:id whenever the app
/// returns from the payment page.
class OrderScreen extends StatefulWidget {
  final String orderId;
  final Order? initial;

  const OrderScreen({super.key, required this.orderId, this.initial});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with WidgetsBindingObserver {
  late Order? order = widget.initial;
  String? error;
  bool loading = false;
  bool paying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (order == null) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final state = AppScope.read(context);
    try {
      final fresh = await state.order(widget.orderId);
      if (fresh.isPaid) await state.refreshCart().catchError((_) {});
      if (mounted) setState(() => order = fresh);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pay() async {
    setState(() => paying = true);
    try {
      final url = await AppScope.read(context).paymentLink(widget.orderId);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    final user = AppScope.of(context).user;

    return Scaffold(
      appBar: capsAppBar(context, o == null ? 'Your order' : 'Order #${o.number}', back: true),
      body: o == null
          ? (error != null
                ? ErrorRetry(message: error!, onRetry: _load)
                : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                children: [
                  Eyebrow(o.statusLabel),
                  const SizedBox(height: 12),
                  if (o.isPaid)
                    SplitHeading(
                      'Thank you${user == null ? '' : ',\n'}',
                      italic: user == null ? '.' : '${user.firstName}.',
                    )
                  else if (o.isCancelled)
                    const SplitHeading('This order was ', italic: 'cancelled.')
                  else
                    const SplitHeading('Almost ', italic: 'there.'),
                  const SizedBox(height: 12),
                  Text(
                    o.isPaid
                        ? 'Your payment was received. Your piece is now with our atelier.'
                        : o.isCancelled
                        ? 'No payment was taken for it.'
                        : 'Complete the payment on the secure 2Checkout page. This screen updates when you come back.',
                    style: AppText.body(),
                  ),
                  if (loading) const Padding(padding: EdgeInsets.only(top: 14), child: LinearProgressIndicator()),
                  const SizedBox(height: 26),
                  if (!o.isCancelled) ...[StageBar(stage: o.stage), const SizedBox(height: 28)],
                  if (o.isPending) ...[
                    ElevatedButton(
                      onPressed: paying ? null : _pay,
                      child: Text(paying ? 'OPENING PAYMENT…' : 'COMPLETE PAYMENT'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(onPressed: loading ? null : _load, child: const Text('I HAVE PAID · REFRESH')),
                    const SizedBox(height: 28),
                  ],
                  const Eyebrow('Summary'),
                  const SizedBox(height: 6),
                  for (final i in o.items)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.line)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i.name}${i.quantity > 1 ? ' × ${i.quantity}' : ''}',
                              style: AppText.serif(size: 21),
                            ),
                          ),
                          Text(formatAed(i.price * i.quantity), style: AppText.sans(size: 14, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('TOTAL', style: AppText.caps(color: AppColors.ink, size: 12.5)),
                      const Spacer(),
                      Text(formatAed(o.totalAmount), style: AppText.serif(size: 30)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Eyebrow('Delivering to'),
                  const SizedBox(height: 10),
                  for (final line in o.shippingAddress.lines.where((l) => l.isNotEmpty))
                    Text(line, style: AppText.sans(size: 15, color: AppColors.ink, height: 1.6)),
                  const SizedBox(height: 32),
                  Center(child: UnderlineLink('Continue shopping', onTap: () => ShellScope.go(context, AppTab.shop))),
                ],
              ),
            ),
    );
  }
}
