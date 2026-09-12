// Density profiles plus the multiplier machinery that scales them.
//
// The base rows are the upstream `fine` profiles; each shipped preset
// (state x size) applies count and radius multipliers on top, resolved once
// per (state, size) pair rather than per frame.
import 'dart:math' as math;

import 'orb_core.dart';

/// 2-D lattices (rings x dots-per-ring) come in pairs — each side takes the
/// square root of the scale so the TOTAL dot count scales by `scale`. Flat
/// lists scale linearly instead.
const List<List<String>> _countPairs = <List<String>>[
  <String>['latRings', 'lonDensity'],
  <String>['rings', 'lonDensity'],
  <String>['lanes', 'segs'],
];

const List<String> _countKeys = <String>[
  'orbitN',
  'ghostN',
  'nodeN',
  'strandN',
  'signals',
];

/// Sets the morph outline's sampling density.
const List<String> _iconDensityKeys = <String>['iconD'];

/// Every key that sets a dot's rendered radius. Scaling all of them together
/// keeps a dot's near/far falloff intact while shrinking or growing the mark.
const List<String> _radiusKeys = <String>[
  'rBase',
  'rDepth',
  'rActive',
  'rDot',
  'ghostR',
  'partR',
  'partRDepth',
  'nodeR',
  'nodeRDepth',
];

/// Scales every dot-count knob in [opts] by [scale].
OrbOpts scaleCounts(OrbOpts opts, double scale) {
  final OrbOpts out = OrbOpts.of(opts);
  final Set<String> done = <String>{};
  final double rt = math.sqrt(scale);
  for (final List<String> pair in _countPairs) {
    final String a = pair[0];
    final String b = pair[1];
    final double? va = out[a];
    final double? vb = out[b];
    if (va != null && vb != null && !done.contains(a) && !done.contains(b)) {
      out[a] = math.max(2, (va * rt).round()).toDouble();
      out[b] = math.max(2, (vb * rt).round()).toDouble();
      done.add(a);
      done.add(b);
    }
  }
  for (final String k in _countKeys) {
    final double? v = out[k];
    // 0 means the mode opted out of that layer entirely (`ring` has no ghost
    // sphere); scaling must not resurrect it as a single stray dot.
    if (v != null && v != 0 && !done.contains(k)) {
      out[k] = math.max(1, (v * scale).round()).toDouble();
    }
  }
  for (final String k in _iconDensityKeys) {
    final double? v = out[k];
    if (v != null) out[k] = math.max(0.02, v * scale);
  }
  return out;
}

/// Scales every dot-radius knob in [opts] by [scale].
OrbOpts scaleRadii(OrbOpts opts, double scale) {
  final OrbOpts out = OrbOpts.of(opts);
  for (final String k in _radiusKeys) {
    final double? v = out[k];
    if (v != null) out[k] = v * scale;
  }
  // Remember the multiplier itself: spacing-derived radii (the morph outline)
  // use it, since they are not based on any single radius key.
  out['rSizeMul'] = (out['rSizeMul'] ?? 1) * scale;
  return out;
}

/// Base (fine) profiles per mode, before preset multipliers.
const Map<String, OrbOpts> kBaseProfiles = <String, OrbOpts>{
  'globe': <String, double>{
    'latRings': 17,
    'lonDensity': 44,
    'rBase': 0.6,
    'rDepth': 1.7,
    'rBoost': 1.0,
    'inkFar': 0.62,
    'inkSpan': 0.54,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'orbits': <String, double>{
    'orbitN': 12,
    'ghostN': 40,
    'ghostR': 0.9,
    'ghostA': 0.5,
    'particles': 3,
    'partR': 1.2,
    'partRDepth': 1.6,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'rubik': <String, double>{
    'latRings': 15,
    'lonDensity': 40,
    'moveCount': 14,
    'rBase': 0.6,
    'rDepth': 1.7,
    'rActive': 0.3,
    'inkFar': 0.62,
    'inkSpan': 0.54,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'wave': <String, double>{
    'rings': 15,
    'lonDensity': 40,
    'rBase': 0.6,
    'rDepth': 1.7,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'web': <String, double>{
    'nodeN': 30,
    'thr': 0.72,
    'signals': 5,
    'nodeR': 1.4,
    'nodeRDepth': 1.8,
    'lineW': 0.8,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'braid': <String, double>{
    'strandN': 52,
    'turns': 3.0,
    'ghostN': 150,
    'rBase': 1.2,
    'rDepth': 1.8,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'ribbon': <String, double>{
    'lanes': 5,
    'segs': 88,
    'ghostN': 150,
    'rBase': 1.1,
    'rDepth': 1.7,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  // `ring` shares ribbon's painter; `faceOn` cancels the camera tilt and moves
  // the undulation onto the radius, and there is no ghost sphere behind it.
  'ring': <String, double>{
    'lanes': 5,
    'segs': 88,
    'ghostN': 0,
    'faceOn': 1,
    'rBase': 1.1,
    'rDepth': 1.7,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'morph': <String, double>{
    'rDot': 0.021,
    'iconD': 1,
    'rMin': 0.25,
  },
};
