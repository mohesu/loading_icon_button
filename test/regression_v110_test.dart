// Regressions for the defects found by the 1.1.0 adversarial review.
//
// Each test here corresponds to a confirmed finding; the comment names the
// behaviour that used to be wrong, so a future refactor that reintroduces it
// fails here rather than in a user's app.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

/// Captures errors routed to [FlutterError] for the duration of [body].
Future<List<Object>> captureErrors(Future<void> Function() body) async {
  final List<Object> caught = <Object>[];
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails d) => caught.add(d.exception);
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return caught;
}

void main() {
  group('LoadingButton state machine', () {
    testWidgets(
        'a throwing onSuccess does not turn a successful run into an error',
        (WidgetTester tester) async {
      // Before the fix, onSuccess ran inside the same try that guarded
      // onPressed, so its throw drove the button to ActionState.error and
      // reported a successful request as a failure.
      final List<ActionState> states = <ActionState>[];
      Object? failure;
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      final List<Object> errors = await captureErrors(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              controller: controller,
              enableHapticFeedback: false,
              resetAfterDuration: false,
              onPressed: () async {},
              onSuccess: () => throw StateError('from onSuccess'),
              onFailure: (Object e, StackTrace s) => failure = e,
              onStateChanged: states.add,
              child: const Text('Go'),
            ),
          ),
        ));
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      });

      expect(states, <ActionState>[ActionState.loading, ActionState.success]);
      expect(controller.state, ActionState.success);
      expect(failure, isNull,
          reason: 'onFailure must not see an onSuccess bug');
      expect(errors.single, isStateError);
    });

    testWidgets('a throwing onFailure still reports the original action error',
        (WidgetTester tester) async {
      final List<Object> errors = await captureErrors(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              enableHapticFeedback: false,
              resetAfterDuration: false,
              onPressed: () async => throw StateError('from onPressed'),
              onFailure: (Object e, StackTrace s) =>
                  throw ArgumentError('from onFailure'),
              child: const Text('Go'),
            ),
          ),
        ));
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      });

      // The onFailure bug is surfaced, and it cannot swallow or overwrite the
      // action's own error by escaping into a discarded future.
      expect(errors, hasLength(1));
      expect(errors.single, isArgumentError);
    });

    testWidgets('onStateChanged does not fire for progress-only changes',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      final List<ActionState> states = <ActionState>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadingButton(
            controller: controller,
            onStateChanged: states.add,
            onPressed: () async {},
            child: const Text('Go'),
          ),
        ),
      ));

      controller.start();
      await tester.pump();
      for (int i = 1; i <= 5; i++) {
        controller.setProgress(i / 5);
        await tester.pump();
      }

      expect(states, <ActionState>[ActionState.loading]);
    });

    testWidgets('a progress tick does not push the success window back',
        (WidgetTester tester) async {
      // _scheduleReset used to re-arm on every notification, so a determinate
      // upload reporting progress after success would never reset.
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadingButton(
            controller: controller,
            successDuration: const Duration(milliseconds: 300),
            onPressed: () async {},
            child: const Text('Go'),
          ),
        ),
      ));

      controller.success();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      controller.setProgress(0.9); // would previously restart the 300ms window
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(controller.state, ActionState.idle);
    });

    testWidgets('mounting disabled does not notify during build',
        (WidgetTester tester) async {
      // initState used to write ActionState.disabled into the notifier, which
      // dispatched onStateChanged inside the build phase; a listener that
      // marked an ancestor dirty then tripped a framework assertion.
      int outerBuilds = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              outerBuilds++;
              return LoadingButton(
                enabled: false,
                onPressed: () async {},
                onStateChanged: (ActionState _) => setState(() {}),
                child: const Text('Go'),
              );
            },
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(outerBuilds, 1);
    });

    testWidgets('a cooldown that expires while disabled stays disabled',
        (WidgetTester tester) async {
      // The controller-less cooldown timer used to force ActionState.idle
      // regardless of `enabled`, leaving a button painted enabled that
      // ignored every tap.
      Widget build({required bool enabled}) => MaterialApp(
            home: Scaffold(
              body: LoadingButton(
                enabled: enabled,
                enableHapticFeedback: false,
                successDuration: const Duration(milliseconds: 50),
                cooldown: const Duration(milliseconds: 100),
                onPressed: () async {},
                child: const Text('Go'),
              ),
            ),
          );

      await tester.pumpWidget(build(enabled: true));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 60)); // success -> cooldown

      await tester.pumpWidget(build(enabled: false));
      await tester.pump(const Duration(milliseconds: 200)); // cooldown expires

      final ElevatedButton button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull,
          reason: 'still disabled by the enabled property');
      final LoadingButtonState state =
          tester.state<LoadingButtonState>(find.byType(LoadingButton));
      expect(state.currentState, ActionState.disabled,
          reason: 'the painted state must agree with interactivity');
    });
  });

  group('AutoLoadingButton', () {
    testWidgets('several taps on one failing run report the error once',
        (WidgetTester tester) async {
      // Taps arriving before the loading rebuild lands all join the same
      // pending run; _reportIfUnobserved used to attach a fresh catchError per
      // tap, so one exception reached FlutterError once per tap.
      // The callback is held open by a gate so all three taps land while the
      // SAME run is still pending — without the gate each tap would start its
      // own run and three reports would be correct.
      final Completer<void> gate = Completer<void>();
      final List<Object> errors = await captureErrors(() async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ElevatedAutoLoadingButton(
              onPressed: () async {
                await gate.future;
                throw StateError('boom');
              },
              child: const Text('Go'),
            ),
          ),
        ));
        final Finder button = find.byType(ElevatedAutoLoadingButton);
        // No pump between taps: the button has not rebuilt into its disabled
        // form yet, which is exactly the window the bug lived in.
        await tester.tap(button);
        await tester.tap(button);
        await tester.tap(button);
        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      });

      expect(errors, hasLength(1));
      expect(errors.single, isStateError);
    });
  });

  group('ThinkingOrb', () {
    testWidgets('the shared clock never reports a negative time',
        (WidgetTester tester) async {
      // The static epoch is never reset, and the test binding restarts the
      // frame clock for every test, so a stale epoch used to produce negative
      // (and test-order-dependent) orb time.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: ThinkingOrb(state: OrbState.working)),
      ));
      await tester.pump(const Duration(milliseconds: 32));

      final CustomPaint paint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(ThinkingOrb),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      final ValueListenable<double> time =
          (paint.painter! as dynamic).time as ValueListenable<double>;
      expect(time.value, greaterThanOrEqualTo(0));
    });

    testWidgets('a transparent tint paints nothing',
        (WidgetTester tester) async {
      // _ink used to discard the tint's alpha, so a transparent tint painted
      // opaque black dots.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: ThinkingOrb(
            state: OrbState.working,
            color: Color(0x00000000),
            paused: true,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);

      final CustomPaint paint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(ThinkingOrb),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      final _DotColorRecorder recorder = _DotColorRecorder();
      paint.painter!.paint(recorder, const Size(64, 64));
      expect(recorder.colors, isNotEmpty, reason: 'dots were painted at all');
      // Compared as whole colours rather than by reading the alpha channel:
      // `Color.alpha`/`opacity` are deprecated in current stable and `Color.a`
      // does not exist on the oldest SDK this package supports.
      expect(recorder.colors.toSet(), <Color>{const Color(0x00000000)});
    });
  });
}

/// A [Canvas] stand-in that records the colour of every circle painted.
class _DotColorRecorder implements Canvas {
  final List<Color> colors = <Color>[];

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      colors.add(paint.color);

  @override
  void noSuchMethod(Invocation invocation) {}
}
