import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'orb_core.dart';
import 'orb_presets.dart';
import 'orb_registry.dart';

/// Paints one instant of a thinking orb.
///
/// The painter is driven by [repaint] — a notifier carrying elapsed seconds —
/// so a running orb repaints without ever rebuilding the widget tree.
class OrbPainter extends CustomPainter {
  OrbPainter({
    required this.resolved,
    required this.time,
    required this.dark,
    required this.color,
  }) : super(repaint: time);

  /// The mode and fully-scaled options for this orb's state and size tier.
  final ResolvedOrb resolved;

  /// Elapsed clock seconds, already multiplied by this orb's speed.
  final ValueListenable<double> time;

  /// Whether to paint light ink (for dark substrates) or dark ink.
  final bool dark;

  /// Optional ink tint. When null the orb is monochrome, as designed.
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final double side = size.shortestSide;
    if (side <= 0) return;

    final OrbFrame frame =
        kOrbModeFrames[resolved.mode]!(side, time.value, resolved.opts);

    // Lines first, so nodes sit on top of their own edges.
    if (frame.lines.isNotEmpty) {
      final Paint stroke = Paint()..style = PaintingStyle.stroke;
      for (final OrbLine l in frame.lines) {
        stroke
          ..color = _ink(l.white, l.a ?? 1)
          ..strokeWidth = l.w;
        canvas.drawLine(
          Offset(l.x1, l.y1),
          Offset(l.x2, l.y2),
          stroke,
        );
      }
    }

    final Paint fill = Paint()..isAntiAlias = true;
    for (final OrbDot d in frame.dots) {
      fill.color = _ink(d.white, d.a ?? 1);
      canvas.drawCircle(Offset(d.x, d.y), d.r, fill);
    }
  }

  /// Maps an ink value and alpha onto a paint colour.
  ///
  /// The monochrome mapping is the designed one: `white` is an ink value where
  /// 0 is the darkest mark, and on dark substrates it is mirrored so near dots
  /// read bright. That is the same depth language on an inverted substrate,
  /// not a second palette.
  ///
  /// When a tint is supplied there is no grey ramp to mirror, so ink strength
  /// (`1 - white`, which is high for near dots under both substrates) drives
  /// alpha instead and the hue stays constant.
  Color _ink(double white, double alpha) {
    final double w = white.clamp(0.0, 1.0);
    final int a = (alpha.clamp(0.0, 1.0) * 255).round();
    final Color? tint = color;
    if (tint != null) {
      return tint.withAlpha((a * (1 - w)).round());
    }
    final int g = ((dark ? 1 - w : w) * 255).round();
    return Color.fromARGB(a, g, g, g);
  }

  @override
  bool shouldRepaint(OrbPainter old) =>
      old.resolved != resolved ||
      old.dark != dark ||
      old.color != color ||
      old.time != time;

  @override
  bool shouldRebuildSemantics(OrbPainter oldDelegate) => false;

  /// Renders one frame to an image. Used by the golden tests.
  static Future<ui.Image> renderFrame({
    required OrbState state,
    required double size,
    required double time,
    bool dark = false,
    Color? color,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    OrbPainter(
      resolved: resolvePreset(state, tierForSize(size)),
      time: ValueNotifier<double>(time),
      dark: dark,
      color: color,
    ).paint(canvas, Size(size, size));
    return recorder.endRecording().toImage(size.ceil(), size.ceil());
  }
}
