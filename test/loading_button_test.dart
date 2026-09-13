import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

/// Transitions are irrelevant to almost every assertion here, so the default
/// cross fade is collapsed to a single frame and pumped past with [_settle].
const Duration _fast = Duration(milliseconds: 1);

/// Applies a pending state change and then lets the [_fast] transition run
/// out, so exactly one child is on screen. Advances the clock by 16ms, which
/// is short enough not to trip the success/error windows used below.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: child)),
    );

/// A marker so a test can prove the custom transition builder was used.
class _Transition extends StatelessWidget {
  const _Transition({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

void main() {
  group('state machine', () {
    testWidgets(
        'runs idle -> loading -> success -> idle, swapping the child at each '
        'step and reporting every transition but the initial idle',
        (WidgetTester tester) async {
      final Completer<void> gate = Completer<void>();
      final List<ActionState> observed = <ActionState>[];

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        successDuration: const Duration(milliseconds: 200),
        enableHapticFeedback: false,
        onPressed: () => gate.future,
        onStateChanged: observed.add,
        child: const Text('Go'),
      )));

      // Idle: the child, and no state change reported for simply existing.
      expect(find.text('Go'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(observed, isEmpty);

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);

      // Loading: the default indeterminate spinner, child gone.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Go'), findsNothing);
      expect(observed, <ActionState>[ActionState.loading]);

      gate.complete();
      await _settle(tester);

      // Success: the default check, spinner gone.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(observed, <ActionState>[ActionState.loading, ActionState.success]);

      await tester.pump(const Duration(milliseconds: 250));
      await _settle(tester);

      // Back to idle, with the original child.
      expect(find.text('Go'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(
        observed,
        <ActionState>[
          ActionState.loading,
          ActionState.success,
          ActionState.idle,
        ],
      );
    });

    testWidgets(
        'shows the error state, hands onFailure the thrown error and a '
        'non-null stack trace, then returns to idle',
        (WidgetTester tester) async {
      final Exception boom = Exception('boom');
      final List<ActionState> observed = <ActionState>[];
      Object? caught;
      StackTrace? caughtStack;

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        errorDuration: const Duration(milliseconds: 200),
        enableHapticFeedback: false,
        onPressed: () async => throw boom,
        onFailure: (Object error, StackTrace stackTrace) {
          caught = error;
          caughtStack = stackTrace;
        },
        onStateChanged: observed.add,
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Go'), findsNothing);
      expect(caught, same(boom));
      expect(caughtStack, isNotNull);
      expect(observed, <ActionState>[ActionState.loading, ActionState.error]);
      // Handled by onFailure, so nothing escapes to the error reporter.
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 250));
      await _settle(tester);

      expect(find.text('Go'), findsOneWidget);
      expect(
        observed,
        <ActionState>[
          ActionState.loading,
          ActionState.error,
          ActionState.idle,
        ],
      );
    });

    testWidgets('still calls the deprecated onError with the thrown error',
        (WidgetTester tester) async {
      final Exception boom = Exception('legacy');
      final List<Object?> seen = <Object?>[];

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        resetAfterDuration: false,
        enableHapticFeedback: false,
        onPressed: () async => throw boom,
        // ignore: deprecated_member_use_from_same_package
        onError: seen.add,
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);

      expect(seen, <Object?>[boom]);
      // onError counts as an observer, so the error is not reported twice.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'reports an unobserved failure to FlutterError.onError instead of '
        'swallowing it', (WidgetTester tester) async {
      final Exception boom = Exception('unobserved');
      final List<FlutterErrorDetails> reported = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = reported.add;

      try {
        await tester.pumpWidget(_host(LoadingButton(
          animationDuration: _fast,
          resetAfterDuration: false,
          enableHapticFeedback: false,
          onPressed: () async => throw boom,
          child: const Text('Go'),
        )));

        await tester.tap(find.byType(ElevatedButton));
        await _settle(tester);
      } finally {
        FlutterError.onError = previous;
      }

      expect(reported, hasLength(1));
      expect(reported.single.exception, same(boom));
      expect(reported.single.stack, isNotNull);
      expect(reported.single.library, 'loading_icon_button');
      // The button still shows the failure even with nobody listening.
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('calls onSuccess exactly once on the success path',
        (WidgetTester tester) async {
      int successes = 0;

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        resetAfterDuration: false,
        enableHapticFeedback: false,
        onPressed: () async {},
        onSuccess: () => successes++,
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(successes, 1);
    });

    testWidgets('never calls onSuccess when onPressed throws',
        (WidgetTester tester) async {
      int successes = 0;

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        resetAfterDuration: false,
        enableHapticFeedback: false,
        onPressed: () async => throw Exception('boom'),
        onSuccess: () => successes++,
        onFailure: (Object _, StackTrace __) {},
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(successes, 0);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });

  group('press path', () {
    testWidgets('runs onPressed once when tapped twice within the same frame',
        (WidgetTester tester) async {
      final Completer<void> gate = Completer<void>();
      int calls = 0;

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        resetAfterDuration: false,
        enableHapticFeedback: false,
        onPressed: () {
          calls++;
          return gate.future;
        },
        child: const Text('Go'),
      )));

      // No pump between the taps: the widget has not rebuilt, so only the
      // synchronous press latch can reject the second one.
      final Finder button = find.byType(ElevatedButton);
      await tester.tap(button);
      await tester.tap(button);

      expect(calls, 1);

      gate.complete();
      await _settle(tester);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets(
        'invokes onPressed and enters loading after a single pump, so '
        'haptics and the press animation cannot gate it',
        (WidgetTester tester) async {
      final Completer<void> gate = Completer<void>();
      bool called = false;
      final GlobalKey<LoadingButtonState> key = GlobalKey<LoadingButtonState>();

      await tester.pumpWidget(_host(LoadingButton(
        key: key,
        animationDuration: _fast,
        resetAfterDuration: false,
        // Haptics on: the platform channel must not be awaited.
        onPressed: () {
          called = true;
          return gate.future;
        },
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(called, isTrue);
      expect(key.currentState!.currentState, ActionState.loading);

      gate.complete();
      await _settle(tester);
    });

    testWidgets('rejects a press that arrives while a run is still in flight',
        (WidgetTester tester) async {
      final Completer<void> gate = Completer<void>();
      int calls = 0;
      final GlobalKey<LoadingButtonState> key = GlobalKey<LoadingButtonState>();

      await tester.pumpWidget(_host(LoadingButton(
        key: key,
        animationDuration: _fast,
        resetAfterDuration: false,
        enableHapticFeedback: false,
        onPressed: () {
          calls++;
          return gate.future;
        },
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
      await key.currentState!.press();

      expect(calls, 1);

      gate.complete();
      await _settle(tester);
    });

    testWidgets('survives being disposed while onPressed is still in flight',
        (WidgetTester tester) async {
      final Completer<void> gate = Completer<void>();

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        enableHapticFeedback: false,
        onPressed: () => gate.future,
        onStateChanged: (ActionState _) {},
        onSuccess: () {},
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Tear the button out mid-run, then let the future land.
      await tester.pumpWidget(_host(const SizedBox.shrink()));
      gate.complete();
      await tester.pump(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
      expect(find.byType(LoadingButton), findsNothing);
    });

    testWidgets('holds the terminal state when resetAfterDuration is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        successDuration: const Duration(milliseconds: 50),
        resetAfterDuration: false,
        enableHapticFeedback: false,
        onPressed: () async {},
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Go'), findsNothing);
    });

    testWidgets('honours a custom successDuration',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        successDuration: const Duration(milliseconds: 500),
        enableHapticFeedback: false,
        onPressed: () async {},
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Still held just before the window elapses...
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.check), findsOneWidget);

      // ...and released just after it.
      await tester.pump(const Duration(milliseconds: 200));
      await _settle(tester);
      expect(find.text('Go'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('honours a custom errorDuration', (WidgetTester tester) async {
      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        errorDuration: const Duration(milliseconds: 500),
        enableHapticFeedback: false,
        onPressed: () async => throw Exception('boom'),
        onFailure: (Object _, StackTrace __) {},
        child: const Text('Go'),
      )));

      await tester.tap(find.byType(ElevatedButton));
      await _settle(tester);
      expect(find.byIcon(Icons.error), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.error), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await _settle(tester);
      expect(find.text('Go'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);
    });
  });

  group('enabled', () {
    testWidgets('renders ActionState.disabled and rejects taps when disabled',
        (WidgetTester tester) async {
      int calls = 0;
      final GlobalKey<LoadingButtonState> key = GlobalKey<LoadingButtonState>();

      await tester.pumpWidget(_host(LoadingButton(
        key: key,
        animationDuration: _fast,
        enabled: false,
        enableHapticFeedback: false,
        onPressed: () async => calls++,
        child: const Text('Go'),
      )));
      await _settle(tester);

      expect(key.currentState!.currentState, ActionState.disabled);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await _settle(tester);
      // Even the programmatic path refuses.
      await key.currentState!.press();
      await _settle(tester);

      expect(calls, 0);
      expect(key.currentState!.currentState, ActionState.disabled);
    });

    testWidgets('returns to idle when enabled flips back to true',
        (WidgetTester tester) async {
      final GlobalKey<LoadingButtonState> key = GlobalKey<LoadingButtonState>();

      Widget build(bool enabled) => _host(LoadingButton(
            key: key,
            animationDuration: _fast,
            enabled: enabled,
            enableHapticFeedback: false,
            onPressed: () async {},
            child: const Text('Go'),
          ));

      await tester.pumpWidget(build(false));
      await _settle(tester);
      expect(key.currentState!.currentState, ActionState.disabled);

      await tester.pumpWidget(build(true));
      await _settle(tester);

      expect(key.currentState!.currentState, ActionState.idle);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('disables the underlying button when onPressed is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(const LoadingButton(
        animationDuration: _fast,
        child: Text('Go'),
      )));

      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    });
  });

  group('button types', () {
    Future<void> expectType(
      WidgetTester tester,
      ButtonType type,
      Type expected,
      List<Type> others,
    ) async {
      await tester.pumpWidget(_host(LoadingButton(
        type: type,
        animationDuration: _fast,
        enableHapticFeedback: false,
        onPressed: () async {},
        child: const Icon(Icons.send),
      )));

      expect(find.byType(expected), findsOneWidget, reason: '$type');
      for (final Type other in others) {
        expect(find.byType(other), findsNothing, reason: '$type vs $other');
      }
    }

    testWidgets('ButtonType.elevated builds an ElevatedButton',
        (WidgetTester tester) async {
      await expectType(tester, ButtonType.elevated, ElevatedButton,
          <Type>[FilledButton, OutlinedButton, TextButton, IconButton]);
    });

    testWidgets('ButtonType.filled builds a FilledButton',
        (WidgetTester tester) async {
      await expectType(tester, ButtonType.filled, FilledButton,
          <Type>[ElevatedButton, OutlinedButton, TextButton, IconButton]);
    });

    testWidgets('ButtonType.outlined builds an OutlinedButton',
        (WidgetTester tester) async {
      await expectType(tester, ButtonType.outlined, OutlinedButton,
          <Type>[ElevatedButton, FilledButton, TextButton, IconButton]);
    });

    testWidgets('ButtonType.text builds a TextButton',
        (WidgetTester tester) async {
      await expectType(tester, ButtonType.text, TextButton,
          <Type>[ElevatedButton, FilledButton, OutlinedButton, IconButton]);
    });

    testWidgets('ButtonType.icon builds an IconButton',
        (WidgetTester tester) async {
      await expectType(tester, ButtonType.icon, IconButton,
          <Type>[ElevatedButton, FilledButton, OutlinedButton]);
    });
  });

  group('child resolution', () {
    /// Builds a button already resting in [state], so no transition is in
    /// flight and no reset timer is pending.
    Future<LoadingButtonController> pumpIn(
      WidgetTester tester,
      ActionState state, {
      Widget? child,
      Widget? loadingWidget,
      Widget? successWidget,
      Widget? errorWidget,
      String? loadingText,
      String? successText,
      String? errorText,
      LoadingIndicator? indicator,
      LoadingButtonThemeData? theme,
    }) async {
      final LoadingButtonController controller = LoadingButtonController(
        value: LoadingButtonValue(state: state),
      );
      addTearDown(controller.dispose);

      Widget button = LoadingButton(
        animationDuration: _fast,
        resetAfterDuration: false,
        enableHapticFeedback: false,
        controller: controller,
        onPressed: () async {},
        loadingWidget: loadingWidget,
        successWidget: successWidget,
        errorWidget: errorWidget,
        loadingText: loadingText,
        successText: successText,
        errorText: errorText,
        indicator: indicator,
        child: child,
      );
      if (theme != null) {
        button = LoadingButtonTheme(data: theme, child: button);
      }
      await tester.pumpWidget(_host(button));
      await _settle(tester);
      return controller;
    }

    testWidgets('idle shows the child, and nothing when there is no child',
        (WidgetTester tester) async {
      await pumpIn(tester, ActionState.idle, child: const Text('Idle'));
      expect(find.text('Idle'), findsOneWidget);

      await pumpIn(tester, ActionState.idle);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('disabled shows the same child as idle',
        (WidgetTester tester) async {
      await pumpIn(tester, ActionState.disabled, child: const Text('Idle'));
      expect(find.text('Idle'), findsOneWidget);
    });

    testWidgets('loading prefers loadingWidget over text, indicator and theme',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.loading,
        loadingWidget: const Text('widget'),
        loadingText: 'text',
        indicator: const LoadingIndicator.widget(Text('indicator')),
        theme: const LoadingButtonThemeData(
          indicator: LoadingIndicator.widget(Text('theme')),
        ),
      );

      expect(find.text('widget'), findsOneWidget);
      expect(find.text('text'), findsNothing);
      expect(find.text('indicator'), findsNothing);
      expect(find.text('theme'), findsNothing);
    });

    testWidgets('loading prefers loadingText over indicator and theme',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.loading,
        loadingText: 'text',
        indicator: const LoadingIndicator.widget(Text('indicator')),
        theme: const LoadingButtonThemeData(
          indicator: LoadingIndicator.widget(Text('theme')),
        ),
      );

      expect(find.text('text'), findsOneWidget);
      expect(find.text('indicator'), findsNothing);
      expect(find.text('theme'), findsNothing);
    });

    testWidgets('loading prefers the widget indicator over the theme one',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.loading,
        indicator: const LoadingIndicator.widget(Text('indicator')),
        theme: const LoadingButtonThemeData(
          indicator: LoadingIndicator.widget(Text('theme')),
        ),
      );

      expect(find.text('indicator'), findsOneWidget);
      expect(find.text('theme'), findsNothing);
    });

    testWidgets('loading falls back to the theme indicator',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.loading,
        theme: const LoadingButtonThemeData(
          indicator: LoadingIndicator.widget(Text('theme')),
        ),
      );

      expect(find.text('theme'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('loading falls back to the default spinner',
        (WidgetTester tester) async {
      await pumpIn(tester, ActionState.loading);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator))
            .value,
        isNull,
      );
    });

    testWidgets('success prefers successWidget over text and theme',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.success,
        successWidget: const Text('widget'),
        successText: 'text',
        theme: const LoadingButtonThemeData(successWidget: Text('theme')),
      );

      expect(find.text('widget'), findsOneWidget);
      expect(find.text('text'), findsNothing);
      expect(find.text('theme'), findsNothing);
    });

    testWidgets('success prefers successText over the theme widget',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.success,
        successText: 'text',
        theme: const LoadingButtonThemeData(successWidget: Text('theme')),
      );

      expect(find.text('text'), findsOneWidget);
      expect(find.text('theme'), findsNothing);
    });

