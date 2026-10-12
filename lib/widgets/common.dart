import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../screens/auth_screen.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Bundled photo with the wireframe's hatched placeholder behind it.
class Photo extends StatelessWidget {
  final String asset;
  final BoxFit fit;
  final Alignment alignment;
  final String? semanticLabel;

  const Photo(this.asset, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) => sync
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: child,
            ),
      errorBuilder: (_, _, _) => const Hatch(),
    );
  }
}

/// Diagonal hairline hatch used for image frames in the wireframe.
class Hatch extends StatelessWidget {
  final Color background;
  final Color line;
  final Widget? child;

  const Hatch({super.key, this.background = AppColors.stone, this.line = const Color(0x14000000), this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HatchPainter(background, line), child: child ?? const SizedBox.expand());
  }
}

class _HatchPainter extends CustomPainter {
  final Color bg;
  final Color line;
  _HatchPainter(this.bg, this.line);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final p = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.bg != bg || old.line != line;
}

/// Fine gold-line drawing of the folded spectacles: stands in for eyewear
/// photography, which isn't in the photo set.
class GlassesArt extends StatelessWidget {
  final Color color;
  final bool handheld;

  const GlassesArt({super.key, this.color = AppColors.goldBright, this.handheld = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GlassesPainter(color, handheld), child: const SizedBox.expand());
  }
}

class _GlassesPainter extends CustomPainter {
  final Color color;
  final bool handheld;
  _GlassesPainter(this.color, this.handheld);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;
    final cy = size.height * 0.55;
    final r = w * 0.15;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Chain from the top corners down to the bridge.
    final chain = Path()
      ..moveTo(w * 0.12, 0)
      ..quadraticBezierTo(cx - r * 0.6, cy - r * 1.9, cx, cy - r * 0.55)
      ..quadraticBezierTo(cx + r * 0.6, cy - r * 1.9, w * 0.88, 0);
    final dashes = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final metric in chain.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 3.5), dashes);
      }
    }

    // Two lenses and the bridge.
    final left = Offset(cx - r * 1.15, cy);
    final right = Offset(cx + r * 1.15, cy);
    canvas.drawOval(Rect.fromCenter(center: left, width: r * 2, height: r * 1.7), p);
    canvas.drawOval(Rect.fromCenter(center: right, width: r * 2, height: r * 1.7), p);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.25), width: r * 0.6, height: r * 0.5),
      math.pi,
      math.pi,
      false,
      p,
    );

    if (handheld) {
      // A slender handle instead of temples.
      canvas.drawLine(Offset(right.dx + r, cy), Offset(right.dx + r * 2.4, cy + r * 1.6), p);
    } else {
      // Temples folding back.
      canvas.drawLine(Offset(left.dx - r, cy - r * 0.2), Offset(left.dx - r * 1.7, cy - r * 0.9), p);
      canvas.drawLine(Offset(right.dx + r, cy - r * 0.2), Offset(right.dx + r * 1.7, cy - r * 0.9), p);
    }

    // Soft lens sheen.
    final sheen = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (final c in [left, right]) {
      canvas.drawLine(c + Offset(-r * 0.45, -r * 0.2), c + Offset(-r * 0.05, -r * 0.55), sheen);
    }
  }

  @override
  bool shouldRepaint(_GlassesPainter old) => old.color != color || old.handheld != handheld;
}

/// "VUE & OR" wordmark with the gold italic ampersand.
class Wordmark extends StatelessWidget {
  final double size;
  final Color color;
  final double spacing;

  const Wordmark({super.key, this.size = 20, this.color = AppColors.ink, this.spacing = 4});

  @override
  Widget build(BuildContext context) {
    final style = AppText.serif(size: size, weight: FontWeight.w500, color: color, letterSpacing: spacing);
    return Semantics(
      label: 'VUE & OR',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'VUE ', style: style),
            TextSpan(
              text: '&',
              style: AppText.serif(size: size, color: AppColors.goldBright, italic: true),
            ),
            TextSpan(text: ' OR', style: style),
          ],
        ),
      ),
    );
  }
}

