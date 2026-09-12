// The sphere-lattice modes: globe (searching), rubik (solving) and
// wave (listening). All draw a lat/long dot field with mode-specific
// motion, then hand off to the shared z-sorted painter.
import 'dart:math' as math;

import '../orb_core.dart';

// --- the shared solver heartbeat (rubik) ------------------------------
// Rapid eased moves scramble, then replay in reverse (palindrome) so
// everything clicks back to solved, rests, repeats.

/// One quarter turn of a band: which axis it spins about, the slab of that
/// axis it grabs (`lo` .. `hi`) and the signed angle it sweeps.
class Move {
  const Move({
    required this.axis,
    required this.lo,
    required this.hi,
    required this.ang,
  });

  /// 0 = x, 1 = y, 2 = z.
  final int axis;
  final double lo;
  final double hi;
  final double ang;
}

/// The state of the scramble/solve palindrome at one instant: how far each
/// move has progressed, and which one is currently turning (-1 while resting).
class SolveCycle {
  const SolveCycle(this.amount, this.active);

  final List<double> amount;
  final int active;
}

/// Where the scramble → solve palindrome stands at [time].
SolveCycle solveCycle(double time, int count, double slotDur, double rest) {
  final double cyc = 2 * count * slotDur + rest;
  final double tc = time % cyc;
  final List<double> amount = List<double>.filled(count, 0);
  int active = -1;
  if (tc < 2 * count * slotDur) {
    final int slot = (tc / slotDur).floor();
    final double p = (tc - slot * slotDur) / slotDur;
    final double cl = math.min(1.0, p / 0.7);
    final double ep = 1 - (1 - cl) * (1 - cl) * (1 - cl); // machine ease-out
    if (slot < count) {
      for (int i = 0; i < slot; i++) {
        amount[i] = 1;
      }
      amount[slot] = ep;
      active = slot;
    } else {
      final int u = 2 * count - 1 - slot;
      for (int i = 0; i < u; i++) {
        amount[i] = 1;
      }
      amount[u] = 1 - ep;
      active = u;
    }
  }
  return SolveCycle(amount, active);
}

/// A point after the move stack has been applied, plus whether it sits in the
/// band that is turning right now.
class MovedPoint {
  const MovedPoint(this.x, this.y, this.z, this.inActive);

  final double x;
  final double y;
  final double z;
  final bool inActive;
}

/// Runs [pt3] through every partially-or-fully applied move in order.
///
/// The coordinates are carried forward from one move to the next, so the
/// sequence matters: a later move grabs its slab out of the *already rotated*
/// point, exactly as turning a real puzzle does.
MovedPoint applyMoves(List<double> pt3, List<Move> moves, SolveCycle sc) {
  double x = pt3[0];
  double y = pt3[1];
  double z = pt3[2];
  bool inActive = false;
  for (int i = 0; i < moves.length; i++) {
    if (sc.amount[i] <= 0) continue;
    final Move mv = moves[i];
    final double coord = mv.axis == 0
        ? x
        : mv.axis == 1
            ? y
            : z;
    if (coord < mv.lo || coord >= mv.hi) continue;
    if (i == sc.active) inActive = true;
    final double a = mv.ang * sc.amount[i];
    final double ca = math.cos(a);
    final double sa = math.sin(a);
    if (mv.axis == 0) {
      final double y2 = y * ca - z * sa;
      z = y * sa + z * ca;
      y = y2;
    } else if (mv.axis == 1) {
      final double x2 = x * ca + z * sa;
      z = -x * sa + z * ca;
      x = x2;
    } else {
      final double x2 = x * ca - y * sa;
      y = x * sa + y * ca;
      x = x2;
    }
  }
  return MovedPoint(x, y, z, inActive);
}

