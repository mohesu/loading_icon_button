import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'orb_painter.dart';
import 'orb_presets.dart';
import 'orb_registry.dart';

/// How a [ThinkingOrb] picks its ink.
enum OrbTheme {
  /// Follow the ambient [Theme] brightness. This is almost always what you want.
  auto,

  /// Light ink, for dark surfaces.
  dark,

  /// Dark ink, for light surfaces.
  light,
}

/// Default screen-reader descriptions, one per state.
const Map<OrbState, String> kOrbSemanticLabels = <OrbState, String>{
  OrbState.working: 'Working',
  OrbState.searching: 'Searching',
  OrbState.solving: 'Solving',
  OrbState.listening: 'Listening',
  OrbState.connecting: 'Connecting',
  OrbState.weaving: 'Weaving',
  OrbState.composing: 'Composing',
  OrbState.breathing: 'Thinking',
  OrbState.shaping: 'Shaping',
};

/// An animated dotted orb for AI and agent interfaces.
///
/// Nine hand-tuned states each visualise a different kind of work — see
/// [OrbState]. Every state is drawn as filled circles over a rotated,
/// z-sorted 3D point field: no shaders, no blurs and no image assets, so an
/// orb costs one [CustomPainter] and renders identically on every platform
/// Flutter supports.
///
/// ```dart
/// const ThinkingOrb(state: OrbState.searching, size: 64)
/// ```
///
/// Orbs are monochrome by default and take their ink from the ambient theme
/// brightness. Pass [color] to tint one.
///
/// Every mounted orb reads the same clock, so several on screen stay in step.
/// Animation stops automatically when the orb's route is inactive (via
/// [TickerMode]), when [paused] is set, and when the platform asks for
/// reduced motion — in which case a representative still frame is painted.
///
/// Two tunings ship per state: an inline-text design below [size] 40 and a
/// chat-avatar design at or above it. They are separate designs rather than
/// one scaled up, so a 20px orb stays legible.
///
/// {@template loading_icon_button.orb_tests}
/// An orb animates continuously, so `tester.pumpAndSettle()` will never
/// settle while one is mounted. Drive tests with `tester.pump(duration)`, or
/// mount the orb with `paused: true`.
/// {@endtemplate}
class ThinkingOrb extends StatefulWidget {
  const ThinkingOrb({
    super.key,
    this.state = OrbState.working,
    this.size = 64,
    this.theme = OrbTheme.auto,
    this.speed = 1,
    this.paused = false,
    this.color,
    this.semanticLabel,
  })  : assert(size > 0, 'size must be positive'),
        assert(speed > 0, 'speed must be positive');

  /// Which of the nine animations to show.
  final OrbState state;

  /// The orb's width and height, in logical pixels.
  ///
  /// Sizes below [kOrbTierBreakpoint] use the inline-text tuning; sizes at or
  /// above it use the chat-avatar tuning.
  final double size;

  /// Which ink to use. Defaults to [OrbTheme.auto], which follows the ambient
  /// [Theme] brightness.
  final OrbTheme theme;

  /// Multiplier on the state's own tuned speed.
  final double speed;

  /// Freezes the animation on the current frame.
  final bool paused;

  /// Optional ink tint. When null the orb is monochrome, as designed.
  final Color? color;

  /// Screen-reader description. Defaults to a per-state label from
  /// [kOrbSemanticLabels]; pass the empty string to hide the orb from
  /// accessibility tools when a nearby label already describes it.
  final String? semanticLabel;

  @override
  State<ThinkingOrb> createState() => _ThinkingOrbState();
}

class _ThinkingOrbState extends State<ThinkingOrb>
    with SingleTickerProviderStateMixin {
  /// Elapsed seconds, already multiplied by both the state's tuned speed and
  /// [ThinkingOrb.speed]. The painter listens to this directly, so ticking
  /// never rebuilds the widget tree.
  final ValueNotifier<double> _time = ValueNotifier<double>(0);

  late final Ticker _ticker;
  late ResolvedOrb _resolved;

  /// The frame timestamp the shared clock started from.
  ///
  /// Static, so every orb in the app measures from the same origin and their
  /// animations stay in step no matter when each one mounted.
  static Duration? _epoch;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _resolved = resolvePreset(widget.state, tierForSize(widget.size));
    // Join the shared clock immediately. Without this an orb mounted into a
    // running app paints one frame at t = 0 — a visible hitch, and out of step
    // with every orb already on screen — before its first tick lands.
    if (_epoch != null) {
      final double? seconds = _currentSharedSeconds();
      if (seconds != null) {
        _time.value = seconds * _resolved.speed * widget.speed;
      }
    }
    // Created through the mixin so [TickerMode] mutes it automatically when
    // the orb's route is not current.
    _ticker = createTicker(_onTick);
    _syncTicker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _syncTicker();
    }
  }

  @override
  void didUpdateWidget(ThinkingOrb old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state ||
        tierForSize(old.size) != tierForSize(widget.size)) {
      _resolved = resolvePreset(widget.state, tierForSize(widget.size));
    }
    if (old.paused != widget.paused ||
        old.state != widget.state ||
        old.speed != widget.speed) {
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  bool get _shouldAnimate => !widget.paused && !_reduceMotion;

  void _syncTicker() {
    if (_shouldAnimate) {
      if (!_ticker.isActive) _ticker.start();
      return;
    }
    if (_ticker.isActive) _ticker.stop();
    if (_reduceMotion) {
      // A representative still frame, so the orb still reads as itself.
      // This value is already in post-speed units, so it is not scaled.
      _time.value =
          kOrbStaticFrameTime[_resolved.mode] ?? kOrbDefaultStaticFrameTime;
    }
  }

  void _onTick(Duration _) {
    // Read the frame timestamp rather than this ticker's own elapsed time:
    // it is identical for every orb painted in the same frame, which is what
    // keeps independently-mounted orbs synchronised.
    _time.value = _sharedSeconds(
          SchedulerBinding.instance.currentFrameTimeStamp,
        ) *
        _resolved.speed *
        widget.speed;
  }

  /// Seconds since the shared epoch, re-anchoring if the clock moved backwards.
  ///
  /// The frame clock is not monotonic across the lifetime of a static epoch:
  /// the test binding restarts it for every test, so a second test would
  /// otherwise read a timestamp before the epoch an earlier test set and paint
  /// a negative, test-order-dependent time.
  static double _sharedSeconds(Duration now) {
    final Duration? epoch = _epoch;
    if (epoch == null || now < epoch) {
      _epoch = now;
      return 0;
    }
    return (now - epoch).inMicroseconds / Duration.microsecondsPerSecond;
  }

  /// The shared clock's current reading, or null if no frame is in flight.
  ///
  /// [SchedulerBinding.currentFrameTimeStamp] is only populated between the
  /// begin-frame and end-of-frame callbacks, which is exactly the window where
  /// [SchedulerBinding.schedulerPhase] is not idle.
  static double? _currentSharedSeconds() {
    final SchedulerBinding binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.idle) return null;
    return _sharedSeconds(binding.currentFrameTimeStamp);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = switch (widget.theme) {
      OrbTheme.dark => true,
      OrbTheme.light => false,
      OrbTheme.auto => Theme.of(context).brightness == Brightness.dark,
    };
    final String label =
        widget.semanticLabel ?? kOrbSemanticLabels[widget.state]!;

    final Widget orb = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: OrbPainter(
          resolved: _resolved,
          time: _time,
          dark: dark,
          color: widget.color,
        ),
      ),
    );

    if (label.isEmpty) return orb;
    return Semantics(
      label: label,
      image: true,
      child: orb,
    );
  }
}
