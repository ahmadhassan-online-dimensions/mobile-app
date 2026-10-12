import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'prescription_screen.dart';

/// Wireframe 6 — Lens guide.
class LensGuideScreen extends StatefulWidget {
  const LensGuideScreen({super.key});

  @override
  State<LensGuideScreen> createState() => _LensGuideScreenState();
}

class _LensGuideScreenState extends State<LensGuideScreen> {
  LensType? choice;
  String strength = '+2.00';
  bool allStrengths = false;

  Future<void> _apply() async {
    final state = AppScope.read(context);
    for (final p in state.products) {
      await state.setOptions(p, state.optionsFor(p).copyWith(lens: choice, strength: strength));
    }
    if (!mounted) return;
    ShellScope.go(context, AppTab.shop);
    showMessage(
      context,
      '${choice!.label}${choice == LensType.reading ? ' $strength' : ''} lenses selected for both pieces',
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = AppScope.of(context).prescription;
    final shown = allStrengths ? readingStrengths : const ['+1.00', '+1.50', '+2.00', '+2.50'];

    return Scaffold(
      appBar: capsAppBar(context, 'Lens guide'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        children: [
          const SplitHeading('Find the lens that ', italic: 'sees\nfor you.'),
          const SizedBox(height: 12),
          Text('Every piece is fitted with the lenses you choose. Not sure? Start here.', style: AppText.body()),
          const SizedBox(height: 24),
          _LensCard(
            title: 'Plain',
            text: 'Clear, non-corrective lenses. For style, or for anyone without a prescription.',
            icon: Icons.circle_outlined,
            selected: choice == LensType.plain,
            onTap: () => setState(() => choice = LensType.plain),
          ),
          const SizedBox(height: 12),
          _LensCard(
            title: 'Prescription',
            text: "Made to your optometrist's prescription. Enter the values once and they're kept for you.",
            icon: Icons.add_circle_outline,
            selected: choice == LensType.prescription,
            onTap: () => setState(() => choice = LensType.prescription),
          ),
          const SizedBox(height: 12),
          _LensCard(
            title: 'Reading',
            text: 'Magnification for close work, chosen by strength.',
            icon: Icons.radio_button_checked,
            selected: choice == LensType.reading,
            onTap: () => setState(() => choice = LensType.reading),
            footer: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in shown)
                  _Chip(
                    label: s,
                    selected: choice == LensType.reading && s == strength,
                    onTap: () => setState(() {
                      choice = LensType.reading;
                      strength = s;
                    }),
                  ),
                if (!allStrengths) _Chip(label: 'More', onTap: () => setState(() => allStrengths = true)),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: choice == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: ElevatedButton(
                      onPressed: _apply,
                      child: Text(
                        'SHOP WITH ${choice!.label.toUpperCase()}'
                        '${choice == LensType.reading ? ' $strength' : ''}',
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 40),
          const Eyebrow('Reading your prescription'),
          const SizedBox(height: 12),
          for (final (term, meaning) in const [
            ('SPH · Sphere', 'Lens power for near- or far-sightedness.'),
            ('CYL · Cylinder', 'Correction for astigmatism, if any.'),
            ('AXIS', 'The angle of astigmatism correction, 0–180.'),
            ('PD · Pupillary distance', 'Distance between your pupils, in millimetres.'),
          ])
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term,
                    style: AppText.sans(size: 14.5, weight: FontWeight.w600, color: AppColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(meaning, style: AppText.sans(size: 14.5)),
                ],
              ),
            ),
          Container(height: 1, color: AppColors.line),
          const SizedBox(height: 32),
          CustomPaint(
            painter: _DashedBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  Icon(
                    saved == null ? Icons.photo_camera_outlined : Icons.check_circle_outline,
                    color: saved == null ? AppColors.ink : AppColors.gold,
                  ),
                  const SizedBox(height: 14),
                  Text(saved == null ? 'Save your prescription' : 'Prescription saved', style: AppText.serif(size: 24)),
                  const SizedBox(height: 6),
                  Text(
                    saved == null
                        ? "Enter it once; it's ready whenever you choose prescription lenses."
                        : 'Ready for prescription lenses.',
                    textAlign: TextAlign.center,
                    style: AppText.sans(size: 13.5),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrescriptionScreen())),
                    child: Text(saved == null ? 'ADD PRESCRIPTION' : 'EDIT'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => launchUrl(Uri.parse('mailto:hello@vueandor.com?subject=Lens%20question')),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Speak with an optician', style: AppText.sans(size: 15.5, color: AppColors.ink)),
                  ),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LensCard extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? footer;

  const _LensCard({
    required this.title,
    required this.text,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: selected ? AppColors.ink : AppColors.line, width: selected ? 1.2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: AppText.serif(size: 28))),
                  Icon(icon, color: selected ? AppColors.ink : AppColors.gold, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(text, style: AppText.body(size: 14.5)),
              if (footer != null) ...[const SizedBox(height: 14), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 60, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.paper,
            border: Border.all(color: selected ? AppColors.ink : AppColors.lineStrong),
          ),
          child: Text(label, style: AppText.sans(size: 13.5, color: selected ? Colors.white : AppColors.ink)),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.lineStrong
      ..strokeWidth = 1;
    void dash(Offset a, Offset b) {
      final len = (b - a).distance;
      final dir = (b - a) / len;
      for (double d = 0; d < len; d += 8) {
        canvas.drawLine(a + dir * d, a + dir * (d + 4).clamp(0, len), p);
      }
    }

    dash(Offset.zero, Offset(size.width, 0));
    dash(Offset(size.width, 0), Offset(size.width, size.height));
    dash(Offset(size.width, size.height), Offset(0, size.height));
    dash(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}