/// The fixed move list, derived from the hash so the same puzzle replays
/// every cycle.
List<Move> makeMoves(int count) {
  final List<Move> moves = <Move>[];
  for (int i = 0; i < count; i++) {
    final int axis = math.min(2, (hashD(i.toDouble(), 2.3) * 3).floor());
    final double lo =
        -1.0 + 0.5 * math.min(3, (hashD(i.toDouble(), 5.9) * 4).floor());
    final double dir = hashD(i.toDouble(), 7.7) < 0.5 ? 1.0 : -1.0;
    moves.add(Move(axis: axis, lo: lo, hi: lo + 0.5, ang: (dir * math.pi) / 2));
  }
  return moves;
}

// --- Globe: lat/long field, a scan meridian sweeps — searching --------

/// Globe — a lat/long dot field with a meridian sweeping across it.
OrbFrame frameGlobe(double size, double t, OrbOpts o) {
  const double spin = 0.5;
  final double cx = size / 2;
  final double cy = size / 2;
  final double radius = (size / 2) * 0.82;
  final double tilt = 0.4 + 0.06 * math.sin(t * 0.35);
  final OrbProjector pt = makeProj(t * spin, tilt, cx, cy, radius);
  // scan sweeps relative to the spin; scanMul scales that relative rate
  final double scan = t * (spin + (1.7 - spin) * (o['scanMul'] ?? 1));
  final double rs = radiusScale(size, o['rsPow'] ?? 0.6);
  final double dimBase = o['dimBase'] ?? 1;

  final List<OrbDot> dots = <OrbDot>[];
  final int latRings = (o['latRings'] ?? 17).round();
  final double lonDensity = o['lonDensity'] ?? 44;
  for (int li = 0; li <= latRings; li++) {
    final double lat = -math.pi / 2 + (li / latRings) * math.pi;
    final double cosLat = math.cos(lat);
    final double sinLat = math.sin(lat);
    final int lonCount = math.max(1, (cosLat.abs() * lonDensity).round());
    for (int lj = 0; lj < lonCount; lj++) {
      final double lon = (lj / lonCount) * 2 * math.pi;
      final List<double> p = pt(
        cosLat * math.cos(lon),
        sinLat,
        cosLat * math.sin(lon),
      );
      final double px = p[0];
      final double py = p[1];
      final double z = p[2];
      final double depth = (z + 1) / 2;
      // the scan: a moving meridian read as a size ripple, not a shine
      final double d = angleDelta(lon + t * spin, scan);
      final double boost = math.exp(-(d * d) / 0.18) * math.max(0.0, z);
      dots.add(
        OrbDot(
          x: px,
          y: py,
          z: z,
          r: ((o['rBase'] ?? 0.6) +
                  (o['rDepth'] ?? 1.7) * depth +
                  (o['rBoost'] ?? 1) * boost) *
              rs,
          white: (o['inkFar'] ?? 0.62) - (o['inkSpan'] ?? 0.54) * depth,
          // dimBase < 1 fades un-scanned dots so the meridian reads clearly
          a: dimBase + (1 - dimBase) * math.min(1.0, boost),
        ),
      );
    }
  }
  return finalizeFrame(dots, <OrbLine>[], o['rMin'] ?? 0.3);
}

// --- Rubik: bands twist in quarter turns, scramble → solve — solving --

