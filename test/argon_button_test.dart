import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

/// Wraps [child] in the minimum app scaffolding the Argon buttons need.
Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

const double _kWidth = 200;
const double _kHeight = 50;
const Duration _kAnimation = Duration(milliseconds: 450);

/// The width of the outermost box the Argon button sizes itself to.
double _widthOf(WidgetTester tester, Type type) =>
    tester.getSize(find.byType(type)).width;

void main() {
  group('ArgonButton', () {
    testWidgets(
        'startLoading collapses the button to its loader and stopLoading '
        'expands it back to the idle child', (WidgetTester tester) async {
      late void Function() startLoading;
      late void Function() stopLoading;
      ArgonButtonState? stateAtTap;

      await tester.pumpWidget(_host(ArgonButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        onTap: (Function start, Function stop, ArgonButtonState state) {
          startLoading = start as void Function();
          stopLoading = stop as void Function();
          stateAtTap = state;
        },
        loader: const CircularProgressIndicator(),
        child: const Text('Login'),
      )));

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_widthOf(tester, ArgonButton), _kWidth);

      await tester.tap(find.byType(ArgonButton));
      await tester.pump();
      expect(stateAtTap, ArgonButtonState.idle,
          reason: 'onTap is handed the state the button was in when tapped');

      startLoading();
      await tester.pump();

      expect(find.text('Login'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'busy swaps the child for the loader immediately');

      // Half way through the animation the width is strictly between the two
      // endpoints, i.e. it is animating rather than snapping.
      await tester.pump(_kAnimation ~/ 2);
      final double midWidth = _widthOf(tester, ArgonButton);
      expect(midWidth, lessThan(_kWidth));
      expect(midWidth, greaterThan(_kHeight));

      // A spinner animates forever, so the frames are counted out by hand
      // rather than settled.
      await tester.pump(const Duration(milliseconds: 500));
      expect(_widthOf(tester, ArgonButton), _kHeight,
          reason: 'minWidth defaults to the height, giving a circle');

      stopLoading();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(_widthOf(tester, ArgonButton), _kWidth);
      expect(find.text('Login'), findsOneWidget,
          reason: 'the dismissed animation returns the button to idle');
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a second tap reports the busy state to onTap',
        (WidgetTester tester) async {
      late void Function() startLoading;
      final List<ArgonButtonState> seen = <ArgonButtonState>[];

      await tester.pumpWidget(_host(ArgonButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        onTap: (Function start, Function stop, ArgonButtonState state) {
          startLoading = start as void Function();
          seen.add(state);
        },
        child: const Text('Login'),
      )));

      await tester.tap(find.byType(ArgonButton));
      await tester.pump();
      startLoading();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(ArgonButton));
      await tester.pump();

      expect(seen, <ArgonButtonState>[
        ArgonButtonState.idle,
        ArgonButtonState.busy,
      ]);
    });

    testWidgets(
        'REGRESSION: a null onTap disables the button instead of crashing on a '
        'force-unwrap', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ArgonButton(
        height: _kHeight,
        width: _kWidth,
        onTap: null,
        child: Text('Login'),
      )));

      expect(
        tester.widget<MaterialButton>(find.byType(MaterialButton)).enabled,
        isFalse,
        reason: 'no callback means no press target',
      );

      await tester.tap(find.byType(ArgonButton), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'REGRESSION: a null loader falls back to the default indicator instead '
        'of crashing', (WidgetTester tester) async {
      late void Function() startLoading;

      await tester.pumpWidget(_host(ArgonButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        onTap: (Function start, Function stop, ArgonButtonState state) {
          startLoading = start as void Function();
        },
        // No loader given.
        child: const Text('Login'),
      )));

      await tester.tap(find.byType(ArgonButton));
      await tester.pump();
      startLoading();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets(
        'REGRESSION: calling the escaped startLoading/stopLoading closures '
        'after the button is unmounted does not throw',
        (WidgetTester tester) async {
      late void Function() startLoading;
      late void Function() stopLoading;

      await tester.pumpWidget(_host(ArgonButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        onTap: (Function start, Function stop, ArgonButtonState state) {
          startLoading = start as void Function();
          stopLoading = stop as void Function();
        },
        child: const Text('Login'),
      )));

      await tester.tap(find.byType(ArgonButton));
      await tester.pump();

      // The user navigates away while the async work is still in flight.
      await tester.pumpWidget(_host(const Text('gone')));
      expect(find.text('gone'), findsOneWidget);

      expect(startLoading, returnsNormally,
          reason: 'the closure outlives the widget by design');
      expect(stopLoading, returnsNormally);

      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a zero width leaves the button unconstrained rather than '
        'collapsing it to nothing', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ArgonButton(
        height: _kHeight,
        width: 0,
        child: Text('Login'),
      )));

      expect(tester.takeException(), isNull);
      expect(_widthOf(tester, ArgonButton), greaterThan(0),
          reason: 'lerpWidth returns null so the child sizes the button');
      expect(find.text('Login'), findsOneWidget);
    });
  });

  group('ArgonTimerButton', () {
    testWidgets(
        'counts down once a second, auto-reverses at zero and returns to the '
        'idle child', (WidgetTester tester) async {
      late void Function(int) startTimer;

      await tester.pumpWidget(_host(ArgonTimerButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        onTap: (Function start, ArgonButtonState? state) {
          startTimer = start as void Function(int);
        },
        loader: (int seconds) => Text('$seconds s'),
        child: const Text('Resend'),
      )));

      expect(find.text('Resend'), findsOneWidget);
      expect(_widthOf(tester, ArgonTimerButton), _kWidth);

      await tester.tap(find.byType(ArgonTimerButton));
      startTimer(3);
      await tester.pump();

      expect(find.text('Resend'), findsNothing);
      expect(find.text('3 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('2 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1 s'), findsOneWidget);

      // The collapse animation finished long before the countdown did.
      expect(_widthOf(tester, ArgonTimerButton), _kHeight);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0 s'), findsOneWidget,
          reason: 'zero is rendered on the frame the reverse is kicked off');

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_widthOf(tester, ArgonTimerButton), _kWidth,
          reason: 'reaching zero auto-reverses the width animation');
      expect(find.text('Resend'), findsOneWidget);

      // Let the periodic timer observe zero and cancel itself.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend'), findsOneWidget);
    });

    testWidgets('initialTimer starts the countdown without a tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(ArgonTimerButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        initialTimer: 2,
        onTap: (Function start, ArgonButtonState? state) {},
        loader: (int seconds) => Text('$seconds s'),
        child: const Text('Resend'),
      )));

      expect(find.text('2 s'), findsOneWidget);
      expect(find.text('Resend'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('0 s'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Resend'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('a null loader falls back to the default indicator',
        (WidgetTester tester) async {
      late void Function(int) startTimer;

      await tester.pumpWidget(_host(ArgonTimerButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        onTap: (Function start, ArgonButtonState? state) {
          startTimer = start as void Function(int);
        },
        child: const Text('Resend'),
      )));

      await tester.tap(find.byType(ArgonTimerButton));
      startTimer(2);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend'), findsOneWidget);
    });

    testWidgets('a null onTap disables the button instead of crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(const ArgonTimerButton(
        height: _kHeight,
        width: _kWidth,
        onTap: null,
        child: Text('Resend'),
      )));

      expect(
        tester.widget<MaterialButton>(find.byType(MaterialButton)).enabled,
        isFalse,
      );

      await tester.tap(find.byType(ArgonTimerButton), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Resend'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'REGRESSION: startTimer(0) throws an ArgumentError instead of a raw '
        'String', (WidgetTester tester) async {
      late void Function(int) startTimer;

      await tester.pumpWidget(_host(ArgonTimerButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        onTap: (Function start, ArgonButtonState? state) {
          startTimer = start as void Function(int);
        },
        loader: (int seconds) => Text('$seconds s'),
        child: const Text('Resend'),
      )));

      await tester.tap(find.byType(ArgonTimerButton));
      await tester.pump();

      expect(() => startTimer(0), throwsArgumentError);
      expect(() => startTimer(-1), throwsArgumentError);

      await tester.pump();
      expect(find.text('Resend'), findsOneWidget,
          reason: 'a rejected countdown leaves the button idle');
    });

    testWidgets('cancels its periodic Timer when disposed mid-countdown',
        (WidgetTester tester) async {
      late void Function(int) startTimer;

      await tester.pumpWidget(_host(ArgonTimerButton(
        height: _kHeight,
        width: _kWidth,
        animationDuration: _kAnimation,
        onTap: (Function start, ArgonButtonState? state) {
          startTimer = start as void Function(int);
        },
        loader: (int seconds) => Text('$seconds s'),
        child: const Text('Resend'),
      )));

      await tester.tap(find.byType(ArgonTimerButton));
      startTimer(30);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('29 s'), findsOneWidget);

      await tester.pumpWidget(_host(const Text('gone')));

      // A live Timer would tick into a defunct State here, and the test would
      // additionally fail with a pending timer at teardown.
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
      expect(find.text('gone'), findsOneWidget);
    });
  });
}
