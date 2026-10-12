import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'order_screen.dart';

/// Delivery details -> POST /orders/checkout -> 2Checkout payment page.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  late final AppState state = AppScope.read(context);
  late final ShippingAddress? saved = state.savedAddress;
  late final name = TextEditingController(text: saved?.fullName ?? state.user?.name ?? '');
  late final phone = TextEditingController(text: saved?.phone ?? '');
  late final address = TextEditingController(text: saved?.address ?? '');
  late final city = TextEditingController(text: saved?.city ?? '');
  late final emirate = TextEditingController(text: saved?.state ?? '');
  late final postal = TextEditingController(text: saved?.postalCode ?? '');
  late final country = TextEditingController(text: saved?.country ?? 'United Arab Emirates');
  bool placing = false;

  @override
  void dispose() {
    for (final c in [name, phone, address, city, emirate, postal, country]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _placeOrder() async {
    if (!form.currentState!.validate()) return;
    setState(() => placing = true);
    final shipping = ShippingAddress(
      fullName: name.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
      city: city.text.trim(),
      state: emirate.text.trim(),
      postalCode: postal.text.trim(),
      country: country.text.trim(),
    );
    try {
      final (order, paymentUrl) = await state.checkout(shipping);
      await state.saveAddress(shipping);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderScreen(orderId: order.id, initial: order),
        ),
      );
      if (paymentUrl != null) {
        await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(
        context,
        e.statusCode == 503 ? 'Online payment is not available right now. Please try again later.' : e.message,
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => placing = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? type,
    Iterable<String>? autofill,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        autofillHints: autofill,
        textInputAction: TextInputAction.next,
        style: AppText.sans(size: 15, color: AppColors.ink),
        decoration: InputDecoration(labelText: required ? label : '$label (optional)'),
        validator: required ? _required : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cart = s.cart;

    return Scaffold(
      appBar: capsAppBar(context, 'Checkout', back: true),
      body: Form(
        key: form,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            children: [
              const SplitHeading('Where should it ', italic: 'arrive?'),
              const SizedBox(height: 24),
              const Eyebrow('Delivery'),
              const SizedBox(height: 14),
              _field(name, 'Full name', required: true, autofill: const [AutofillHints.name]),
              _field(phone, 'Mobile', type: TextInputType.phone, autofill: const [AutofillHints.telephoneNumber]),
              _field(
                address,
                'Building, street, area',
                required: true,
                autofill: const [AutofillHints.fullStreetAddress],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(city, 'City', required: true, autofill: const [AutofillHints.addressCity])),
                  const SizedBox(width: 10),
                  Expanded(child: _field(emirate, 'Emirate', autofill: const [AutofillHints.addressState])),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field(postal, 'Postal code', autofill: const [AutofillHints.postalCode])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(country, 'Country', required: true, autofill: const [AutofillHints.countryName]),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Eyebrow('Your pieces'),
              const SizedBox(height: 8),
              for (final l in cart.items)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 52, height: 62, child: Photo(l.product.photo)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l.product.name}${l.quantity > 1 ? ' × ${l.quantity}' : ''}',
                              style: AppText.serif(size: 21),
                            ),
                            Text(s.optionsFor(l.product).summary, style: AppText.sans(size: 12.5)),
                          ],
                        ),
                      ),
                      Text(formatAed(l.lineTotal), style: AppText.sans(size: 14, color: AppColors.ink)),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('TOTAL', style: AppText.caps(color: AppColors.ink, size: 12.5)),
                  const Spacer(),
                  Text(formatAed(cart.totalAmount), style: AppText.serif(size: 32)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will pay on the secure 2Checkout page, then come back here to follow your order.',
                      style: AppText.sans(size: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: placing || cart.isEmpty ? null : _placeOrder,
                child: placing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('CONTINUE TO PAYMENT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