/// Rubik — bands of the lattice twist in quarter turns, scramble then solve.
OrbFrame frameRubik(double size, double t, OrbOpts o) {
  final double cx = size / 2;
  final double cy = size / 2;
  final double R = (size / 2) * 0.82;
  final OrbProjector pt = makeProj(
    t * 0.55,
    0.35 + 0.1 * math.sin(t * 0.9),
    cx,
    cy,
    R,
  );
  final double rs = radiusScale(size, o['rsPow'] ?? 0.6);
  final int moveCount = (o['moveCount'] ?? 14).round();
  final List<Move> moves = makeMoves(moveCount);
  final SolveCycle sc = solveCycle(t, moveCount, 0.42, 1.2);

  final List<OrbDot> dots = <OrbDot>[];
  final int latRings = (o['latRings'] ?? 15).round();
  final double lonDensity = o['lonDensity'] ?? 40;
  for (int li = 0; li <= latRings; li++) {
    final double lat = -math.pi / 2 + (li / latRings) * math.pi;
    final double cosLat = math.cos(lat);
    final double sinLat = math.sin(lat);
    final int lonCount = math.max(1, (cosLat.abs() * lonDensity).round());
    for (int lj = 0; lj < lonCount; lj++) {
      final double lon = (lj / lonCount) * 2 * math.pi;
      final MovedPoint mp = applyMoves(<double>[
        cosLat * math.cos(lon),
        sinLat,
        cosLat * math.sin(lon),
      ], moves, sc);
      final List<double> p = pt(mp.x, mp.y, mp.z);
      final double px = p[0];
      final double py = p[1];
      final double zr = p[2];
      final double depth = (zr + 1) / 2;
      // the band being turned inks a touch darker — the "hand"
      dots.add(
        OrbDot(
          x: px,
          y: py,
          z: zr,
          r: ((o['rBase'] ?? 0.6) +
                  (o['rDepth'] ?? 1.7) * depth +
                  (mp.inActive ? (o['rActive'] ?? 0.3) : 0.0)) *
              rs,
          white: (o['inkFar'] ?? 0.62) -
              (o['inkSpan'] ?? 0.54) * depth -
              (mp.inActive ? 0.14 : 0.0),
        ),
      );
    }
  }
  return finalizeFrame(dots, <OrbLine>[], o['rMin'] ?? 0.3);
}

// --- Wave: a waveform rolls through the rings — listening -------------

/// Wave — a waveform rolls through the rings, breathing the sphere in and out.
OrbFrame frameWave(double size, double t, OrbOpts o) {
  final double cx = size / 2;
  final double cy = size / 2;
  // 0.76 base x 1.15 — the undulation pulls the sphere inward, so wave read
  // ~15% smaller than the other lattice modes; scaled up to match them
  final double R = (size / 2) * 0.874;
  final OrbProjector pt = makeProj(t * 0.18, 0.38, cx, cy, 1);
  final double rs = radiusScale(size, o['rsPow'] ?? 0.6);

  final List<OrbDot> dots = <OrbDot>[];
  final int rings = (o['rings'] ?? 15).round();
  final double lonDensity = o['lonDensity'] ?? 40;
  for (int ri = 0; ri <= rings; ri++) {
    final double lat = -math.pi / 2 + (ri / rings) * math.pi;
    final double cosLat = math.cos(lat);
    final double sinLat = math.sin(lat);
    // two waves, different tempi — organic, never quite repeating
    final double w = 0.62 * math.sin(t * 2.1 - ri * 0.52) +
        0.38 * math.sin(t * 1.27 + ri * 0.83);
    final double rr = R * (0.88 + 0.105 * w);
    final int lonCount = math.max(1, (cosLat.abs() * lonDensity).round());
    for (int lj = 0; lj < lonCount; lj++) {
      final double lon = (lj / lonCount) * 2 * math.pi;
      final List<double> p = pt(
        cosLat * math.cos(lon) * rr,
        sinLat * rr,
        cosLat * math.sin(lon) * rr,
      );
      final double px = p[0];
      final double py = p[1];
      final double z = p[2];
      final double depth = (z / R + 1) / 2;
      final double crest = math.max(0.0, w);
      dots.add(
        OrbDot(
          x: px,
          y: py,
          z: z,
          r: ((o['rBase'] ?? 0.6) + (o['rDepth'] ?? 1.7) * depth) *
              (1 + 0.4 * crest) *
              rs,
          white: 0.66 - 0.56 * depth - 0.1 * crest,
        ),
      );
    }
  }
  return finalizeFrame(dots, <OrbLine>[], o['rMin'] ?? 0.3);
}