/// Heading with an optional italic second part: "Two ways to see. *Two finishes.*"
class SplitHeading extends StatelessWidget {
  final String plain;
  final String? italic;
  final TextStyle Function({Color color, bool italic}) style;
  final Color color;
  final Color? italicColor;

  const SplitHeading(
    this.plain, {
    super.key,
    this.italic,
    this.style = _h1,
    this.color = AppColors.ink,
    this.italicColor,
  });

  static TextStyle _h1({Color color = AppColors.ink, bool italic = false}) => AppText.h1(color: color, italic: italic);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: plain,
            style: style(color: color),
          ),
          if (italic != null)
            TextSpan(
              text: italic,
              style: style(color: italicColor ?? color, italic: true),
            ),
        ],
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = AppColors.gold});

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppText.eyebrow(color: color));
}

/// Small caps label over an image frame ("MODEL 01 · NECKLACE MODE").
class FrameLabel extends StatelessWidget {
  final String text;
  final Color color;
  const FrameLabel(this.text, {super.key, this.color = AppColors.text});

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppText.caps(color: color, size: 10.5));
}

/// Underlined text link ("Sign in", "Remove", "Continue shopping").
class UnderlineLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double size;

  const UnderlineLink(this.label, {super.key, this.onTap, this.color = AppColors.text, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppText.sans(size: size, color: color, decoration: TextDecoration.underline),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bag icon with a gold count badge.
class BagButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  const BagButton({super.key, required this.onPressed, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    final count = AppScope.of(context).bagCount;
    return IconButton(
      tooltip: count == 0 ? 'Bag' : 'Bag, $count items',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.goldBright,
        textColor: AppColors.ink,
        label: Text(
          '$count',
          style: AppText.sans(size: 10, weight: FontWeight.w700, color: AppColors.ink),
        ),
        child: Icon(Icons.shopping_bag_outlined, color: color, size: 22),
      ),
    );
  }
}

/// − 1 + boxed stepper.
class QtyStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  const QtyStepper({super.key, required this.value, this.min = 1, required this.max, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(border: Border.all(color: AppColors.lineStrong)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            iconSize: 16,
            icon: const Icon(Icons.remove),
            onPressed: onChanged == null || value <= min ? null : () => onChanged!(value - 1),
          ),
          SizedBox(
            width: 20,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppText.sans(size: 15, color: AppColors.ink),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            iconSize: 16,
            icon: const Icon(Icons.add),
            onPressed: onChanged == null || value >= max ? null : () => onChanged!(value + 1),
          ),
        ],
      ),
    );
  }
}

/// "Details and dimensions  +" expanding row.
class AccordionRow extends StatefulWidget {
  final String title;
  final Widget child;
  final Color color;

  const AccordionRow({super.key, required this.title, required this.child, this.color = AppColors.ink});

  @override
  State<AccordionRow> createState() => _AccordionRowState();
}

class _AccordionRowState extends State<AccordionRow> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            child: InkWell(
              onTap: () => setState(() => open = !open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title, style: AppText.sans(size: 15, color: widget.color)),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.125 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.add, size: 20, color: widget.color),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(padding: const EdgeInsets.only(bottom: 20), child: widget.child)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Simple top bar from the wireframes: caps title, optional back and actions.
PreferredSizeWidget capsAppBar(BuildContext context, String title, {List<Widget>? actions, bool back = false}) {
  return AppBar(
    automaticallyImplyLeading: back,
    leading: back
        ? IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        : null,
    title: Text(title.toUpperCase()),
    actions: actions,
  );
}

void showMessage(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

void showError(BuildContext context, Object error) =>
    showMessage(context, error is ApiException ? error.message : 'Something went wrong. Please try again.');

/// Opens sign-in if needed. Returns true when the user is signed in.
Future<bool> ensureSignedIn(BuildContext context, {String? reason}) async {
  final state = AppScope.read(context);
  if (state.signedIn) return true;
  final ok = await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => AuthScreen(reason: reason), fullscreenDialog: true));
  return ok == true && state.signedIn;
}

/// Retry block for failed loads.
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color color;

  const ErrorRetry({super.key, required this.message, required this.onRetry, this.color = AppColors.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.body(color: color),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
        ],
      ),
    );
  }
}
