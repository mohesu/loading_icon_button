import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

/// Wraps [child] in the minimum app scaffolding the Material buttons need.
Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

/// Swaps [FlutterError.onError] for a recorder for the duration of one test.
///
/// The auto buttons deliberately route tap-path failures to
/// [FlutterError.reportError]; without this the test binding would treat those
/// reports as test failures instead of as the behaviour under test.
List<FlutterErrorDetails> _captureFlutterErrors() {
  final List<FlutterErrorDetails> captured = <FlutterErrorDetails>[];
  final FlutterExceptionHandler? previous = FlutterError.onError;
  FlutterError.onError = captured.add;
  addTearDown(() {
    FlutterError.onError = previous;
  });
  return captured;
}

/// True when every Material button currently in the tree is enabled.
bool _allButtonsEnabled(WidgetTester tester) {
  final List<ButtonStyleButton> buttons = tester
      .widgetList<ButtonStyleButton>(
        find.byWidgetPredicate((Widget widget) => widget is ButtonStyleButton),
      )
      .toList();
  expect(buttons, isNotEmpty, reason: 'no Material button found in the tree');
  return buttons.every((ButtonStyleButton button) => button.enabled);
}

/// Resolves the padding [ButtonStyleButton.defaultStyleOf] gives [finder].
EdgeInsetsGeometry? _defaultPaddingOf(WidgetTester tester, Finder finder) {
  final ButtonStyleButton button = tester.widget<ButtonStyleButton>(finder);
  final BuildContext context = tester.element(finder);
  // The test has to ask the widget what Material would have given it; there
  // is no public accessor for a button's default style.
  // ignore: invalid_use_of_protected_member
  return button.defaultStyleOf(context).padding?.resolve(<WidgetState>{});
}

/// One `XxxAutoLoadingButton` constructor plus how to spot its idle child.
class _Family {
  const _Family(this.name, this.build, this.idleChild);

  final String name;
  final Widget Function(AsyncCallback onPressed) build;
  final Finder idleChild;
}

