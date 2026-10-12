import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'prescription_screen.dart';
import 'transformation_screen.dart';

/// Wireframe 4 — Product.
class ProductScreen extends StatefulWidget {
  final Product product;

  const ProductScreen({super.key, required this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Product product = widget.product;
  late PieceOptions options = AppScope.read(context).optionsFor(widget.product);
  final pages = PageController();
  int page = 0;
  bool eyewear = false;
  bool adding = false;

  @override
  void initState() {
    super.initState();
    // Fresh price and stock from GET /products/:id.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final fresh = await AppScope.read(context).product(product.id);
        if (mounted) setState(() => product = fresh);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  void _set(PieceOptions o) {
    setState(() => options = o);
    AppScope.read(context).setOptions(product, o);
  }

  Future<void> _add() async {
    if (options.lens == LensType.prescription && AppScope.read(context).prescription == null) {
      final saved = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const PrescriptionScreen()));
      if (saved != true || !mounted) return;
    }
    if (!mounted || !await ensureSignedIn(context, reason: 'Sign in to add pieces to your bag.')) return;
    if (!mounted) return;
    setState(() => adding = true);
    final state = AppScope.read(context);
    try {
      await state.setOptions(product, options);
      await state.addToBag(product);
      if (!mounted) return;
      showMessage(
        context,
        '${product.name} · ${options.summary} added to your bag',
        action: SnackBarAction(label: 'VIEW BAG', onPressed: () => ShellScope.go(context, AppTab.bag)),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final saved = state.isWishlisted(product);
    final top = MediaQuery.paddingOf(context).top;
    final number = product.name.toUpperCase();

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ---- gallery -------------------------------------------------
            SizedBox(
              height: 500 + top,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: eyewear
                        ? Container(
                            key: const ValueKey('eyewear'),
                            color: AppColors.dark,
                            padding: EdgeInsets.fromLTRB(40, top + 90, 40, 120),
                            child: GlassesArt(handheld: !product.isWearable),
                          )
                        : PageView.builder(
                            key: const ValueKey('necklace'),
                            controller: pages,
                            itemCount: product.gallery.length,
                            onPageChanged: (i) => setState(() => page = i),
                            itemBuilder: (_, i) {
                              final img = Photo(
                                product.gallery[i],
                                semanticLabel: '${product.name} worn as a necklace, photo ${i + 1}',
                              );
                              return InteractiveViewer(
                                minScale: 1,
                                maxScale: 3,
                                child: i == 0 ? Hero(tag: 'piece-${product.id}', child: img) : img,
                              );
                            },
                          ),
                  ),
                  IgnorePointer(
                    child: Column(
                      children: [
                        Container(
                          height: top + 80,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x55000000), Color(0x00000000)],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 150,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0x66000000)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: top + 8,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _RoundButton(
                          tooltip: 'Back',
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        _RoundButton(
                          tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
                          icon: saved ? Icons.favorite : Icons.favorite_border,
                          color: saved ? AppColors.gold : AppColors.ink,
                          onTap: () => state.toggleWishlist(product),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: top + 74,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FrameLabel(
                        eyewear ? '$number · worn as eyewear' : '$number · swipe · pinch to zoom',
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 22,
                    child: Column(
                      children: [
                        if (!eyewear)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < product.gallery.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == page ? 22 : 14,
                                  height: 2,
                                  color: i == page ? Colors.white : Colors.white54,
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        _ModeToggle(eyewear: eyewear, onChanged: (v) => setState(() => eyewear = v)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- details -------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(product.categoryLabel),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: Text(product.name, style: AppText.serif(size: 44))),
                      Text(formatAed(product.price), style: AppText.serif(size: 22)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(product.story, style: AppText.body(size: 15.5)),
                  if (!product.inStock || product.stock <= 5) ...[
                    const SizedBox(height: 10),
                    Text(
                      product.inStock ? 'Only ${product.stock} left' : 'Sold out',
                      style: AppText.caps(color: product.inStock ? AppColors.gold : AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Text('FINISH', style: AppText.caps(color: AppColors.ink, size: 12)),
                      const SizedBox(width: 12),
                      Text(options.finish.label, style: AppText.sans(size: 13.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final (f, color) in [
                        (Finish.solidGold, AppColors.goldBright),
                        (Finish.goldPlated, AppColors.plated),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Semantics(
                            button: true,
                            selected: options.finish == f,
                            label: f.label,
                            excludeSemantics: true,
                            child: InkResponse(
                              radius: 30,
                              onTap: () => _set(options.copyWith(finish: f)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: options.finish == f ? AppColors.ink : Colors.transparent,
                                    width: 1.2,
                                  ),
                                ),
                                child: CircleAvatar(backgroundColor: color),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Text('LENSES', style: AppText.caps(color: AppColors.ink, size: 12)),
                      const Spacer(),
                      UnderlineLink(
                        'Lens guide',
                        color: AppColors.gold,
                        size: 13.5,
                        onTap: () => ShellScope.go(context, AppTab.lenses),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final lens in LensType.values) ...[
                    _LensOption(
                      lens: lens,
                      selected: options.lens == lens,
                      onTap: () => _set(options.copyWith(lens: lens)),
                      child: switch (lens) {
                        LensType.reading when options.lens == LensType.reading => _StrengthPicker(
                          value: options.strength,
                          onChanged: (s) => _set(options.copyWith(strength: s)),
                        ),
                        LensType.prescription when options.lens == LensType.prescription => _PrescriptionLine(
                          prescription: state.prescription,
                        ),
                        _ => null,
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  Material(
                    color: AppColors.sand,
                    child: InkWell(
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransformationScreen())),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 84,
                              height: 84,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Photo(product.gallery.last),
                                  Container(color: const Color(0x55000000)),
                                  const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Watch it transform', style: AppText.serif(size: 23)),
                                  const SizedBox(height: 4),
                                  Text('From necklace to eyewear, step by step', style: AppText.sans(size: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AccordionRow(
                    title: 'Details and dimensions',
                    child: Text(
                      product.isWearable
                          ? 'Wearable eyewear. The pendant opens into glasses with slender temples that rest on the ears. '
                                'Available with plain, prescription or reading lenses.'
                          : 'Handheld eyewear. The pendant lifts into a lens held gracefully to the eyes, then closes '
                                'and becomes jewelry again. Available with plain, prescription or reading lenses.',
                      style: AppText.body(size: 14.5),
                    ),
                  ),
                  AccordionRow(
                    title: 'Materials and care',
                    child: Text(
                      'Choose 18k solid gold or gold plated. Close the piece gently before wearing it as a necklace, '
                      'clean the lenses with a soft cloth, and store it in its box when you are not wearing it.',
                      style: AppText.body(size: 14.5),
                    ),
                  ),
                  AccordionRow(
                    title: 'Delivery and returns',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery is confirmed at checkout. For returns or questions, write to client care.',
                          style: AppText.body(size: 14.5),
                        ),
                        UnderlineLink(
                          'hello@vueandor.com',
                          color: AppColors.gold,
                          onTap: () => launchUrl(Uri.parse('mailto:hello@vueandor.com')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        options.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(size: 12),
                      ),
                      Text(formatAed(product.price), style: AppText.serif(size: 24)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: !product.inStock || adding ? null : _add,
                    child: adding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(product.inStock ? 'ADD TO BAG' : 'SOLD OUT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _RoundButton({required this.tooltip, required this.icon, required this.onTap, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(backgroundColor: AppColors.paper, fixedSize: const Size(46, 46)),
      icon: Icon(icon, size: 18, color: color),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool eyewear;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.eyewear, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool value) {
      final on = eyewear == value;
      return Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: AppText.sans(
                size: 12,
                weight: FontWeight.w600,
                letterSpacing: 2,
                color: on ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(26)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('NECKLACE', false), seg('EYEWEAR', true)]),
    );
  }
}

class _LensOption extends StatelessWidget {
  final LensType lens;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  const _LensOption({required this.lens, required this.selected, required this.onTap, this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.paper : Colors.transparent,
            border: Border.all(color: selected ? AppColors.ink : AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Radio(selected: selected),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lens.label,
                          style: AppText.sans(size: 15.5, weight: FontWeight.w500, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(lens.description, style: AppText.sans(size: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.topCenter,
                child: child == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(padding: const EdgeInsets.only(top: 14, left: 36), child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.ink : AppColors.muted, width: 1.4),
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 10 : 0,
        height: selected ? 10 : 0,
        decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
      ),
    );
  }
}

class _StrengthPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StrengthPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in readingStrengths)
          Semantics(
            button: true,
            selected: s == value,
            child: InkWell(
              onTap: () => onChanged(s),
              child: Container(
                constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: s == value ? AppColors.ink : AppColors.paper,
                  border: Border.all(color: s == value ? AppColors.ink : AppColors.line),
                ),
                child: Text(s, style: AppText.sans(size: 13, color: s == value ? Colors.white : AppColors.ink)),
              ),
            ),
          ),
      ],
    );
  }
}

class _PrescriptionLine extends StatelessWidget {
  final Prescription? prescription;
  const _PrescriptionLine({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    return Row(
      children: [
        Expanded(
          child: Text(
            p == null
                ? 'No prescription saved yet.'
                : 'Saved · R ${p.rightSph.isEmpty ? '—' : p.rightSph}  L ${p.leftSph.isEmpty ? '—' : p.leftSph}'
                      '${p.pd.isEmpty ? '' : '  PD ${p.pd}'}',
            style: AppText.sans(size: 13, color: AppColors.ink),
          ),
        ),
        UnderlineLink(
          p == null ? 'Add' : 'Edit',
          color: AppColors.gold,
          size: 13.5,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrescriptionScreen())),
        ),
      ],
    );
  }
}
