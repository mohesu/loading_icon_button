// Numeric parity against the upstream `thinking-orbs` engine.
//
// The orb geometry is deterministic in (size, t, opts), so this port can be
// checked against the reference implementation dot by dot rather than by
// eyeballing pixels. See `test/fixtures/README.md` for the fixture's
// provenance.
//
// Dots are compared in a CANONICAL order rather than raw draw order. For
// face-on modes the projected depth cancels algebraically — `breathing` emits
// 44 dots whose z is zero in exact arithmetic and +/-1e-17 in floating point —
// so raw draw order among those dots is decided by rounding noise, and Dart's
// `sin`/`cos` differ from V8's in the last ulp. Sorting both sides by
// (z rounded to the fixture's own 6-decimal precision, then x, then y) removes
// that ambiguity without weakening anything: every dot is still compared on
// every field, and draw order proper is asserted separately by checking that
// z is non-decreasing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/src/orbs/orb_core.dart';
import 'package:loading_icon_button/src/orbs/orb_presets.dart';
import 'package:loading_icon_button/src/orbs/orb_registry.dart';

void main() {
  final Map<String, dynamic> golden = jsonDecode(
    File('test/fixtures/orbs-golden.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final double tol = (golden['tolerance'] as num).toDouble();
  final Map<String, dynamic> resolved =
      golden['resolved'] as Map<String, dynamic>;
  final List<dynamic> cases = golden['cases'] as List<dynamic>;

  OrbState stateNamed(String n) =>
      OrbState.values.firstWhere((OrbState s) => s.name == n);

  OrbSizeTier tierForGoldenSize(int size) =>
      size == 20 ? OrbSizeTier.inline : OrbSizeTier.avatar;

  group('preset resolution matches upstream', () {
    for (final MapEntry<String, dynamic> e in resolved.entries) {
      test(e.key, () {
        final List<String> parts = e.key.split('-');
        final ResolvedOrb r = resolvePreset(
          stateNamed(parts[0]),
          tierForGoldenSize(int.parse(parts[1])),
        );
        final Map<String, dynamic> want = e.value as Map<String, dynamic>;

        expect(r.mode.name, want['mode'], reason: 'mode for ${e.key}');
        expect(r.speed, closeTo((want['speed'] as num).toDouble(), tol),
            reason: 'speed for ${e.key}');

        final Map<String, dynamic> wantOpts =
            want['opts'] as Map<String, dynamic>;
        expect(r.opts.keys.toSet(), wantOpts.keys.toSet(),
            reason: 'option keys for ${e.key}');
        for (final MapEntry<String, dynamic> o in wantOpts.entries) {
          expect(r.opts[o.key], closeTo((o.value as num).toDouble(), tol),
              reason: 'opt ${o.key} for ${e.key}');
        }
      });
    }
  });

  group('frame geometry matches upstream', () {
    for (final dynamic raw in cases) {
      final Map<String, dynamic> c = raw as Map<String, dynamic>;
      test(c['key'] as String, () {
        final int size = c['size'] as int;
        final ResolvedOrb r = resolvePreset(
          stateNamed(c['state'] as String),
          tierForGoldenSize(size),
        );
        final OrbFrame frame = kOrbModeFrames[r.mode]!(
          size.toDouble(),
          (c['t'] as num).toDouble(),
          r.opts,
        );

        expect(frame.dots.length, c['dotCount'], reason: 'dot count');
        expect(frame.lines.length, c['lineCount'], reason: 'line count');

        // finalizeFrame must emit far-to-near.
        for (int i = 1; i < frame.dots.length; i++) {
          expect(frame.dots[i].z, greaterThanOrEqualTo(frame.dots[i - 1].z),
              reason: 'dots must be z-sorted at index $i');
        }

        // Dot stride 6: x, y, z, r, white, a.
        final List<num> wantDots = (c['dots'] as List<dynamic>).cast<num>();
        final List<List<double>> got = <List<double>>[
          for (final OrbDot d in frame.dots)
            <double>[d.x, d.y, d.z, d.r, d.white, d.a ?? 1],
        ];
        final List<List<double>> want = <List<double>>[
          for (int i = 0; i < frame.dots.length; i++)
            <double>[
              for (int f = 0; f < 6; f++) wantDots[i * 6 + f].toDouble()
            ],
        ];
        _canonicalise(got, 2);
        _canonicalise(want, 2);

        const List<String> names = <String>['x', 'y', 'z', 'r', 'white', 'a'];
        for (int i = 0; i < got.length; i++) {
          for (int f = 0; f < 6; f++) {
            expect(
              got[i][f],
              closeTo(want[i][f], tol),
              reason: 'dot $i ${names[f]}',
            );
          }
        }

        // Line stride 7: x1, y1, x2, y2, white, a, w. Lines are emitted in a
        // deterministic i<j node order, never sorted, so draw order is exact.
        final List<num> wantLines = (c['lines'] as List<dynamic>).cast<num>();
        const List<String> lineNames = <String>[
          'x1',
          'y1',
          'x2',
          'y2',
          'white',
          'a',
          'w',
        ];
        for (int i = 0; i < frame.lines.length; i++) {
          final OrbLine l = frame.lines[i];
          final int b = i * 7;
          final List<double> gotLine = <double>[
            l.x1,
            l.y1,
            l.x2,
            l.y2,
            l.white,
            l.a ?? 1,
            l.w,
          ];
          for (int f = 0; f < 7; f++) {
            expect(
              gotLine[f],
              closeTo(wantLines[b + f].toDouble(), tol),
              reason: 'line $i ${lineNames[f]}',
            );
          }
        }
      });
    }
  });
}

/// Sorts dot rows into an order that does not depend on rounding noise.
///
/// [zIndex] names the depth column. Depth is compared at the fixture's own
/// 6-decimal precision so that dots which are coincident in depth fall back to
/// a stable x-then-y ordering, rather than to whichever way the last ulp fell.
void _canonicalise(List<List<double>> rows, int zIndex) {
  // `compareTo` orders -0.0 before 0.0, and quantising noise of either sign
  // lands on both, so collapse signed zero before comparing.
  double q(double v) {
    final double r = (v * 1e6).roundToDouble();
    return r == 0 ? 0.0 : r;
  }

  rows.sort((List<double> a, List<double> b) {
    int c = q(a[zIndex]).compareTo(q(b[zIndex]));
    if (c != 0) return c;
    c = q(a[0]).compareTo(q(b[0]));
    if (c != 0) return c;
    return q(a[1]).compareTo(q(b[1]));
  });
}