final List<_Family> _families = <_Family>[
  _Family(
    'ElevatedAutoLoadingButton',
    (AsyncCallback onPressed) => ElevatedAutoLoadingButton(
      onPressed: onPressed,
      child: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'ElevatedAutoLoadingButton.icon',
    (AsyncCallback onPressed) => ElevatedAutoLoadingButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
      label: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'FilledAutoLoadingButton',
    (AsyncCallback onPressed) => FilledAutoLoadingButton(
      onPressed: onPressed,
      child: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'FilledAutoLoadingButton.icon',
    (AsyncCallback onPressed) => FilledAutoLoadingButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
      label: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'FilledAutoLoadingButton.tonal',
    (AsyncCallback onPressed) => FilledAutoLoadingButton.tonal(
      onPressed: onPressed,
      child: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'FilledAutoLoadingButton.tonalIcon',
    (AsyncCallback onPressed) => FilledAutoLoadingButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
      label: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'OutlinedAutoLoadingButton',
    (AsyncCallback onPressed) => OutlinedAutoLoadingButton(
      onPressed: onPressed,
      child: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'OutlinedAutoLoadingButton.icon',
    (AsyncCallback onPressed) => OutlinedAutoLoadingButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
      label: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'TextAutoLoadingButton',
    (AsyncCallback onPressed) => TextAutoLoadingButton(
      onPressed: onPressed,
      child: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'TextAutoLoadingButton.icon',
    (AsyncCallback onPressed) => TextAutoLoadingButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
      label: const Text('Save'),
    ),
    find.text('Save'),
  ),
  _Family(
    'IconAutoLoadingButton',
    (AsyncCallback onPressed) => IconAutoLoadingButton(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
    ),
    find.byIcon(Icons.save),
  ),
  _Family(
    'IconAutoLoadingButton.filled',
    (AsyncCallback onPressed) => IconAutoLoadingButton.filled(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
    ),
    find.byIcon(Icons.save),
  ),
  _Family(
    'IconAutoLoadingButton.filledTonal',
    (AsyncCallback onPressed) => IconAutoLoadingButton.filledTonal(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
    ),
    find.byIcon(Icons.save),
  ),
  _Family(
    'IconAutoLoadingButton.outlined',
    (AsyncCallback onPressed) => IconAutoLoadingButton.outlined(
      onPressed: onPressed,
      icon: const Icon(Icons.save),
    ),
    find.byIcon(Icons.save),
  ),
];

void main() {
  for (final _Family family in _families) {
    group(family.name, () {
      testWidgets(
          'a tap shows the indicator, hides the child and disables the button '
          'until the future completes', (WidgetTester tester) async {
        final Completer<void> completer = Completer<void>();
        int calls = 0;

        await tester.pumpWidget(_host(family.build(() {
          calls++;
          return completer.future;
        })));

        expect(family.idleChild, findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(_allButtonsEnabled(tester), isTrue);

        await tester.tap(family.idleChild);
        await tester.pump();

        expect(calls, 1);
        expect(family.idleChild, findsNothing,
            reason: 'the idle child is replaced by the indicator');
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(_allButtonsEnabled(tester), isFalse,
            reason: 'a loading auto button must not accept a second press');

        completer.complete();
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(family.idleChild, findsOneWidget);
        expect(_allButtonsEnabled(tester), isTrue);
      });

      testWidgets(
          'a tap while already loading does not invoke onPressed a second time',
          (WidgetTester tester) async {
        final Completer<void> completer = Completer<void>();
        int calls = 0;

        await tester.pumpWidget(_host(family.build(() {
          calls++;
          return completer.future;
        })));

        await tester.tap(family.idleChild);
        await tester.pump();
        expect(calls, 1);

        await tester.tap(find.byType(CircularProgressIndicator),
            warnIfMissed: false);
        await tester.pump();
        expect(calls, 1, reason: 'the button is disabled while loading');

        completer.complete();
        await tester.pumpAndSettle();
      });

      testWidgets(
          'REGRESSION: an onPressed that throws restores the idle, tappable '
          'state instead of leaving a permanent spinner',
          (WidgetTester tester) async {
        final List<FlutterErrorDetails> errors = _captureFlutterErrors();
        Completer<void> completer = Completer<void>();
        int calls = 0;

        await tester.pumpWidget(_host(family.build(() {
          calls++;
          return completer.future;
        })));

        await tester.tap(family.idleChild);
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.completeError(StateError('save failed'));
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing,
            reason: 'the loading flag must be cleared on the failure path too');
        expect(family.idleChild, findsOneWidget);
        expect(_allButtonsEnabled(tester), isTrue);
        expect(errors, hasLength(1));
        expect(errors.single.exception, isA<StateError>());

        // And the button still works afterwards.
        completer = Completer<void>();
        await tester.tap(family.idleChild);
        await tester.pump();
        expect(calls, 2);
        completer.complete();
        await tester.pumpAndSettle();
      });
    });
  }

  group('AutoLoadingButtonState.doPress', () {
    testWidgets(
        'returns the identical pending future and does not re-invoke onPressed '
        'while a run is in flight', (WidgetTester tester) async {
      final GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>> key =
          GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>();
      final Completer<void> completer = Completer<void>();
      int calls = 0;

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        key: key,
        onPressed: () {
          calls++;
          return completer.future;
        },
        child: const Text('Save'),
      )));

      final Future<void> first = key.currentState!.doPress();
      final Future<void> second = key.currentState!.doPress();
      await tester.pump();

      expect(identical(first, second), isTrue,
          reason: 'the in-flight future is handed back verbatim');
      expect(calls, 1);

      completer.complete();
      await first;
      await second;
      await tester.pumpAndSettle();

      // Once settled a new press starts a fresh run.
      final Completer<void> next = Completer<void>();
      calls = 0;
      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        key: key,
        onPressed: () {
          calls++;
          return next.future;
        },
        child: const Text('Save'),
      )));
      final Future<void> third = key.currentState!.doPress();
      await tester.pump();
      expect(calls, 1);
      expect(identical(third, first), isFalse);
      next.complete();
      await third;
      await tester.pumpAndSettle();
    });

    testWidgets(
        'hands an asynchronous failure to its caller and does NOT also report '
        'it to FlutterError', (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = _captureFlutterErrors();
      final GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>> key =
          GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        key: key,
        onPressed: () async => throw StateError('boom'),
        child: const Text('Save'),
      )));

      // Attach the handler synchronously so the failure is never unobserved.
      final Future<Object?> caught = key.currentState!.doPress().then<Object?>(
            (_) => null,
            onError: (Object error) => error,
          );
      await tester.pumpAndSettle();

      expect(await caught, isA<StateError>());
      expect(errors, isEmpty,
          reason: 'an observed failure must not be double-reported');
      expect(find.text('Save'), findsOneWidget);
      expect(
          tester
              .widget<ElevatedLoadingButton>(find.byType(ElevatedLoadingButton))
              .enabled,
          isTrue);
    });

    testWidgets(
        'hands a synchronous throw from onPressed to its caller and clears the '
        'loading state', (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = _captureFlutterErrors();
      final GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>> key =
          GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        key: key,
        // Throws before ever returning a Future.
        onPressed: () => throw ArgumentError('sync boom'),
        child: const Text('Save'),
      )));

      final Future<Object?> caught = key.currentState!.doPress().then<Object?>(
            (_) => null,
            onError: (Object error) => error,
          );
      await tester.pumpAndSettle();

      expect(await caught, isA<ArgumentError>());
      expect(errors, isEmpty);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets(
        'is a no-op returning a completed future when onPressed is null',
        (WidgetTester tester) async {
      final GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>> key =
          GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        key: key,
        onPressed: null,
        child: const Text('Save'),
      )));

      await key.currentState!.doPress();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
          tester
              .widget<ElevatedLoadingButton>(find.byType(ElevatedLoadingButton))
              .enabled,
          isFalse,
          reason: 'a button with neither callback is disabled');
    });
  });

  group('AutoLoadingButtonState.doLongPress', () {
    testWidgets('a long press enters the loading state and restores the child',
        (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      int longPresses = 0;
      int presses = 0;

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        onPressed: () async => presses++,
        onLongPress: () {
          longPresses++;
          return completer.future;
        },
        child: const Text('Save'),
      )));

      await tester.longPress(find.text('Save'));
      await tester.pump();

      expect(longPresses, 1);
      expect(presses, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
          tester
              .widget<ElevatedLoadingButton>(find.byType(ElevatedLoadingButton))
              .enabled,
          isFalse);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'returns the identical pending future and does not re-invoke '
        'onLongPress while a run is in flight', (WidgetTester tester) async {
      final GlobalKey<AutoLoadingButtonState<FilledAutoLoadingButton>> key =
          GlobalKey<AutoLoadingButtonState<FilledAutoLoadingButton>>();
      final Completer<void> completer = Completer<void>();
      int calls = 0;

      await tester.pumpWidget(_host(FilledAutoLoadingButton(
        key: key,
        onPressed: null,
        onLongPress: () {
          calls++;
          return completer.future;
        },
        child: const Text('Save'),
      )));

      final Future<void> first = key.currentState!.doLongPress();
      final Future<void> second = key.currentState!.doLongPress();
      await tester.pump();

      expect(identical(first, second), isTrue);
      expect(calls, 1);

      completer.complete();
      await first;
      await tester.pumpAndSettle();
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets(
        'REGRESSION: a throwing onLongPress recovers the idle state, reports to '
        'FlutterError on the gesture path and returns the error to doLongPress '
        'callers', (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = _captureFlutterErrors();
      final GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>> key =
          GlobalKey<AutoLoadingButtonState<ElevatedAutoLoadingButton>>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        key: key,
        onPressed: null,
        onLongPress: () async => throw StateError('long boom'),
        child: const Text('Save'),
      )));

      // Gesture path: reported to FlutterError, button recovers.
      await tester.longPress(find.text('Save'));
      await tester.pumpAndSettle();

      expect(errors, hasLength(1));
      expect(errors.single.exception, isA<StateError>());
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Save'), findsOneWidget);
      expect(
          tester
              .widget<ElevatedLoadingButton>(find.byType(ElevatedLoadingButton))
              .enabled,
          isTrue);

      // Caller path: the error comes back on the future instead.
      errors.clear();
      final Future<Object?> caught =
          key.currentState!.doLongPress().then<Object?>(
                (_) => null,
                onError: (Object error) => error,
              );
      await tester.pumpAndSettle();

      expect(await caught, isA<StateError>());
      expect(errors, isEmpty);
    });
  });

  group('icon variants', () {
    testWidgets('.icon renders the icon and the label side by side',
        (WidgetTester tester) async {
      await tester.pumpWidget(_host(ElevatedAutoLoadingButton.icon(
        onPressed: () async {},
        icon: const Icon(Icons.upload),
        label: const Text('Upload'),
      )));

      expect(find.byIcon(Icons.upload), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);

      final Offset icon = tester.getCenter(find.byIcon(Icons.upload));
      final Offset label = tester.getCenter(find.text('Upload'));
      expect(icon.dx, lessThan(label.dx),
          reason: 'the icon leads the label in a Row');
      expect(icon.dy, moreOrLessEquals(label.dy, epsilon: 1));
    });

    testWidgets(
        'defaultStyleOf applies icon-scaled padding only to the .icon form',
        (WidgetTester tester) async {
      const EdgeInsetsGeometry expectedIconPadding =
          EdgeInsetsDirectional.fromSTEB(16, 0, 24, 0);
      const EdgeInsetsGeometry expectedTextIconPadding =
          EdgeInsetsDirectional.fromSTEB(12, 8, 16, 8);

      Future<EdgeInsetsGeometry?> paddingFor(Widget button, Type inner) async {
        await tester.pumpWidget(_host(button));
        return _defaultPaddingOf(tester, find.byType(inner));
      }

      final EdgeInsetsGeometry? elevatedPlain = await paddingFor(
        ElevatedAutoLoadingButton(
            onPressed: () async {}, child: const Text('Save')),
        ElevatedLoadingButton,
      );
      final EdgeInsetsGeometry? elevatedIcon = await paddingFor(
        ElevatedAutoLoadingButton.icon(
          onPressed: () async {},
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        ElevatedLoadingButton,
      );
      expect(elevatedIcon, expectedIconPadding);
      expect(elevatedPlain, isNot(elevatedIcon));

      final EdgeInsetsGeometry? filledPlain = await paddingFor(
        FilledAutoLoadingButton(
            onPressed: () async {}, child: const Text('Save')),
        FilledLoadingButton,
      );
      final EdgeInsetsGeometry? filledIcon = await paddingFor(
        FilledAutoLoadingButton.icon(
          onPressed: () async {},
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        FilledLoadingButton,
      );
      expect(filledIcon, expectedIconPadding);
      expect(filledPlain, isNot(filledIcon));

      final EdgeInsetsGeometry? outlinedPlain = await paddingFor(
        OutlinedAutoLoadingButton(
            onPressed: () async {}, child: const Text('Save')),
        OutlinedLoadingButton,
      );
      final EdgeInsetsGeometry? outlinedIcon = await paddingFor(
        OutlinedAutoLoadingButton.icon(
          onPressed: () async {},
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        OutlinedLoadingButton,
      );
      expect(outlinedIcon, expectedIconPadding);
      expect(outlinedPlain, isNot(outlinedIcon));

      final EdgeInsetsGeometry? textPlain = await paddingFor(
        TextAutoLoadingButton(
            onPressed: () async {}, child: const Text('Save')),
        TextLoadingButton,
      );
      final EdgeInsetsGeometry? textIcon = await paddingFor(
        TextAutoLoadingButton.icon(
          onPressed: () async {},
          icon: const Icon(Icons.save),
          label: const Text('Save'),
        ),
        TextLoadingButton,
      );
      expect(textIcon, expectedTextIconPadding);
      expect(textPlain, isNot(textIcon));
    });

    testWidgets(
        'the loading indicator keeps the icon padding while a .icon button is '
        'busy', (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();
      await tester.pumpWidget(_host(ElevatedAutoLoadingButton.icon(
        onPressed: () => completer.future,
        loadingLabel: const Text('Uploading'),
        icon: const Icon(Icons.upload),
        label: const Text('Upload'),
      )));

      await tester.tap(find.text('Upload'));
      await tester.pump();

      expect(
        _defaultPaddingOf(tester, find.byType(ElevatedLoadingButton)),
        const EdgeInsetsDirectional.fromSTEB(16, 0, 24, 0),
        reason: 'the loading row is still an icon+label row',
      );

      completer.complete();
      await tester.pumpAndSettle();
    });
  });

  group('loadingLabel and loadingClickable', () {
    testWidgets('loadingLabel renders beside the spinner while loading',
        (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        onPressed: () => completer.future,
        loadingLabel: const Text('Saving'),
        child: const Text('Save'),
      )));

      expect(find.text('Saving'), findsNothing);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Saving'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final Offset spinner =
          tester.getCenter(find.byType(CircularProgressIndicator));
      final Offset label = tester.getCenter(find.text('Saving'));
      expect(spinner.dx, lessThan(label.dx),
          reason: 'the spinner leads the loading label');

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.text('Saving'), findsNothing);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets(
        'loadingClickable: true keeps a loading ElevatedLoadingButton tappable',
        (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(_host(ElevatedLoadingButton(
        isLoading: true,
        loadingClickable: true,
        onPressed: () => taps++,
        child: const Text('Save'),
      )));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
          tester
              .widget<ElevatedLoadingButton>(find.byType(ElevatedLoadingButton))
              .enabled,
          isTrue);

      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets(
        'loadingClickable: false disables a loading ElevatedLoadingButton',
        (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(_host(ElevatedLoadingButton(
        isLoading: true,
        onPressed: () => taps++,
        child: const Text('Save'),
      )));

      await tester.tap(find.byType(CircularProgressIndicator),
          warnIfMissed: false);
      await tester.pump();

      expect(taps, 0);
      expect(
          tester
              .widget<ElevatedLoadingButton>(find.byType(ElevatedLoadingButton))
              .enabled,
          isFalse);
    });
  });

  group('disposal', () {
    testWidgets(
        'disposing a button mid-flight neither throws nor reports an error',
        (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = _captureFlutterErrors();
      final Completer<void> completer = Completer<void>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        onPressed: () => completer.future,
        child: const Text('Save'),
      )));

      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(_host(const Text('gone')));
      expect(find.text('gone'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(errors, isEmpty);
    });

    testWidgets(
        'disposing a button whose callback then fails reports once and does not '
        'call setState on a defunct State', (WidgetTester tester) async {
      final List<FlutterErrorDetails> errors = _captureFlutterErrors();
      final Completer<void> completer = Completer<void>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        onPressed: () => completer.future,
        child: const Text('Save'),
      )));

      await tester.tap(find.text('Save'));
      await tester.pump();

      await tester.pumpWidget(_host(const Text('gone')));
      completer.completeError(StateError('after dispose'));
      await tester.pumpAndSettle();

      expect(errors, hasLength(1));
      expect(errors.single.exception, isA<StateError>());
      expect(find.text('gone'), findsOneWidget);
    });
  });

  group('LoadingIndicator.orb', () {
    testWidgets(
        'renders a ThinkingOrb instead of a CircularProgressIndicator while '
        'loading', (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        onPressed: () => completer.future,
        indicator: const LoadingIndicator.orb(state: OrbState.searching),
        child: const Text('Ask'),
      )));

      await tester.tap(find.text('Ask'));
      // An orb animates forever, so never settle while one is mounted.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 64));

      expect(find.byType(ThinkingOrb), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.widget<ThinkingOrb>(find.byType(ThinkingOrb)).state,
          OrbState.searching);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ThinkingOrb), findsNothing);
      expect(find.text('Ask'), findsOneWidget);
    });

    testWidgets('an IconAutoLoadingButton shows an orb when asked to',
        (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();

      await tester.pumpWidget(_host(IconAutoLoadingButton(
        onPressed: () => completer.future,
        indicator: const LoadingIndicator.orb(),
        icon: const Icon(Icons.auto_awesome),
      )));

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 64));

      expect(find.byType(ThinkingOrb), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsNothing);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ThinkingOrb), findsNothing);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('loadingIcon still wins over an orb indicator',
        (WidgetTester tester) async {
      final Completer<void> completer = Completer<void>();

      await tester.pumpWidget(_host(ElevatedAutoLoadingButton(
        onPressed: () => completer.future,
        loadingIcon: const Text('...'),
        indicator: const LoadingIndicator.orb(),
        child: const Text('Ask'),
      )));

      await tester.tap(find.text('Ask'));
      await tester.pump();

      expect(find.text('...'), findsOneWidget);
      expect(find.byType(ThinkingOrb), findsNothing);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
