// Orbits: particles on tilted orbits — the "working" state. No nucleus
// (the tuned preset runs coreless): just ghost paths and the particles
// doing the work.
import 'dart:math' as math;

import '../orb_core.dart';

/// Builds one frame of the `orbits` mode.
OrbFrame frameOrbits(double size, double t, OrbOpts o) {
  final double cx = size / 2;
  final double cy = size / 2;
  final double R = (size / 2) * 0.82;
  final OrbProjector pt = makeProj(t * 0.12, 0.3, cx, cy, 1);
  final double rs = radiusScale(size, o['rsPow'] ?? 0.6);

  final List<OrbDot> dots = <OrbDot>[];
  final int orbitN = (o['orbitN'] ?? 12).round();
  final int ghostN = (o['ghostN'] ?? 40).round();
  final int particles = (o['particles'] ?? 3).round();

  // orbits: each a tilted circle — a ghost path + running particles
  for (int orb = 0; orb < orbitN; orb++) {
    final double h1 = hashD(orb.toDouble(), 1.7);
    final double h2 = hashD(orb.toDouble(), 5.2);
    final double h3 = hashD(orb.toDouble(), 8.9);
    final double ro = R * (0.45 + 0.52 * h1);
    final double th = h1 * 2 * math.pi;
    final double phi = math.acos(2 * h2 - 1);
    // orbit plane basis (u, v perpendicular to the normal n)
    final double nx = math.sin(phi) * math.cos(th);
    final double ny = math.cos(phi);
    final double nz = math.sin(phi) * math.sin(th);
    double ux = -ny;
    double uy = nx;
    const double uz = 0;
    final double ul = math.max(1e-6, math.sqrt(ux * ux + uy * uy));
    ux /= ul;
    uy /= ul;
    final double vx = ny * uz - nz * uy;
    final double vy = nz * ux - nx * uz;
    final double vz = nx * uy - ny * ux;
    final double speed = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1 : -1);

    // ghost path
    for (int k = 0; k < ghostN; k++) {
      final double a = (k / ghostN) * 2 * math.pi;
      final List<double> p = pt(
        (ux * math.cos(a) + vx * math.sin(a)) * ro,
        (uy * math.cos(a) + vy * math.sin(a)) * ro,
        (uz * math.cos(a) + vz * math.sin(a)) * ro,
      );
      final double px = p[0];
      final double py = p[1];
      final double z = p[2];
      final double depth = (z / ro + 1) / 2;
      dots.add(
        OrbDot(
          x: px,
          y: py,
          z: z,
          r: (o['ghostR'] ?? 0.9) * rs,
          white: 0.72,
          a: (o['ghostA'] ?? 0.5) * (0.4 + 0.6 * depth),
        ),
      );
    }
    // the particles doing the work
    for (int m = 0; m < particles; m++) {
      final double a = t * speed + (m / particles) * 2 * math.pi + h2 * 6;
      final List<double> p = pt(
        (ux * math.cos(a) + vx * math.sin(a)) * ro,
        (uy * math.cos(a) + vy * math.sin(a)) * ro,
        (uz * math.cos(a) + vz * math.sin(a)) * ro,
      );
      final double px = p[0];
      final double py = p[1];
      final double z = p[2];
      final double depth = (z / ro + 1) / 2;
      dots.add(
        OrbDot(
          x: px,
          y: py,
          z: z,
          r: ((o['partR'] ?? 1.2) + (o['partRDepth'] ?? 1.6) * depth) * rs,
          white: 0.3 - 0.22 * depth,
        ),
      );
    }
  }
  return finalizeFrame(dots, <OrbLine>[], o['rMin'] ?? 0.3);
}