    testWidgets('success falls back to the theme widget, then to the check',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.success,
        theme: const LoadingButtonThemeData(successWidget: Text('theme')),
      );
      expect(find.text('theme'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);

      await pumpIn(tester, ActionState.success);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('error prefers errorWidget over text and theme',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.error,
        errorWidget: const Text('widget'),
        errorText: 'text',
        theme: const LoadingButtonThemeData(errorWidget: Text('theme')),
      );

      expect(find.text('widget'), findsOneWidget);
      expect(find.text('text'), findsNothing);
      expect(find.text('theme'), findsNothing);
    });

    testWidgets('error prefers errorText over the theme widget',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.error,
        errorText: 'text',
        theme: const LoadingButtonThemeData(errorWidget: Text('theme')),
      );

      expect(find.text('text'), findsOneWidget);
      expect(find.text('theme'), findsNothing);
    });

    testWidgets('error falls back to the theme widget, then to the error icon',
        (WidgetTester tester) async {
      await pumpIn(
        tester,
        ActionState.error,
        theme: const LoadingButtonThemeData(errorWidget: Text('theme')),
      );
      expect(find.text('theme'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);

      await pumpIn(tester, ActionState.error);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('announces the transient states as a live region',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpIn(
        tester,
        ActionState.loading,
        child: const Text('Go'),
      );

      expect(
        find.bySemanticsLabel('Loading'),
        findsOneWidget,
      );

      await pumpIn(tester, ActionState.error, errorText: 'Nope');
      expect(find.bySemanticsLabel('Nope'), findsOneWidget);

      handle.dispose();
    });
  });

  group('decoration', () {
    testWidgets('wraps the button in a Tooltip only when tooltip is set',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        enableHapticFeedback: false,
        onPressed: () async {},
        child: const Text('Go'),
      )));
      expect(find.byType(Tooltip), findsNothing);

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        enableHapticFeedback: false,
        tooltip: 'Send it',
        onPressed: () async {},
        child: const Text('Go'),
      )));

      final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Send it');
      expect(
        find.descendant(
          of: find.byType(Tooltip),
          matching: find.byType(ElevatedButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('passes focusNode and autofocus to the underlying button',
        (WidgetTester tester) async {
      final FocusNode node = FocusNode(debugLabel: 'loading-button');
      addTearDown(node.dispose);

      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        enableHapticFeedback: false,
        focusNode: node,
        autofocus: true,
        onPressed: () async {},
        child: const Text('Go'),
      )));
      await _settle(tester);

      expect(node.hasFocus, isTrue);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).focusNode,
        same(node),
      );
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).autofocus,
        isTrue,
      );
    });

    testWidgets('uses the supplied transitionBuilder instead of a fade',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        enableHapticFeedback: false,
        onPressed: () async {},
        transitionBuilder: (Widget child, Animation<double> animation) =>
            _Transition(child: child),
        child: const Text('Go'),
      )));
      await _settle(tester);

      expect(
        find.descendant(
          of: find.byType(_Transition),
          matching: find.text('Go'),
        ),
        findsOneWidget,
      );
      // The default cross fade is gone; the page route's own fades, which
      // live above the button, are not the button's doing.
      expect(
        find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('cross-fades with a FadeTransition by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(LoadingButton(
        animationDuration: _fast,
        enableHapticFeedback: false,
        onPressed: () async {},
        child: const Text('Go'),
      )));
      await _settle(tester);

      final Finder fade = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(FadeTransition),
      );
      expect(fade, findsOneWidget);
      expect(
        find.descendant(of: fade, matching: find.text('Go')),
        findsOneWidget,
      );
    });
  });
}
