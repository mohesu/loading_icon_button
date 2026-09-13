// Braid: three strands plait around the sphere — the "weaving" state.
// Each strand runs pole to pole on a helix, and a radial breathing term
// makes them trade places, reading as the over/under of a plait.
//
// Ported to Dart from `thinking-orbs` by Jakub Antalik (MIT).
import 'dart:math' as math;

import '../orb_core.dart';

/// Builds one frame of the braid ("weaving") mode.
///
/// Tuning keys: `rsPow`, `ghostN`, `strandN`, `turns`, `rBase`, `rDepth`,
/// `rMin`.
OrbFrame frameBraid(double size, double t, OrbOpts o) {
  final double cx = size / 2;
  final double cy = size / 2;
  final double R = (size / 2) * 0.76;
  final OrbProjector pt = makeProj(t * 0.4, 0.3, cx, cy, 1);
  final double rs = radiusScale(size, o['rsPow'] ?? 0.6);

  final List<OrbDot> dots = <OrbDot>[];
  final int ghostN = (o['ghostN'] ?? 150).round();
  for (int i = 0; i < ghostN; i++) {
    final List<double> d = fibDir(i, ghostN);
    final List<double> p = pt(d[0] * R, d[1] * R, d[2] * R);
    final double px = p[0];
    final double py = p[1];
    final double z = p[2];
    final double depth = (z / R + 1) / 2;
    dots.add(
      OrbDot(
        x: px,
        y: py,
        z: z,
        r: 0.8 * rs,
        white: 0.78,
        a: 0.1 + 0.22 * depth,
      ),
    );
  }

  final int strandN = (o['strandN'] ?? 52).round();
  final double turns = o['turns'] ?? 3;
  for (int s = 0; s < 3; s++) {
    final double phase = (s / 3) * 2 * math.pi;
    for (int i = 0; i < strandN; i++) {
      // u walks pole to pole; the frac() drift slides the whole strand along
      final double u = (frac(i / strandN + t * 0.045) * 2 - 1) * 0.96;
      final double surf = math.sqrt(math.max(0.0, 1 - u * u));
      final double endFade = math.min(1.0, (1 - u.abs()) / 0.1);
      final double a = u * math.pi * turns + phase;
      // radial breathing: strands trade places — the over/under of a plait
      final double weave =
          1 + 0.075 * math.sin(u * math.pi * turns * 2 + phase * 2 + t * 0.8);
      final double rr = surf * R * weave;
      final List<double> p = pt(
        math.cos(a) * rr,
        u * R * weave,
        math.sin(a) * rr,
      );
      final double px = p[0];
      final double py = p[1];
      final double zr = p[2];
      final double depth = (zr / R + 1) / 2;
      dots.add(
        OrbDot(
          x: px,
          y: py,
          z: zr,
          r: ((o['rBase'] ?? 1.2) + (o['rDepth'] ?? 1.8) * depth) * rs,
          white: 0.55 - 0.45 * depth,
          a: endFade * (0.45 + 0.55 * depth),
        ),
      );
    }
  }
  return finalizeFrame(dots, <OrbLine>[], o['rMin'] ?? 0.3);
}
