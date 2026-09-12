// Ribbon: an undulating sash of parallel strands rides a great circle —
// the "composing" state. The tuned preset freezes the 3D tumble
// (spin 0), leaving the traveling undulation on a fixed band.
//
// The same painter also drives "breathing" (ring), via the `faceOn` flag:
// a face-on circle whose radius — not its out-of-plane offset — undulates,
// so it reads as a ring slowly morphing rather than a sash in orbit.
//
// Ported to Dart from `thinking-orbs` by Jakub Antalik (MIT).
import 'dart:math' as math;

import '../orb_core.dart';

/// Builds one frame of the ribbon ("composing") mode, and — with a non-zero
/// `faceOn` — the ring ("breathing") mode.
///
/// Tuning keys: `spin`, `rsPow`, `ghostN`, `faceOn`, `wobMul`, `lanes`,
/// `segs`, `bandMul`, `rBase`, `rDepth`, `rMin`.
OrbFrame frameRibbon(double size, double t, OrbOpts o) {
  final double cx = size / 2;
  final double cy = size / 2;
  final double R = (size / 2) * 0.78;
  // spin scales the 3D tumble; spin=0 freezes the band's orientation,
  // leaving only the traveling undulation
  final double spin = o['spin'] ?? 1;
  final double camTilt = 0.3;
  final OrbProjector pt = makeProj(t * 0.1 * spin, camTilt, cx, cy, 1);
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

  // The band plane, precessing (frozen when spin=0). The projection squashes
  // the band's great circle vertically by cos(ta + camTilt); face-on sets
  // ta = -camTilt so that term is 1 and the band reads as a true circle
  // rather than ribbon's tilted ellipse.
  final double ya = t * 0.24 * spin;
  final double ta = (o['faceOn'] ?? 0) != 0
      ? -camTilt
      : 0.55 + 0.3 * math.sin(t * 0.18) * spin;
  final double ux = math.cos(ya);
  final double uy = 0;
  final double uz = math.sin(ya);
  final double vx = -uz * math.sin(ta);
  final double vy = math.cos(ta);
  final double vz = ux * math.sin(ta);
  // plane normal n = u × v
  final double nx = uy * vz - uz * vy;
  final double ny = uz * vx - ux * vz;
  final double nz = ux * vy - uy * vx;

  // Radial lobes swell past R, so pull the base radius in by (most of) the
  // wobble amplitude. The silhouette then stays inside the frame however far
  // the deformation is pushed, while lobes keep getting deeper relative to
  // the mean radius.
  final double wobAmp = 0.23 * (o['wobMul'] ?? 1);
  final double baseR = (o['faceOn'] ?? 0) != 0 ? R / (1 + 0.85 * wobAmp) : R;

  final double baseLanes = o['lanes'] ?? 5;
  final int segs = (o['segs'] ?? 88).round();
  final int lanes = math.max(1, (baseLanes * (o['bandMul'] ?? 1)).round());
  for (int w = 0; w < lanes; w++) {
    final double laneOff = (w - (lanes - 1) / 2) * 0.075;
    final double edge =
        (w - (lanes - 1) / 2).abs() / math.max(1.0, (lanes - 1) / 2);
    for (int k = 0; k < segs; k++) {
      final double a = (k / segs) * 2 * math.pi;
      // the undulation: two traveling waves along the band; wobMul
      // scales the deformation — 0 is a clean band
      final double wob = (0.16 * math.sin(a * 3 - t * 1.7 + w * 0.22) +
              0.07 * math.sin(a * 5 + t * 1.1)) *
          (o['wobMul'] ?? 1);
      // A normal-direction wobble is cancelled by the re-normalisation below:
      // the point lands back on the sphere, so the silhouette is pinned at R
      // and the deformation can only ever pull dots inward. Face-on instead
      // modulates the in-plane RADIUS, so lobes genuinely swell outward and
      // pinch inward. Ribbon keeps the original out-of-plane sash wobble.
      final double radial = (o['faceOn'] ?? 0) != 0 ? 1 + wob : 1;
      final double off = (o['faceOn'] ?? 0) != 0 ? laneOff : laneOff + wob;
      final double x = ux * math.cos(a) + vx * math.sin(a) + nx * off;
      final double y = uy * math.cos(a) + vy * math.sin(a) + ny * off;
      final double z = uz * math.cos(a) + vz * math.sin(a) + nz * off;
      final double l = math.sqrt(x * x + y * y + z * z);
      final double rr = baseR * radial;
      final List<double> p = pt((x / l) * rr, (y / l) * rr, (z / l) * rr);
      final double px = p[0];
      final double py = p[1];
      final double zr = p[2];
      final double depth = (zr / R + 1) / 2;
      dots.add(
        OrbDot(
          x: px,
          y: py,
          z: zr,
          r: ((o['rBase'] ?? 1.1) + (o['rDepth'] ?? 1.7) * depth) *
              (1 - 0.25 * edge) *
              rs,
          white: 0.52 - 0.44 * depth + 0.18 * edge,
          a: 0.4 + 0.6 * depth,
        ),
      );
    }
  }
  return finalizeFrame(dots, <OrbLine>[], o['rMin'] ?? 0.3);
}
