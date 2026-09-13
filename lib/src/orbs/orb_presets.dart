// The shipped tunings: nine states x two sizes.
//
// `count` and `size` are multipliers over the base fine profiles; `speed`
// multiplies the shared clock. A pair is resolved once and cached, so the
// render loop only ever sees plain numbers.
import 'orb_core.dart';
import 'orb_profiles.dart';

/// The nine shipped thinking-orb animations.
///
/// Each is a hand-tuned design rather than a variation on one loop, and each
/// ships separate tunings for its two sizes.
enum OrbState {
  /// Particles run on tilted orbits.
  working,

  /// A scan meridian sweeps a dotted globe.
  searching,

  /// Bands scramble in quarter turns, then click back solved.
  solving,

  /// A waveform rolls through the latitude rings.
  listening,

  /// A constellation wires itself, packets running the edges.
  connecting,

  /// Three strands plait around the sphere.
  weaving,

  /// An undulating multi-band sash.
  composing,

  /// A face-on ring slowly morphing.
  breathing,

  /// A dotted outline morphs circle to triangle to square.
  shaping,
}

/// The geometry engine behind each [OrbState]. Two states share `ribbon`.
enum OrbMode { orbits, globe, rubik, wave, web, braid, ribbon, ring, morph }

/// Maps a public state onto the engine mode that draws it.
const Map<OrbState, OrbMode> kStateToMode = <OrbState, OrbMode>{
  OrbState.working: OrbMode.orbits,
  OrbState.searching: OrbMode.globe,
  OrbState.solving: OrbMode.rubik,
  OrbState.listening: OrbMode.wave,
  OrbState.connecting: OrbMode.web,
  OrbState.weaving: OrbMode.braid,
  OrbState.composing: OrbMode.ribbon,
  OrbState.breathing: OrbMode.ring,
  OrbState.shaping: OrbMode.morph,
};

/// One baked tuning row.
class OrbPreset {
  const OrbPreset({
    required this.speed,
    required this.count,
    required this.size,
    this.extra = const <String, double>{},
  });

  /// Multiplier on the shared clock.
  final double speed;

  /// Multiplier on every dot-count knob.
  final double count;

  /// Multiplier on every dot-radius knob.
  final double size;

  /// Extra mode options merged verbatim after scaling.
  final OrbOpts extra;
}

/// The two tuned size tiers. These are separate designs, not a scale factor:
/// each carries its own dot count, dot size and speed.
enum OrbSizeTier {
  /// Inline-text scale, tuned at 20 logical pixels.
  inline,

  /// Chat-avatar scale, tuned at 64 logical pixels.
  avatar,
}

/// The threshold at which [OrbSizeTier.avatar] tunings take over.
const double kOrbTierBreakpoint = 40;

/// Picks the tuned tier for a rendered [size].
OrbSizeTier tierForSize(double size) =>
    size < kOrbTierBreakpoint ? OrbSizeTier.inline : OrbSizeTier.avatar;

const Map<OrbMode, Map<OrbSizeTier, OrbPreset>> _presets =
    <OrbMode, Map<OrbSizeTier, OrbPreset>>{
  OrbMode.orbits: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(speed: 1.885, count: 1, size: 1),
    OrbSizeTier.inline: OrbPreset(speed: 3.9, count: 0.238, size: 2.4),
  },
  OrbMode.globe: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(
      speed: 2.015,
      count: 0.42,
      size: 1.15,
      extra: <String, double>{'scanMul': 4.08, 'dimBase': 0.45},
    ),
    OrbSizeTier.inline: OrbPreset(
      speed: 2.665,
      count: 0.105,
      size: 1.75,
      extra: <String, double>{'scanMul': 4.335, 'dimBase': 0.45},
    ),
  },
  OrbMode.rubik: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(speed: 1.82, count: 0.35, size: 1.05),
    OrbSizeTier.inline: OrbPreset(speed: 1.95, count: 0.088, size: 1.9),
  },
  OrbMode.wave: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(speed: 4.388, count: 0.341, size: 1),
    OrbSizeTier.inline: OrbPreset(speed: 3.998, count: 0.105, size: 1.6),
  },
  OrbMode.web: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(speed: 3.315, count: 1.35, size: 0.95),
    OrbSizeTier.inline: OrbPreset(speed: 6.63, count: 0.25, size: 1.52),
  },
  OrbMode.braid: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(speed: 1.625, count: 0.5, size: 1),
    OrbSizeTier.inline: OrbPreset(speed: 2.75, count: 0.1125, size: 1.36),
  },
  OrbMode.ribbon: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(
      speed: 2.34,
      count: 0.25,
      size: 0.85,
      extra: <String, double>{'spin': 0, 'bandMul': 3.9, 'wobMul': 1},
    ),
    OrbSizeTier.inline: OrbPreset(
      speed: 3.12,
      count: 0.051,
      size: 1.073,
      extra: <String, double>{'spin': 0, 'bandMul': 4.94, 'wobMul': 1},
    ),
  },
  OrbMode.ring: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(
      speed: 3.24,
      count: 0.25,
      size: 0.956,
      extra: <String, double>{'spin': 0, 'bandMul': 3.627, 'wobMul': 0.368},
    ),
    OrbSizeTier.inline: OrbPreset(
      speed: 3.78,
      count: 0.028,
      size: 1.622,
      extra: <String, double>{'spin': 0, 'bandMul': 3.968, 'wobMul': 0.565},
    ),
  },
  OrbMode.morph: <OrbSizeTier, OrbPreset>{
    OrbSizeTier.avatar: OrbPreset(
      speed: 2.405,
      count: 0.702,
      size: 0.395,
      extra: <String, double>{'spread': 1.45},
    ),
    OrbSizeTier.inline: OrbPreset(
      speed: 2.08,
      count: 0.53,
      size: 1.011,
      extra: <String, double>{'spread': 1.45},
    ),
  },
};

/// A state resolved to its mode, clock speed and fully-scaled draw options.
class ResolvedOrb {
  const ResolvedOrb({
    required this.mode,
    required this.speed,
    required this.opts,
  });

  final OrbMode mode;
  final double speed;
  final OrbOpts opts;
}

final Map<String, ResolvedOrb> _cache = <String, ResolvedOrb>{};

/// Resolves a ([state], [tier]) pair to its mode and fully-scaled options.
///
/// Results are cached: resolution is pure, and every mounted orb of the same
/// state and tier shares one [ResolvedOrb].
ResolvedOrb resolvePreset(OrbState state, OrbSizeTier tier) {
  final String key = '${state.name}-${tier.name}';
  final ResolvedOrb? hit = _cache[key];
  if (hit != null) return hit;

  final OrbMode mode = kStateToMode[state]!;
  final OrbPreset preset = _presets[mode]![tier]!;
  OrbOpts opts = OrbOpts.of(kBaseProfiles[mode.name]!);
  if (preset.count != 1) opts = scaleCounts(opts, preset.count);
  if (preset.size != 1) opts = scaleRadii(opts, preset.size);
  if (preset.extra.isNotEmpty) opts.addAll(preset.extra);

  final ResolvedOrb resolved =
      ResolvedOrb(mode: mode, speed: preset.speed, opts: opts);
  _cache[key] = resolved;
  return resolved;
}
