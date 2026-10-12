import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Enter an optometrist's prescription once; kept on this phone and shown
/// whenever prescription lenses are chosen. Pops `true` when saved.
class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final form = GlobalKey<FormState>();
  late final Prescription initial = AppScope.read(context).prescription ?? const Prescription();
  late final rSph = TextEditingController(text: initial.rightSph);
  late final rCyl = TextEditingController(text: initial.rightCyl);
  late final rAxis = TextEditingController(text: initial.rightAxis);
  late final lSph = TextEditingController(text: initial.leftSph);
  late final lCyl = TextEditingController(text: initial.leftCyl);
  late final lAxis = TextEditingController(text: initial.leftAxis);
  late final pd = TextEditingController(text: initial.pd);

  @override
  void dispose() {
    for (final c in [rSph, rCyl, rAxis, lSph, lCyl, lAxis, pd]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _power(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    return RegExp(r'^[+-]?\d{1,2}(\.\d{1,2})?$').hasMatch(t) ? null : 'e.g. -1.25';
  }

  String? _axis(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = int.tryParse(t);
    return n != null && n >= 0 && n <= 180 ? null : '0–180';
  }

  String? _pd(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final n = double.tryParse(t);
    return n != null && n >= 40 && n <= 80 ? null : '40–80 mm';
  }

  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    final p = Prescription(
      rightSph: rSph.text.trim(),
      rightCyl: rCyl.text.trim(),
      rightAxis: rAxis.text.trim(),
      leftSph: lSph.text.trim(),
      leftCyl: lCyl.text.trim(),
      leftAxis: lAxis.text.trim(),
      pd: pd.text.trim(),
    );
    if (p.isEmpty) {
      showMessage(context, 'Enter at least the sphere (SPH) for one eye.');
      return;
    }
    await AppScope.read(context).savePrescription(p);
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _field(TextEditingController c, String label, String? Function(String?) validator) => Expanded(
    child: TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      textAlign: TextAlign.center,
      style: AppText.sans(size: 15, color: AppColors.ink),
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
      validator: validator,
    ),
  );

  Widget _eye(String title, TextEditingController sph, TextEditingController cyl, TextEditingController axis) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppText.caps(color: AppColors.ink, size: 12)),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _field(sph, 'SPH', _power),
          const SizedBox(width: 8),
          _field(cyl, 'CYL', _power),
          const SizedBox(width: 8),
          _field(axis, 'AXIS', _axis),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: capsAppBar(context, 'Your prescription', back: true),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            const SplitHeading('Enter it ', italic: 'once.'),
            const SizedBox(height: 10),
            Text(
              'Copy the values from your optometrist\'s prescription. They stay on this phone and are '
              'ready whenever you choose prescription lenses.',
              style: AppText.body(),
            ),
            const SizedBox(height: 28),
            _eye('Right eye · OD', rSph, rCyl, rAxis),
            const SizedBox(height: 22),
            _eye('Left eye · OS', lSph, lCyl, lAxis),
            const SizedBox(height: 22),
            Text('PUPILLARY DISTANCE', style: AppText.caps(color: AppColors.ink, size: 12)),
            const SizedBox(height: 10),
            Row(children: [_field(pd, 'PD (mm)', _pd), const Spacer(flex: 2)]),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _save, child: const Text('SAVE PRESCRIPTION')),
            if (!initial.isEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: UnderlineLink(
                  'Remove saved prescription',
                  onTap: () async {
                    await AppScope.read(context).savePrescription(null);
                    if (context.mounted) Navigator.of(context).pop(false);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
