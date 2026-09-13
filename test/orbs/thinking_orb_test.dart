// Widget-level behaviour of [ThinkingOrb].
//
// The geometry itself is locked down numerically by `orb_golden_test.dart`;
// nothing here re-checks dot positions. What is checked here is everything the
// widget layer owns: layout, tier selection, the clock (shared, pausable,
// TickerMode-aware, reduced-motion), ink resolution, semantics and disposal.
//
// The orb animates forever, so `pumpAndSettle` is never used: every test drives
// the clock with explicit `pump(duration)` calls.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/src/orbs/orb_painter.dart';
import 'package:loading_icon_button/src/orbs/orb_presets.dart';
import 'package:loading_icon_button/src/orbs/orb_registry.dart';
import 'package:loading_icon_button/src/orbs/thinking_orb.dart';

/// Mounts [child] under the minimum ancestors an orb needs: a [MediaQuery]
/// (for the reduced-motion query), a [Directionality] (for semantics) and a
/// [Theme] (for `OrbTheme.auto`). [Center] leaves the orb free to take its
/// intrinsic size instead of being stretched by the view constraints.
Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: ThemeData(brightness: brightness),
        child: Center(child: child),
      ),
    ),
  );
}

/// The [OrbPainter] currently driving the orb found by [of] (the only orb in
/// the tree by default).
OrbPainter _painterOf(WidgetTester tester, {Finder? of}) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find.descendant(
      of: of ?? find.byType(ThinkingOrb),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as OrbPainter;
}

/// A canvas that records the colour of every mark a painter makes, so the ink
/// mapping can be asserted on the actual draw calls.
class _InkRecorder implements Canvas {
  final List<Color> colors = <Color>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      colors.add(paint.color);

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => colors.add(paint.color);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Every colour [painter] paints one frame with, at the orb's current time.
List<Color> _inkOf(OrbPainter painter, double size) {
  final _InkRecorder recorder = _InkRecorder();
  painter.paint(recorder, Size.square(size));
  return recorder.colors;
}

void main() {
  group('layout', () {
    for (final OrbState state in OrbState.values) {
      testWidgets(
          '${state.name} lays out at exactly the requested size and '
          'paints its own mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          _host(ThinkingOrb(state: state, size: 48, paused: true)),
        );

        expect(tester.getSize(find.byType(ThinkingOrb)), const Size(48, 48));
        expect(_painterOf(tester).resolved.mode, kStateToMode[state]);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a non-default size is honoured rather than the 64 default',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb(size: 21, paused: true)));

      expect(tester.getSize(find.byType(ThinkingOrb)), const Size(21, 21));
    });
  });

