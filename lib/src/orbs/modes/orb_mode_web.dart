// Web: a constellation wires itself — the "connecting" state. Nodes drift
// on the sphere under slow value noise; any pair closer than `thr` grows an
// edge, and bright packets run along randomly re-picked node pairs.
import 'dart:math' as math;

import '../orb_core.dart';

/// Builds one frame of the `connecting` web.
OrbFrame frameWeb(double size, double t, OrbOpts opts) {
  final double cx = size / 2;
  final double cy = size / 2;
  final double r = (size / 2) * 0.8 * (opts['spread'] ?? 1);
  // Note the projector carries the radius as its scale, so node vectors stay
  // unit-length and the distances below are in unit-sphere space.
  final OrbProjector pt = makeProj(t * 0.12, 0.32, cx, cy, r);
  final double rs = radiusScale(size, opts['rsPow'] ?? 0.6);

  final int nodeN = (opts['nodeN'] ?? 30).round();
  final double thr = opts['thr'] ?? 0.72;
  final double nodeR = opts['nodeR'] ?? 1.4;
  final double nodeRDepth = opts['nodeRDepth'] ?? 1.8;

  // Nodes: fib lattice + slow noise wander, renormalised to the surface.
  final List<List<double>> nodes = <List<double>>[];
  for (int i = 0; i < nodeN; i++) {
    final List<double> d = fibDir(i, nodeN);
    final double x = d[0] + 0.3 * (vnoise(i * 0.31 + 9, t * 0.24) - 0.5) * 2;
    final double y = d[1] + 0.3 * (vnoise(i * 0.53 + 27, t * 0.21) - 0.5) * 2;
    final double z = d[2] + 0.3 * (vnoise(i * 0.77 + 55, t * 0.27) - 0.5) * 2;
    final double l = math.sqrt(x * x + y * y + z * z);
    nodes.add(<double>[x / l, y / l, z / l]);
  }

  final List<OrbLine> lines = <OrbLine>[];
  final List<OrbDot> dots = <OrbDot>[];

  // Edges between close neighbours, alpha by proximity + depth.
  for (int i = 0; i < nodeN; i++) {
    for (int j = i + 1; j < nodeN; j++) {
      final double dx = nodes[i][0] - nodes[j][0];
      final double dy = nodes[i][1] - nodes[j][1];
      final double dz = nodes[i][2] - nodes[j][2];
      final double dist = math.sqrt(dx * dx + dy * dy + dz * dz);
      if (dist >= thr) continue;
      final List<double> p1 = pt(nodes[i][0], nodes[i][1], nodes[i][2]);
      final List<double> p2 = pt(nodes[j][0], nodes[j][1], nodes[j][2]);
      final double x1 = p1[0];
      final double y1 = p1[1];
      final double z1 = p1[2];
      final double x2 = p2[0];
      final double y2 = p2[1];
      final double z2 = p2[2];
      final double depth = ((z1 + z2) / 2 + 1) / 2;
      lines.add(
        OrbLine(
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          white: 0.42,
          a: (1 - dist / thr) * (0.3 + 0.55 * depth),
          w: math.max(0.6, (opts['lineW'] ?? 0.8) * rs),
        ),
      );
    }
  }

  for (int i = 0; i < nodeN; i++) {
    final List<double> p = pt(nodes[i][0], nodes[i][1], nodes[i][2]);
    final double px = p[0];
    final double py = p[1];
    final double z = p[2];
    final double depth = (z + 1) / 2;
    final double pulse = 1 + 0.25 * math.sin(t * 1.4 + i * 2.7);
    dots.add(
      OrbDot(
        x: px,
        y: py,
        z: z,
        r: (nodeR + nodeRDepth * depth) * pulse * rs,
        white: 0.55 - 0.45 * depth,
      ),
    );
  }

  // Signals: bright packets running between paired nodes.
  final int signals = (opts['signals'] ?? 5).round();
  for (int s = 0; s < signals; s++) {
    final double seg = (t * 0.55 + s * 7.31).floorToDouble();
    final int a = (hashD(seg, s * 3.1 + 1.7) * nodeN).floor();
    final int b = (hashD(seg, s * 5.7 + 4.2) * nodeN).floor();
    if (a == b) continue;
    final double f = frac(t * 0.55 + s * 7.31);
    final double x = lerpD(nodes[a][0], nodes[b][0], f);
    final double y = lerpD(nodes[a][1], nodes[b][1], f);
    final double z = lerpD(nodes[a][2], nodes[b][2], f);
    final double l = math.max(1e-6, math.sqrt(x * x + y * y + z * z));
    final List<double> p = pt(x / l, y / l, z / l);
    final double px = p[0];
    final double py = p[1];
    final double zr = p[2];
    final double depth = (zr + 1) / 2;
    dots.add(
      OrbDot(
        x: px,
        y: py,
        z: zr,
        r: (nodeR * 1.5 + nodeRDepth * depth) * rs,
        white: 0.05,
        a: 0.5 + 0.5 * depth,
      ),
    );
  }

  return finalizeFrame(dots, lines, opts['rMin'] ?? 0.3);
}
