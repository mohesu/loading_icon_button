// Morph: a dotted outline cycling circle -> triangle -> square -> circle —
// the "shaping" state. Each shape is a continuous closed path parameterised
// by arc length (top-centre start, clockwise). Every frame the engine blends
// the two neighbouring paths, then lays the dots EVENLY along the blended
// outline — spacing stays uniform at every instant of the morph, holds and
// transitions alike. Plain filled circles only, so nothing here needs a
// blur, a mask or any other compositing trick.
import 'dart:math' as math;

import '../orb_core.dart';

/// A closed outline parameterised by normalised arc length `f` in [0, 1).
/// Returns `[x, y]` in unit-box space (the orb is 1.0 wide).
typedef OrbPath = List<double> Function(double f);

/// Smoothstep easing on an already-normalised `x`.
double smoothE(double x) => x * x * (3 - 2 * x);

/// Builds an arc-length-parameterised path around a closed polygon.
///
/// Segment lengths are measured once up front so the returned closure can
/// walk them cumulatively; the `while` guard checks the remaining target
/// BEFORE the index bound, which is what pins the last segment as the
/// catch-all for `f == 1`.
OrbPath polyPath(List<List<double>> verts) {
  final int v = verts.length;
  final List<double> l = <double>[];
  double total = 0;
  for (int i = 0; i < v; i++) {
    final List<double> a = verts[i];
    final List<double> b = verts[(i + 1) % v];
    final double seg = math.sqrt(
      (b[0] - a[0]) * (b[0] - a[0]) + (b[1] - a[1]) * (b[1] - a[1]),
    );
    l.add(seg);
    total += seg;
  }
  return (double f) {
    double target = f * total;
    int i = 0;
    while (target > l[i] && i < v - 1) {
      target -= l[i];
      i++;
    }
    final List<double> a = verts[i];
    final List<double> b = verts[(i + 1) % v];
    final double ff = l[i] != 0 ? math.min(1.0, target / l[i]) : 0.0;
    return <double>[
      a[0] + (b[0] - a[0]) * ff,
      a[1] + (b[1] - a[1]) * ff,
    ];
  };
}

/// The circle leg of the cycle: a plain parametric circle starting at
/// top-centre and running clockwise.
List<double> orbCirclePath(double f) {
  final double a = -math.pi / 2 + f * 2 * math.pi;
  return <double>[math.cos(a) * 0.24, math.sin(a) * 0.24];
}

/// The circle leg of the cycle.
final OrbPath kOrbCircle = orbCirclePath;

/// The triangle leg of the cycle.
final OrbPath kOrbTriangle = polyPath(<List<double>>[
  <double>[0.0, -0.26],
  <double>[0.24, 0.16],
  <double>[-0.24, 0.16],
]);

/// The square leg of the cycle. Five vertices, not four: the extra one makes
/// the walk START at top-centre like the other shapes.
final OrbPath kOrbSquare = polyPath(<List<double>>[
  <double>[0, -0.2],
  <double>[0.2, -0.2],
  <double>[0.2, 0.2],
  <double>[-0.2, 0.2],
  <double>[-0.2, -0.2],
]);

/// The shape cycle, in order.
final List<OrbPath> kOrbCycle = <OrbPath>[kOrbCircle, kOrbTriangle, kOrbSquare];

/// Dot count for the outline. A low floor keeps sparse outlines possible
/// while never degenerating.
int morphN(double d) => math.max(6, (34 * d).round());

/// Seconds a shape is held fully formed.
const double kOrbMorphHold = 1.4;

/// Seconds spent transitioning to the next shape.
const double kOrbMorphMorph = 0.9;

/// One full hold + transition leg.
const double kOrbMorphSeg = kOrbMorphHold + kOrbMorphMorph;

/// Builds one frame of the `shaping` outline.
///
/// This state was tuned in inkform, which paints it through a blur +
/// threshold "goo" effect; we draw plain circles instead. The dot GEOMETRY
/// is identical either way — thresholding just yields a hard edge where a
/// plain fill has an antialiased one, so these dots read a touch softer than
/// inkform's. Don't "correct" for that by shrinking the radius: it makes the
/// mark genuinely smaller than the tuning.
OrbFrame frameMorph(double size, double t, OrbOpts opts) {
  final int k0 = kOrbCycle.length;
  final double tc = t % (kOrbMorphSeg * k0);
  final int k = (tc / kOrbMorphSeg).floor();
  final double local = tc - k * kOrbMorphSeg;
  final double m = local > kOrbMorphHold
      ? smoothE((local - kOrbMorphHold) / kOrbMorphMorph)
      : 0.0;
  final double sprd = opts['spread'] ?? 1;

  // Blend the two shape PATHS at m, then measure the blended outline.
  final OrbPath pA = kOrbCycle[k];
  final OrbPath pB = kOrbCycle[(k + 1) % k0];
  const int mSamples = 160;
  final List<List<double>> pts = <List<double>>[];
  for (int i = 0; i < mSamples; i++) {
    final double f = i / mSamples;
    final List<double> a = pA(f);
    final List<double> b = pB(f);
    pts.add(<double>[
      (a[0] + (b[0] - a[0]) * m) * sprd,
      (a[1] + (b[1] - a[1]) * m) * sprd,
    ]);
  }
  final List<double> l = <double>[];
  double total = 0;
  for (int i = 0; i < mSamples; i++) {
    final List<double> a = pts[i];
    final List<double> b = pts[(i + 1) % mSamples];
    final double len = math.sqrt(
      (b[0] - a[0]) * (b[0] - a[0]) + (b[1] - a[1]) * (b[1] - a[1]),
    );
    l.add(len);
    total += len;
  }

  // Dot radius depends ONLY on rDot (the size knob); the count sets the
  // gaps. Formed shapes breathe a little (uniform pulse).
  final int n = morphN(opts['iconD'] ?? 1);
  final double re = (opts['rDot'] ?? 0.021) * 1.35 * sprd;
  final double pulse = 1 + 0.02 * math.sin(local * 3.1);

  final List<OrbDot> dots = <OrbDot>[];
  final double c2 = size / 2;
  int seg = 0;
  double acc = 0;
  for (int k2 = 0; k2 < n; k2++) {
    final double target = (k2 / n) * total;
    while (acc + l[seg] < target && seg < mSamples - 1) {
      acc += l[seg];
      seg++;
    }
    final List<double> a = pts[seg];
    final List<double> b = pts[(seg + 1) % mSamples];
    final double f = l[seg] != 0 ? math.min(1.0, (target - acc) / l[seg]) : 0.0;
    final double x = (a[0] + (b[0] - a[0]) * f) * pulse;
    final double y = (a[1] + (b[1] - a[1]) * f) * pulse;
    dots.add(
      OrbDot(
        x: c2 + x * size,
        y: c2 + y * size,
        z: 0,
        r: math.max(0.35, re * size),
        white: 0.1,
      ),
    );
  }
  return finalizeFrame(dots, <OrbLine>[], opts['rMin'] ?? 0.3);
}
