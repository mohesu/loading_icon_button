// Shared primitives for the dotted 3D thinking orbs.
//
// Ported to Dart from `thinking-orbs` by Jakub Antalik (MIT), whose engine is
// itself descended from inkform's HalftoneSphere lineage. The geometry is
// honestly 3D: rotated, depth-shaded and z-sorted, with depth carried by dot
// radius and ink weight alone. Every mode paints filled circles only (plus a
// line pass for `connecting`), so there are no shaders, blurs or rasterised
// assets anywhere in this package.
//
// The functions here are deliberately closure-free and `dart:math`-only so a
// frame is reproducible from `(size, t, opts)` alone. That is what lets
// `test/orbs/orb_golden_test.dart` compare this port against the upstream
// golden vectors dot by dot.
import 'dart:math' as math;

/// A single projected dot, ready to paint.
class OrbDot {
  OrbDot({
    required this.x,
    required this.y,
    required this.z,
    required this.r,
    required this.white,
    this.a,
  });

  /// Projected position, in logical pixels from the top-left of the orb box.
  final double x;
  final double y;

  /// Projected depth. Larger is nearer the viewer; used only for sorting.
  final double z;

  /// Painted radius in logical pixels.
  double r;

  /// Ink value: 0 is the darkest ink on paper. Mirrored on dark substrates.
  final double white;

  /// Optional alpha. `null` means fully opaque.
  final double? a;
}

/// A stroked edge between two projected points (the `connecting` web).
class OrbLine {
  const OrbLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.white,
    required this.w,
    this.a,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  /// Ink value, same convention as [OrbDot.white].
  final double white;

  /// Optional alpha. `null` means fully opaque.
  final double? a;

  /// Stroke width in logical pixels.
  final double w;
}

/// One rendered instant: a complete, final set of draw instructions.
///
/// [dots] is already z-sorted into draw order and radius-clamped; [lines] are
/// drawn first so nodes sit on top of their edges. Nothing here needs further
/// interpretation, which is what makes a frame portable to any 2D renderer.
class OrbFrame {
  const OrbFrame(this.dots, this.lines);

  final List<OrbDot> dots;
  final List<OrbLine> lines;
}

/// Mode options. Values are plain doubles so a profile can be scaled
/// generically without knowing what any individual key means.
typedef OrbOpts = Map<String, double>;

/// Spin + tilt + orthographic projection, as a reusable closure.
typedef OrbProjector = List<double> Function(double x, double y, double z);

/// Builds one frame of geometry for a mode. Pure in `(size, t, opts)`.
typedef OrbModeFrame = OrbFrame Function(double size, double t, OrbOpts opts);

double lerpD(double a, double b, double f) => a + (b - a) * f;

/// Fractional part, matching JavaScript's `x - Math.floor(x)`.
double frac(double x) => x - x.floorToDouble();

/// Deterministic hash in [0, 1).
///
/// The classic sin-based GLSL hash. The multiply by 43758.5453 amplifies the
/// sine's low bits into a uniform-looking value; the inputs here are small
/// integers, so `sin` is accurate to well under one ulp and the result agrees
/// with the JavaScript original far inside the golden tolerance.
double hashD(double a, double b) {
  final double h = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return h - h.floorToDouble();
}

/// Value noise on a 2D lattice — smooth, deterministic, cheap.
double vnoise(double x, double y) {
  final double xi = x.floorToDouble();
  final double yi = y.floorToDouble();
  double fx = x - xi;
  double fy = y - yi;
  fx = fx * fx * (3 - 2 * fx);
  fy = fy * fy * (3 - 2 * fy);
  final double a = hashD(xi, yi);
  final double b = hashD(xi + 1, yi);
  final double c = hashD(xi, yi + 1);
  final double d = hashD(xi + 1, yi + 1);
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy;
}

/// Stable directions on a unit sphere (Fibonacci lattice).
List<double> fibDir(int i, int n) {
  final double golden = math.pi * (3 - math.sqrt(5));
  final double y = 1 - (2 * (i + 0.5)) / n;
  final double rad = math.sqrt(1 - y * y);
  final double a = i * golden;
  return <double>[rad * math.cos(a), y, rad * math.sin(a)];
}

/// Shortest signed angular distance, wrapped to (-pi, pi].
double angleDelta(double a, double b) =>
    math.atan2(math.sin(a - b), math.cos(a - b));

/// Shared spin + tilt + orthographic projection.
OrbProjector makeProj(
  double yaw,
  double tilt,
  double cx,
  double cy,
  double scale,
) {
  final double st = math.sin(tilt);
  final double ct = math.cos(tilt);
  final double sy = math.sin(yaw);
  final double cyw = math.cos(yaw);
  return (double x, double y, double z) {
    final double x1 = x * cyw + z * sy;
    final double z1 = -x * sy + z * cyw;
    final double y1 = y * ct - z1 * st;
    final double z2 = y * st + z1 * ct;
    return <double>[cx + x1 * scale, cy - y1 * scale, z2];
  };
}

/// Dot radii were tuned for a 300pt frame; sub-linear scaling keeps small
/// spinners legible. A lower [pow] makes radii shrink less with size.
double radiusScale(double size, double pow) =>
    math.pow(size / 300, pow).toDouble();

/// Turns raw mode output into a finished frame: drops invisible marks, clamps
/// radii to the mode's floor, and z-sorts far to near into draw order.
///
/// The sort must be STABLE. JavaScript's `Array.prototype.sort` has been
/// stable since ES2019, and the upstream engine relies on that: `shaping`
/// emits every dot at `z == 0`, so insertion order is the only thing that
/// decides draw order there. Dart's [List.sort] is introsort and is *not*
/// stable, so sorting on `z` alone would scramble that state relative to the
/// golden vectors. Comparing on the original index as a tiebreaker restores
/// the guarantee.
OrbFrame finalizeFrame(
  List<OrbDot> dots,
  List<OrbLine> lines, [
  double rMin = 0.3,
]) {
  final List<OrbDot> visible = <OrbDot>[];
  final List<int> order = <int>[];
  for (final OrbDot d in dots) {
    if ((d.a ?? 1) < 0.02) continue;
    d.r = math.max(rMin, d.r);
    order.add(visible.length);
    visible.add(d);
  }
  order.sort((int i, int j) {
    // Compare by subtraction rather than `compareTo`: the upstream comparator
    // is `a.z - b.z`, which treats -0.0 and 0.0 as equal, whereas Dart's
    // `compareTo` orders -0.0 before 0.0 and would reorder such pairs.
    final double d = visible[i].z - visible[j].z;
    if (d < 0) return -1;
    if (d > 0) return 1;
    return i.compareTo(j);
  });
  return OrbFrame(
    <OrbDot>[for (final int i in order) visible[i]],
    <OrbLine>[
      for (final OrbLine l in lines)
        if ((l.a ?? 1) >= 0.02) l,
    ],
  );
}
