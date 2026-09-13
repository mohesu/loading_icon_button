import 'dart:async';

import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

/// Counts how many times a [ChangeNotifier] fires, so a test can assert that a
/// command notifies *exactly* once rather than merely at least once.
class _Counter {
  int value = 0;
  void call() => value++;
}

/// Pumps a [LoadingButton] wired to [controller].
///
/// [resetAfterDuration] is off by default: a button that resets itself leaves a
/// pending [Timer] behind, which fails the test.
Future<void> _pumpButton(
  WidgetTester tester, {
  LoadingButtonController? controller,
  AsyncCallback? onPressed,
  bool resetAfterDuration = false,
  bool enabled = true,
  Duration? debounce,
  Widget child = const Text('Go'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: LoadingButton(
            controller: controller,
            onPressed: onPressed,
            enabled: enabled,
            debounce: debounce,
            resetAfterDuration: resetAfterDuration,
            enableHapticFeedback: false,
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Long enough for the button's [AnimatedSwitcher] to swap children.
const Duration _switcher = Duration(milliseconds: 400);

/// Runs the button's [AnimatedSwitcher] transition to completion.
///
/// Three frames, and all three are needed: the first builds the new child and
/// starts the cross-fade, the second runs it out, and the third rebuilds
/// without the outgoing child, which is only dropped once its animation has
/// reported completion.
Future<void> _swap(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_switcher);
  await tester.pump();
}

void main() {
  group('LoadingButtonValue', () {
    test('the default value is idle, indeterminate and error-free', () {
      const LoadingButtonValue value = LoadingButtonValue.idle;
      expect(value.state, ActionState.idle);
      expect(value.progress, isNull);
      expect(value.error, isNull);
      expect(value.stackTrace, isNull);
      expect(value.isLoading, isFalse);
      expect(value.isDeterminate, isFalse);
    });

    test('isLoading and isDeterminate follow state and progress', () {
      const LoadingButtonValue value = LoadingButtonValue(
        state: ActionState.loading,
        progress: 0.25,
      );
      expect(value.isLoading, isTrue);
      expect(value.isDeterminate, isTrue);
    });

    test('constructing with progress outside 0.0..1.0 trips an assert', () {
      expect(
        () => LoadingButtonValue(state: ActionState.loading, progress: 1.5),
        throwsAssertionError,
      );
      expect(
        () => LoadingButtonValue(state: ActionState.loading, progress: -0.1),
        throwsAssertionError,
      );
      // The bounds themselves are legal.
      expect(const LoadingButtonValue(progress: 0).progress, 0.0);
      expect(const LoadingButtonValue(progress: 1).progress, 1.0);
    });

    test('values with identical fields are equal and share a hashCode', () {
      final StackTrace stack = StackTrace.current;
      final Object error = Exception('boom');
      final LoadingButtonValue a = LoadingButtonValue(
        state: ActionState.error,
        progress: 0.5,
        error: error,
        stackTrace: stack,
      );
      final LoadingButtonValue b = LoadingButtonValue(
        state: ActionState.error,
        progress: 0.5,
        error: error,
        stackTrace: stack,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('a difference in any single field breaks equality', () {
      const LoadingButtonValue base = LoadingButtonValue(
        state: ActionState.loading,
        progress: 0.5,
      );
      expect(base, isNot(equals(base.copyWith(state: ActionState.success))));
      expect(base, isNot(equals(base.copyWith(progress: 0.6))));
      expect(base, isNot(equals(base.copyWith(error: 'nope'))));
      expect(
        base,
        isNot(equals(base.copyWith(stackTrace: StackTrace.current))),
      );
    });

    test('copyWith carries unspecified fields through unchanged', () {
      final StackTrace stack = StackTrace.current;
      final LoadingButtonValue base = LoadingButtonValue(
        state: ActionState.error,
        progress: 0.4,
        error: 'bad',
        stackTrace: stack,
      );
      final LoadingButtonValue copy = base.copyWith(state: ActionState.loading);
      expect(copy.state, ActionState.loading);
      expect(copy.progress, 0.4);
      expect(copy.error, 'bad');
      expect(copy.stackTrace, same(stack));
    });

    test('copyWith(progress: null) alone does NOT clear progress', () {
      const LoadingButtonValue base = LoadingButtonValue(
        state: ActionState.loading,
        progress: 0.4,
      );
      expect(base.copyWith(progress: null).progress, 0.4);
    });

    test('copyWith(clearProgress: true) clears progress', () {
      const LoadingButtonValue base = LoadingButtonValue(
        state: ActionState.loading,
        progress: 0.4,
      );
      expect(base.copyWith(clearProgress: true).progress, isNull);
      // clearProgress wins even when a replacement progress is passed too.
      expect(
        base.copyWith(progress: 0.9, clearProgress: true).progress,
        isNull,
      );
    });

    test('copyWith(error: null) alone does NOT clear the error or stack', () {
      final LoadingButtonValue base = LoadingButtonValue(
        state: ActionState.error,
        error: 'bad',
        stackTrace: StackTrace.current,
      );
      final LoadingButtonValue copy = base.copyWith(error: null);
      expect(copy.error, 'bad');
      expect(copy.stackTrace, isNotNull);
    });

    test('copyWith(clearError: true) clears both error and stackTrace', () {
      final LoadingButtonValue base = LoadingButtonValue(
        state: ActionState.error,
        progress: 0.4,
        error: 'bad',
        stackTrace: StackTrace.current,
      );
      final LoadingButtonValue copy = base.copyWith(clearError: true);
      expect(copy.error, isNull);
      expect(copy.stackTrace, isNull);
      // clearError leaves progress alone.
      expect(copy.progress, 0.4);
    });

    test('toString names the state and mentions progress and error', () {
      expect(const LoadingButtonValue().toString(), 'LoadingButtonValue(idle)');
      expect(
        const LoadingButtonValue(state: ActionState.loading, progress: 0.5)
            .toString(),
        'LoadingButtonValue(loading, progress: 0.5)',
      );
      expect(
        const LoadingButtonValue(state: ActionState.error, error: 'bad')
            .toString(),
        'LoadingButtonValue(error, error: bad)',
      );
    });
  });

  group('LoadingButtonController commands', () {
    late LoadingButtonController controller;
    late _Counter notifications;

    setUp(() {
      controller = LoadingButtonController();
      notifications = _Counter();
      controller.addListener(notifications.call);
    });

    tearDown(() => controller.dispose());

    test('a fresh controller starts idle, unattached and not cooling down', () {
      expect(controller.value, LoadingButtonValue.idle);
      expect(controller.state, ActionState.idle);
      expect(controller.progress, isNull);
      expect(controller.lastError, isNull);
      expect(controller.lastStackTrace, isNull);
      expect(controller.isAttached, isFalse);
      expect(controller.attachmentCount, 0);
      expect(controller.isCoolingDown, isFalse);
      expect(controller.cooldownRemaining, Duration.zero);
    });

    test('a controller can be seeded with a non-idle initial value', () {
      final LoadingButtonController seeded = LoadingButtonController(
        value: const LoadingButtonValue(state: ActionState.disabled),
      );
      addTearDown(seeded.dispose);
      expect(seeded.state, ActionState.disabled);
    });

    test('start() moves to loading, indeterminate, notifying once', () {
      controller.start();
      expect(controller.value,
          const LoadingButtonValue(state: ActionState.loading));
      expect(controller.progress, isNull);
      expect(notifications.value, 1);
    });

    test('start(progress:) moves to loading with that progress, once', () {
      controller.start(progress: 0.25);
      expect(
        controller.value,
        const LoadingButtonValue(state: ActionState.loading, progress: 0.25),
      );
      expect(notifications.value, 1);
    });

    test('start() clears a previously recorded error', () {
      controller.error('bad', StackTrace.current);
      controller.start();
      expect(controller.lastError, isNull);
      expect(controller.lastStackTrace, isNull);
    });

    test('setProgress() updates progress without leaving loading, once', () {
      controller.start();
      notifications.value = 0;

      controller.setProgress(0.5);
      expect(controller.state, ActionState.loading);
      expect(controller.progress, 0.5);
      expect(notifications.value, 1);
    });

    test('setProgress(null) restores the indeterminate indicator, once', () {
      controller.start(progress: 0.5);
      notifications.value = 0;

      controller.setProgress(null);
      expect(controller.state, ActionState.loading);
      expect(controller.progress, isNull);
      expect(controller.value.isDeterminate, isFalse);
      expect(notifications.value, 1);
    });

    test('setProgress() with an out-of-range value trips an assert', () {
      expect(() => controller.setProgress(1.5), throwsAssertionError);
      expect(() => controller.setProgress(-0.5), throwsAssertionError);
    });

    test('setProgress() with an unchanged value does not notify again', () {
      controller.start(progress: 0.5);
      notifications.value = 0;

      controller.setProgress(0.5);
      expect(notifications.value, 0);
    });

    test('success() moves to success and drops progress, notifying once', () {
      controller.start(progress: 0.7);
      notifications.value = 0;

      controller.success();
      expect(controller.value,
          const LoadingButtonValue(state: ActionState.success));
      expect(controller.progress, isNull);
      expect(controller.lastError, isNull);
      expect(notifications.value, 1);
    });

    test('error() records the error and stack trace, notifying once', () {
      final StackTrace stack = StackTrace.current;
      final Object failure = Exception('upload failed');
      controller.start(progress: 0.7);
      notifications.value = 0;

      controller.error(failure, stack);
      expect(controller.state, ActionState.error);
      expect(controller.lastError, same(failure));
      expect(controller.lastStackTrace, same(stack));
      expect(controller.progress, isNull);
      expect(notifications.value, 1);
    });

    test('error() with no arguments still moves to the error state', () {
      controller.error();
      expect(controller.state, ActionState.error);
      expect(controller.lastError, isNull);
    });

    test('reset() returns to idle and clears progress and error, once', () {
      controller.error('bad', StackTrace.current);
      controller.setProgress(0.5);
      notifications.value = 0;

      controller.reset();
      expect(controller.value, LoadingButtonValue.idle);
      expect(controller.progress, isNull);
      expect(controller.lastError, isNull);
      expect(controller.lastStackTrace, isNull);
      expect(notifications.value, 1);
    });

    test('setEnabled(false) moves to disabled, notifying once', () {
      controller.setEnabled(false);
      expect(controller.state, ActionState.disabled);
      expect(notifications.value, 1);
    });

    test('setEnabled(true) returns a disabled controller to idle, once', () {
      controller.setEnabled(false);
      notifications.value = 0;

      controller.setEnabled(true);
      expect(controller.state, ActionState.idle);
      expect(notifications.value, 1);
    });

    test('setEnabled() leaves progress and the last error untouched', () {
      controller.error('bad', StackTrace.current);
      controller.setProgress(0.25);
      controller.setEnabled(false);
      expect(controller.state, ActionState.disabled);
      expect(controller.progress, 0.25);
      expect(controller.lastError, 'bad');
    });

    test('setEnabled(false) is a no-op while a run is in flight', () {
      controller.start(progress: 0.4);
      notifications.value = 0;

      controller.setEnabled(false);
      expect(controller.state, ActionState.loading);
      expect(controller.progress, 0.4);
      expect(notifications.value, 0);
    });

    test('setActionState() sets any phase directly, notifying once', () {
      controller.setActionState(ActionState.success);
      expect(controller.state, ActionState.success);
      expect(notifications.value, 1);
    });

    test('setActionState(progress:) sets phase and progress together', () {
      controller.setActionState(ActionState.loading, progress: 0.8);
      expect(
        controller.value,
        const LoadingButtonValue(state: ActionState.loading, progress: 0.8),
      );
      expect(notifications.value, 1);
    });

    test('setActionState() preserves progress unless asked to clear it', () {
      controller.start(progress: 0.8);
      notifications.value = 0;

      // Changing only the phase must not silently discard progress.
      controller.setActionState(ActionState.disabled);
      expect(controller.state, ActionState.disabled);
      expect(controller.progress, 0.8);
      expect(notifications.value, 1);

      controller.setActionState(ActionState.disabled, clearProgress: true);
      expect(controller.progress, isNull);
      expect(notifications.value, 2);
    });

    test('setActionState() can set the phase and the progress together', () {
      controller.start(progress: 0.2);
      controller.setActionState(ActionState.loading, progress: 0.6);
      expect(controller.state, ActionState.loading);
      expect(controller.progress, 0.6);
    });

    test('setActionState() preserves the last error', () {
      controller.error('bad', StackTrace.current);
      controller.setActionState(ActionState.idle);
      expect(controller.state, ActionState.idle);
      expect(controller.lastError, 'bad');
    });

    test('press() on an unattached controller completes without throwing', () {
      expect(controller.press(), completes);
    });

    test('disposing an unattached controller does not throw', () {
      final LoadingButtonController fresh = LoadingButtonController();
      expect(fresh.dispose, returnsNormally);
    });
  });

  group('LoadingButtonController cooldown', () {
    testWidgets('startCooldown holds disabled, then returns to idle',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      controller.startCooldown(const Duration(seconds: 30));
      expect(controller.state, ActionState.disabled);
      expect(controller.isCoolingDown, isTrue);
      expect(
        controller.cooldownRemaining,
        lessThanOrEqualTo(const Duration(seconds: 30)),
      );
      expect(
        controller.cooldownRemaining,
        greaterThan(const Duration(seconds: 29)),
      );

      await tester.pump(const Duration(seconds: 29));
      expect(controller.state, ActionState.disabled);

      await tester.pump(const Duration(seconds: 2));
      expect(controller.state, ActionState.idle);
      expect(controller.isCoolingDown, isFalse);
      expect(controller.cooldownRemaining, Duration.zero);
    });

    testWidgets('startCooldown(Duration.zero) never disables the button',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      controller.startCooldown(Duration.zero);
      expect(controller.state, ActionState.idle);
      expect(controller.isCoolingDown, isFalse);
      expect(controller.cooldownRemaining, Duration.zero);
    });

    testWidgets('calling startCooldown again restarts the window',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      controller.startCooldown(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 5));
      controller.startCooldown(const Duration(seconds: 10));

      // The first window would have elapsed by now; the restart cancelled it.
      await tester.pump(const Duration(seconds: 6));
      expect(controller.state, ActionState.disabled);
      expect(controller.isCoolingDown, isTrue);

      await tester.pump(const Duration(seconds: 5));
      expect(controller.state, ActionState.idle);
      expect(controller.isCoolingDown, isFalse);
    });

    testWidgets('a cooldown that ends elsewhere than disabled is not reset',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      controller.startCooldown(const Duration(seconds: 10));
      controller.start();

      await tester.pump(const Duration(seconds: 11));
      expect(controller.state, ActionState.loading);
    });

    testWidgets('disposing during a cooldown cancels the pending timer',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      controller.startCooldown(const Duration(seconds: 30));
      controller.dispose();

      // A surviving timer would fire here and notify a disposed notifier,
      // and would fail the test as a pending timer either way.
      await tester.pump(const Duration(seconds: 60));
    });
  });

  group('LoadingButtonController attached to a LoadingButton', () {
    testWidgets('attaching reports isAttached and attachmentCount',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      expect(controller.isAttached, isFalse);
      await _pumpButton(tester, controller: controller);

      expect(controller.isAttached, isTrue);
      expect(controller.attachmentCount, 1);
    });

    testWidgets('the button mirrors every controller state change',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      await _pumpButton(tester, controller: controller);

      expect(find.text('Go'), findsOneWidget);

      controller.start();
      await _swap(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Go'), findsNothing);

      controller.success();
      await _swap(tester);
      expect(find.byIcon(Icons.check), findsOneWidget);

      controller.error('bad');
      await _swap(tester);
      expect(find.byIcon(Icons.error), findsOneWidget);

      controller.reset();
      await _swap(tester);
      expect(find.text('Go'), findsOneWidget);
    });

    testWidgets('the button renders determinate progress from the controller',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      await _pumpButton(tester, controller: controller);

      controller.start(progress: 0.25);
      await _swap(tester);
      expect(
        tester
            .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator))
            .value,
        0.25,
      );

      controller.setProgress(0.75);
      await _swap(tester);
      expect(
        tester
            .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator))
            .value,
        0.75,
      );
    });

    testWidgets('a disabled controller state disables the underlying button',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      await _pumpButton(
        tester,
        controller: controller,
        onPressed: () async {},
      );

      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isTrue);

      controller.setEnabled(false);
      await _swap(tester);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isFalse);

      controller.setEnabled(true);
      await _swap(tester);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isTrue);
    });

    testWidgets("controller.press() runs the button's onPressed",
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      int calls = 0;
      await _pumpButton(
        tester,
        controller: controller,
        onPressed: () async => calls++,
      );

      await controller.press();
      await _swap(tester);

      expect(calls, 1);
      expect(controller.state, ActionState.success);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('controller.press() awaits the callback before returning',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      final Completer<void> gate = Completer<void>();
      bool settled = false;

      await _pumpButton(
        tester,
        controller: controller,
        onPressed: () => gate.future,
      );

      unawaited(controller.press().then((_) => settled = true));
      await tester.pump();
      expect(controller.state, ActionState.loading);
      expect(settled, isFalse);

      gate.complete();
      await _swap(tester);
      expect(settled, isTrue);
      expect(controller.state, ActionState.success);
    });

    testWidgets('controller.press() is rejected while a run is in flight',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      final Completer<void> gate = Completer<void>();
      int calls = 0;

      await _pumpButton(
        tester,
        controller: controller,
        onPressed: () {
          calls++;
          return gate.future;
        },
      );

      final Future<void> first = controller.press();
      await tester.pump();
      await controller.press();
      expect(calls, 1);

      gate.complete();
      await first;
      await _swap(tester);
      expect(calls, 1);
    });

    testWidgets('a tap cannot start a second run behind controller.press()',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      final Completer<void> gate = Completer<void>();
      int calls = 0;

      await _pumpButton(
        tester,
        controller: controller,
        onPressed: () {
          calls++;
          return gate.future;
        },
      );

      // The press latch is set synchronously, before the first await, so the
      // run is already under way and the button is already loading when the
      // tap lands on the still-enabled tree of the previous frame.
      final Future<void> programmatic = controller.press();
      expect(calls, 1);
      expect(controller.state, ActionState.loading);

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(calls, 1);

      gate.complete();
      await programmatic;
      await _swap(tester);
      expect(calls, 1);
    });

    testWidgets('controller.press() cannot start a second run behind a tap',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      final Completer<void> gate = Completer<void>();
      int calls = 0;

      await _pumpButton(
        tester,
        controller: controller,
        onPressed: () {
          calls++;
          return gate.future;
        },
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(calls, 1, reason: 'the tap itself must have started the run');
      expect(controller.state, ActionState.loading);

      await controller.press();
      expect(calls, 1);

      gate.complete();
      await _swap(tester);
      expect(calls, 1);
    });

    testWidgets('press() on a controller whose button is disabled does nothing',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      int calls = 0;
      await _pumpButton(
        tester,
        controller: controller,
        enabled: false,
        onPressed: () async => calls++,
      );

      await controller.press();
      expect(calls, 0);
      // `enabled` belongs to the widget, not to the shared value: a disabled
      // button refuses the press without writing ActionState.disabled into a
      // controller it may be sharing with enabled siblings.
      expect(controller.state, ActionState.idle);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    });

    testWidgets(
        'REGRESSION: a disabled button does not disable its siblings on the '
        'same controller', (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      int calls = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              LoadingButton(
                controller: controller,
                enabled: false,
                enableHapticFeedback: false,
                onPressed: () async => calls++,
                child: const Text('disabled one'),
              ),
              LoadingButton(
                controller: controller,
                enableHapticFeedback: false,
                onPressed: () async => calls++,
                resetAfterDuration: false,
                child: const Text('enabled one'),
              ),
            ],
          ),
        ),
      ));

      expect(controller.attachmentCount, 2);
      expect(controller.state, ActionState.idle);

      await controller.press();
      await tester.pump();

      // Exactly one run: the enabled sibling took it, and the shared value
      // means only one run can be in flight at a time.
      expect(calls, 1);
      expect(controller.state, ActionState.success);
    });

    testWidgets('the button detaches from the controller when it is disposed',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      await _pumpButton(tester, controller: controller);
      expect(controller.attachmentCount, 1);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      expect(controller.attachmentCount, 0);
      expect(controller.isAttached, isFalse);

      // press() on the now-detached controller is a no-op, not a crash.
      await controller.press();
      expect(controller.dispose, returnsNormally);
    });

    testWidgets('swapping a button to another controller moves the attachment',
        (WidgetTester tester) async {
      final LoadingButtonController first = LoadingButtonController();
      final LoadingButtonController second = LoadingButtonController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await _pumpButton(tester, controller: first);
      expect(first.attachmentCount, 1);
      expect(second.attachmentCount, 0);

      await _pumpButton(tester, controller: second);
      expect(first.attachmentCount, 0);
      expect(second.attachmentCount, 1);

      second.start();
      await _swap(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('one LoadingButtonController driving two LoadingButtons', () {
    Future<void> pumpTwo(
      WidgetTester tester,
      LoadingButtonController controller, {
      AsyncCallback? onPressed,
    }) {
      Widget button(String label) => LoadingButton(
            controller: controller,
            onPressed: onPressed,
            resetAfterDuration: false,
            enableHapticFeedback: false,
            child: Text(label),
          );
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[button('first'), button('second')],
            ),
          ),
        ),
      );
    }

    testWidgets('attachmentCount counts both buttons',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await pumpTwo(tester, controller);
      expect(controller.attachmentCount, 2);
      expect(controller.isAttached, isTrue);
    });

    testWidgets('both buttons mirror the same controller value',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      await pumpTwo(tester, controller);

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);

      controller.start();
      await _swap(tester);
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

      controller.success();
      await _swap(tester);
      expect(find.byIcon(Icons.check), findsNWidgets(2));

      controller.reset();
      await _swap(tester);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets(
        'press() runs only the first button, because the shared value is '
        'already loading by the time the second is invoked',
        (WidgetTester tester) async {
      // LoadingButtonController.press() documents that it "runs each one's
      // onPressed", but every attached button gates on the *shared* value:
      // the first binding sets it to loading synchronously, before its first
      // await, so every later binding sees a non-idle state and bails out.
      // This test pins the behaviour that actually ships; if press() is ever
      // fixed to fan out, this expectation is the one to flip.
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      int calls = 0;

      await pumpTwo(tester, controller, onPressed: () async => calls++);

      await controller.press();
      await _swap(tester);

      expect(calls, 1);
      expect(controller.state, ActionState.success);
      // Both buttons still mirror the run that did happen.
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('removing one button leaves the other attached',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      await pumpTwo(tester, controller);
      expect(controller.attachmentCount, 2);

      await _pumpButton(tester, controller: controller);
      expect(controller.attachmentCount, 1);

      controller.start();
      await _swap(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
