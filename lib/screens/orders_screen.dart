import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'order_screen.dart';

/// All orders (GET /orders).
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> orders = AppScope.read(context).orders();

  void _reload() => setState(() => orders = AppScope.read(context).orders());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: capsAppBar(context, 'Orders and returns', back: true),
      body: FutureBuilder<List<Order>>(
        future: orders,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return ErrorRetry(message: '${snap.error}', onRetry: _reload);
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(child: Text('No orders yet.', style: AppText.body()));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final o = list[i];
                final d = o.createdAt;
                return InkWell(
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => OrderScreen(orderId: o.id, initial: o),
                        ),
                      )
                      .then((_) => _reload()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.line)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('#${o.number}', style: AppText.serif(size: 22)),
                              const SizedBox(height: 2),
                              Text(
                                '${d == null ? '' : '${d.day}/${d.month}/${d.year} · '}${o.itemCount} '
                                '${o.itemCount == 1 ? 'piece' : 'pieces'} · ${o.statusLabel}',
                                style: AppText.sans(size: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(formatAed(o.totalAmount), style: AppText.sans(size: 14, color: AppColors.ink)),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