  group('size tier selection', () {
    testWidgets(
        'a size just below kOrbTierBreakpoint resolves the inline '
        'tuning', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          ThinkingOrb(
            size: kOrbTierBreakpoint - 0.1,
            paused: true,
          ),
        ),
      );

      expect(
        _painterOf(tester).resolved,
        same(resolvePreset(OrbState.working, OrbSizeTier.inline)),
      );
    });

    testWidgets(
        'a size exactly at kOrbTierBreakpoint resolves the avatar '
        'tuning', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(ThinkingOrb(size: kOrbTierBreakpoint, paused: true)),
      );

      expect(
        _painterOf(tester).resolved,
        same(resolvePreset(OrbState.working, OrbSizeTier.avatar)),
      );
    });

    testWidgets('the two tiers are genuinely different tunings, not one scaled',
        (WidgetTester tester) async {
      final ResolvedOrb inline =
          resolvePreset(OrbState.working, OrbSizeTier.inline);
      final ResolvedOrb avatar =
          resolvePreset(OrbState.working, OrbSizeTier.avatar);

      expect(inline.speed, isNot(avatar.speed));
      expect(inline.opts, isNot(equals(avatar.opts)));
    });
  });

  group('clock', () {
    testWidgets('an unpaused orb advances its painted frame time every frame',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb()));
      final OrbPainter painter = _painterOf(tester);

      await tester.pump(const Duration(milliseconds: 16));
      final double first = painter.time.value;
      await tester.pump(const Duration(milliseconds: 500));
      final double second = painter.time.value;

      expect(second, greaterThan(first));
      // The clock is scaled by the state's own tuned speed.
      expect(
        second - first,
        closeTo(0.5 * painter.resolved.speed, 1e-6),
      );
    });

    testWidgets('paused: true from mount never advances the painted frame time',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb(paused: true)));
      final OrbPainter painter = _painterOf(tester);
      final double mounted = painter.time.value;

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(painter.time.value, mounted);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('pausing a running orb freezes it on the frame it had reached',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb()));
      final OrbPainter painter = _painterOf(tester);
      await tester.pump(const Duration(milliseconds: 400));
      final double frozen = painter.time.value;
      expect(frozen, greaterThan(0));

      await tester.pumpWidget(_host(const ThinkingOrb(paused: true)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(_painterOf(tester).time.value, frozen);
    });

    testWidgets('un-pausing resumes the animation',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb(paused: true)));
      final double frozen = _painterOf(tester).time.value;

      await tester.pumpWidget(_host(const ThinkingOrb()));
      await tester.pump(const Duration(milliseconds: 400));

      expect(_painterOf(tester).time.value, greaterThan(frozen));
    });

    testWidgets(
        'two orbs mounted at different times report the same frame '
        'time (one shared clock)', (WidgetTester tester) async {
      const Key first = Key('first');
      const Key second = Key('second');

      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[ThinkingOrb(key: first)],
          ),
        ),
      );
      // Let the first orb run well past the second one's mount point.
      await tester.pump(const Duration(milliseconds: 750));

      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ThinkingOrb(key: first),
              ThinkingOrb(key: second)
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final double a = _painterOf(tester, of: find.byKey(first)).time.value;
      final double b = _painterOf(tester, of: find.byKey(second)).time.value;

      expect(b, greaterThan(0));
      expect(a, b);
    });

    testWidgets('speed multiplies the state tuning rather than replacing it',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb(speed: 2)));
      final OrbPainter painter = _painterOf(tester);

      await tester.pump(const Duration(milliseconds: 16));
      final double first = painter.time.value;
      await tester.pump(const Duration(seconds: 1));

      expect(
        painter.time.value - first,
        closeTo(painter.resolved.speed * 2, 1e-6),
      );
    });
  });

  group('reduced motion', () {
    testWidgets(
        'paints the documented default static frame time and starts no '
        'ticker', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const ThinkingOrb(state: OrbState.working),
          disableAnimations: true,
        ),
      );

      final OrbPainter painter = _painterOf(tester);
      expect(painter.resolved.mode, OrbMode.orbits);
      expect(painter.time.value, kOrbDefaultStaticFrameTime);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(painter.time.value, kOrbDefaultStaticFrameTime);
    });

    testWidgets(
        'a mode with a tuned still frame uses it instead of the '
        'default', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const ThinkingOrb(state: OrbState.shaping),
          disableAnimations: true,
        ),
      );

      final OrbPainter painter = _painterOf(tester);
      expect(painter.resolved.mode, OrbMode.morph);
      expect(painter.time.value, kOrbStaticFrameTime[OrbMode.morph]);
      expect(painter.time.value, isNot(kOrbDefaultStaticFrameTime));
    });

    testWidgets(
        'turning reduced motion on mid-flight stops the clock and '
        'snaps to the still frame', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb()));
      final OrbPainter painter = _painterOf(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(painter.time.value, isNot(kOrbDefaultStaticFrameTime));

      await tester.pumpWidget(
        _host(const ThinkingOrb(), disableAnimations: true),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(painter.time.value, kOrbDefaultStaticFrameTime);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('TickerMode', () {
    testWidgets('TickerMode(enabled: false) stops the animation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const TickerMode(enabled: false, child: ThinkingOrb())),
      );
      final OrbPainter painter = _painterOf(tester);
      final double muted = painter.time.value;

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(painter.time.value, muted);
    });

    testWidgets('re-enabling TickerMode resumes the animation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const TickerMode(enabled: false, child: ThinkingOrb())),
      );
      await tester.pump(const Duration(seconds: 1));
      final double muted = _painterOf(tester).time.value;

      await tester.pumpWidget(
        _host(const TickerMode(enabled: true, child: ThinkingOrb())),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(_painterOf(tester).time.value, greaterThan(muted));
    });
  });

  group('ink', () {
    testWidgets('OrbTheme.auto paints dark ink under a light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const ThinkingOrb(paused: true)),
      );

      expect(_painterOf(tester).dark, isFalse);
    });

    testWidgets('OrbTheme.auto follows the ambient theme into dark mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const ThinkingOrb(paused: true), brightness: Brightness.dark),
      );

      expect(_painterOf(tester).dark, isTrue);
    });

    testWidgets('OrbTheme.dark pins light ink under a light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const ThinkingOrb(theme: OrbTheme.dark, paused: true)),
      );

      expect(_painterOf(tester).dark, isTrue);
    });

    testWidgets('OrbTheme.light pins dark ink under a dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const ThinkingOrb(theme: OrbTheme.light, paused: true),
          brightness: Brightness.dark,
        ),
      );

      expect(_painterOf(tester).dark, isFalse);
    });

    testWidgets('an untinted orb paints grey ink, opaque, on both substrates',
        (WidgetTester tester) async {
      for (final Brightness brightness in Brightness.values) {
        await tester.pumpWidget(
          _host(
            const ThinkingOrb(state: OrbState.connecting, size: 64),
            brightness: brightness,
          ),
        );
        await tester.pump(const Duration(milliseconds: 120));

        final OrbPainter painter = _painterOf(tester);
        expect(painter.color, isNull);

        final List<Color> ink = _inkOf(painter, 64);
        expect(ink, isNotEmpty, reason: 'the orb painted nothing');
        for (final Color c in ink) {
          expect(c.r, c.g, reason: 'ink is not grey under $brightness');
          expect(c.g, c.b, reason: 'ink is not grey under $brightness');
        }
      }
    });

    testWidgets('the monochrome ramp is mirrored on a dark substrate',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const ThinkingOrb(state: OrbState.connecting, paused: true)),
      );
      final List<Color> light = _inkOf(_painterOf(tester), 64);

      await tester.pumpWidget(
        _host(
          const ThinkingOrb(state: OrbState.connecting, paused: true),
          brightness: Brightness.dark,
        ),
      );
      final List<Color> dark = _inkOf(_painterOf(tester), 64);

      expect(dark.length, light.length);
      expect(dark, isNot(equals(light)));
      for (int i = 0; i < dark.length; i++) {
        expect(dark[i].r, closeTo(1 - light[i].r, 2 / 255));
        expect(dark[i].a, light[i].a);
      }
    });

    testWidgets(
        'color switches the painter to the tinted path: one hue, '
        'depth carried by alpha', (WidgetTester tester) async {
      const Color tint = Color(0xFFFF0000);
      await tester.pumpWidget(
        _host(
          const ThinkingOrb(
            state: OrbState.connecting,
            size: 64,
            color: tint,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));

      final OrbPainter painter = _painterOf(tester);
      expect(painter.color, tint);

      final List<Color> ink = _inkOf(painter, 64);
      expect(ink, isNotEmpty, reason: 'the orb painted nothing');
      for (final Color c in ink) {
        expect(c.r, tint.r);
        expect(c.g, tint.g);
        expect(c.b, tint.b);
      }
      // Depth has to go somewhere: with the hue pinned it rides on alpha.
      expect(ink.any((Color c) => c.a > 0), isTrue);
      expect(ink.any((Color c) => c.a < 1), isTrue);
    });
  });

  group('semantics', () {
    testWidgets('every state exposes its default label from kOrbSemanticLabels',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      for (final OrbState state in OrbState.values) {
        await tester.pumpWidget(
          _host(ThinkingOrb(state: state, paused: true)),
        );

        expect(
          find.bySemanticsLabel(kOrbSemanticLabels[state]!),
          findsOneWidget,
          reason: 'no default label for ${state.name}',
        );
      }
      handle.dispose();
    });

    testWidgets('the orb is exposed as an image node, not a plain label',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(_host(const ThinkingOrb(paused: true)));

      expect(
        tester.getSemantics(
          find.descendant(
            of: find.byType(ThinkingOrb),
            matching: find.byType(Semantics),
          ),
        ),
        matchesSemantics(
          label: kOrbSemanticLabels[OrbState.working],
          isImage: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('an explicit semanticLabel replaces the per-state default',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(
          const ThinkingOrb(
            state: OrbState.searching,
            semanticLabel: 'Looking for files',
            paused: true,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Looking for files'), findsOneWidget);
      expect(
        find.bySemanticsLabel(kOrbSemanticLabels[OrbState.searching]!),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('an empty semanticLabel removes the Semantics node entirely',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(const ThinkingOrb(semanticLabel: '', paused: true)),
      );

      expect(
        find.descendant(
          of: find.byType(ThinkingOrb),
          matching: find.byType(Semantics),
        ),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(kOrbSemanticLabels[OrbState.working]!),
        findsNothing,
      );
      handle.dispose();
    });
  });

  group('updates in place', () {
    testWidgets(
        'changing state re-resolves the preset without recreating the '
        'State', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const ThinkingOrb(size: 64, paused: true)),
      );
      final State<ThinkingOrb> state =
          tester.state<State<ThinkingOrb>>(find.byType(ThinkingOrb));
      expect(
        _painterOf(tester).resolved,
        same(resolvePreset(OrbState.working, OrbSizeTier.avatar)),
      );

      await tester.pumpWidget(
        _host(
          const ThinkingOrb(
            state: OrbState.weaving,
            size: 64,
            paused: true,
          ),
        ),
      );

      expect(
        _painterOf(tester).resolved,
        same(resolvePreset(OrbState.weaving, OrbSizeTier.avatar)),
      );
      expect(
        tester.state<State<ThinkingOrb>>(find.byType(ThinkingOrb)),
        same(state),
      );
    });

    testWidgets(
        'growing past the breakpoint swaps the tuning without '
        'recreating the State', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const ThinkingOrb(size: 20, paused: true)),
      );
      final State<ThinkingOrb> state =
          tester.state<State<ThinkingOrb>>(find.byType(ThinkingOrb));
      expect(
        _painterOf(tester).resolved,
        same(resolvePreset(OrbState.working, OrbSizeTier.inline)),
      );

      await tester.pumpWidget(
        _host(const ThinkingOrb(size: 64, paused: true)),
      );

      expect(tester.getSize(find.byType(ThinkingOrb)), const Size(64, 64));
      expect(
        _painterOf(tester).resolved,
        same(resolvePreset(OrbState.working, OrbSizeTier.avatar)),
      );
      expect(
        tester.state<State<ThinkingOrb>>(find.byType(ThinkingOrb)),
        same(state),
      );
    });

    testWidgets('resizing within one tier keeps the same tuning',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const ThinkingOrb(size: 48, paused: true)),
      );
      final ResolvedOrb before = _painterOf(tester).resolved;

      await tester.pumpWidget(
        _host(const ThinkingOrb(size: 96, paused: true)),
      );

      expect(tester.getSize(find.byType(ThinkingOrb)), const Size(96, 96));
      expect(_painterOf(tester).resolved, same(before));
    });

    testWidgets(
        'changing speed changes the clock rate without recreating the '
        'State', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb()));
      final State<ThinkingOrb> state =
          tester.state<State<ThinkingOrb>>(find.byType(ThinkingOrb));
      final OrbPainter painter = _painterOf(tester);

      await tester.pump(const Duration(milliseconds: 16));
      final double a = painter.time.value;
      await tester.pump(const Duration(seconds: 1));
      final double slowStep = painter.time.value - a;

      await tester.pumpWidget(_host(const ThinkingOrb(speed: 3)));
      await tester.pump(const Duration(milliseconds: 16));
      final double b = _painterOf(tester).time.value;
      await tester.pump(const Duration(seconds: 1));
      final double fastStep = _painterOf(tester).time.value - b;

      expect(fastStep, closeTo(slowStep * 3, 1e-6));
      expect(
        tester.state<State<ThinkingOrb>>(find.byType(ThinkingOrb)),
        same(state),
      );
    });
  });

  group('disposal', () {
    testWidgets(
        'unmounting mid-animation disposes the ticker and leaves no '
        'pending frame callbacks', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ThinkingOrb()));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(_host(const SizedBox.shrink()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ThinkingOrb), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a reduced-motion orb unmounts without touching its disposed '
        'clock', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const ThinkingOrb(), disableAnimations: true),
      );
      await tester.pumpWidget(_host(const SizedBox.shrink()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
