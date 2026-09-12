// Smoke tests for the gallery app.
//
// A note on pumping: a ThinkingOrb animates continuously, and the gallery
// mounts orbs on four of its five pages, so `pumpAndSettle()` would never
// return. Everything below drives time with explicit `pump(duration)` calls
// instead — which is the same advice the package gives its own users.

import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

void main() {
  /// A window wide enough for the navigation rail and tall enough that most
  /// sections are laid out without scrolling.
  void useLargeWindow(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Advances time in one-second steps, so periodic timers fire the way they
  /// would in a running app.
  Future<void> pumpSeconds(WidgetTester tester, int seconds) async {
    for (int i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  /// Scrolls [finder] into view, then taps it.
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  /// Switches the shell to the destination whose unselected icon is [icon].
  Future<void> goTo(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('opens on the overview page with every destination listed',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Overview'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);

    for (final String label in <String>[
      'Overview',
      'LoadingButton',
      'Auto-loading',
      'Argon',
      'Thinking orbs',
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'the $label destination should be in the rail',
      );
    }

    // The overview samples every family.
    expect(find.byType(LoadingButton), findsWidgets);
    expect(find.byType(ElevatedAutoLoadingButton), findsWidgets);
    expect(find.byType(ArgonButton), findsWidgets);
    expect(find.byType(ThinkingOrb), findsWidgets);
  });

  testWidgets('the app bar toggle flips the theme brightness',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    Brightness currentBrightness() =>
        Theme.of(tester.element(find.byType(NavigationRail))).brightness;

    expect(currentBrightness(), Brightness.light);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(currentBrightness(), Brightness.dark);
    expect(find.byIcon(Icons.light_mode), findsOneWidget);

    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(currentBrightness(), Brightness.light);
  });

  testWidgets('an overview card links through to its page',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    await scrollAndTap(
      tester,
      find.widgetWithText(TextButton, 'See every option').first,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.widgetWithText(AppBar, 'LoadingButton'), findsOneWidget);
  });

  testWidgets('a LoadingButton runs its callback and reports success',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    await goTo(tester, Icons.smart_button_outlined);

    final Finder button = find.byKey(const Key('outcome-success'));
    expect(button, findsOneWidget);
    expect(find.text('Succeeds'), findsOneWidget);

    await scrollAndTap(tester, button);

    // Loading: the callback is in flight.
    expect(find.text('Sending…'), findsOneWidget);

    // The fake work takes 1200ms.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Sent'), findsOneWidget);

    // Success is held for two seconds, then the button resets itself.
    await pumpSeconds(tester, 3);
    expect(find.text('Succeeds'), findsOneWidget);

    // Drain the snack bar onSuccess posted.
    await pumpSeconds(tester, 4);
  });

  testWidgets('the controller drives every attached button',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    await goTo(tester, Icons.smart_button_outlined);

    expect(find.byKey(const Key('controller-state')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('controller-state')),
        matching: find.text('state: idle'),
      ),
      findsOneWidget,
    );

    await scrollAndTap(tester, find.widgetWithText(OutlinedButton, 'start()'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.descendant(
        of: find.byKey(const Key('controller-state')),
        matching: find.text('state: loading'),
      ),
      findsOneWidget,
    );

    // Two buttons share the controller, so both moved.
    expect(find.text('attached to 2'), findsOneWidget);

    await scrollAndTap(tester, find.widgetWithText(OutlinedButton, 'reset()'));
    await pumpSeconds(tester, 3);
  });

  testWidgets('an auto-loading button recovers when its callback throws',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    await goTo(tester, Icons.autorenew_outlined);

    final Finder button = find.byKey(const Key('auto-throws'));
    expect(button, findsOneWidget);
    expect(find.text('Throws (recovers)'), findsOneWidget);

    await scrollAndTap(tester, button);

    // Busy: the label has been replaced by an indicator.
    expect(find.text('Throws (recovers)'), findsNothing);

    // fakeFailure throws after 900ms. With no caller awaiting doPress(), the
    // package routes the failure to FlutterError rather than dropping it.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.takeException(), isNotNull);

    // ...and the button is usable again rather than stuck spinning.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Throws (recovers)'), findsOneWidget);
  });

  testWidgets('the isLoading flag swaps every flag-driven button',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    await goTo(tester, Icons.autorenew_outlined);

    // 'Elevated' also labels a button in the auto section above, so scope the
    // search to the flag-driven row.
    Finder inFlagRow(String label) => find.descendant(
          of: find.byKey(const Key('flag-driven-demos')),
          matching: find.text(label),
        );

    expect(inFlagRow('Elevated'), findsOneWidget);

    await scrollAndTap(tester, find.byKey(const Key('is-loading-switch')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('isLoading: true'), findsOneWidget);
    // The plain labels are gone; the busy ones are in their place.
    expect(inFlagRow('Elevated'), findsNothing);
    expect(inFlagRow('Saving…'), findsOneWidget);
    expect(inFlagRow('Still tappable'), findsOneWidget);

    await scrollAndTap(tester, find.byKey(const Key('is-loading-switch')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(inFlagRow('Elevated'), findsOneWidget);
  });

  testWidgets('the orbs page shows all nine states at both tiers',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    await goTo(tester, Icons.blur_on_outlined);

    for (final OrbState state in OrbState.values) {
      expect(
        find.byKey(Key('orb-avatar-${state.name}')),
        findsOneWidget,
        reason: '${state.name} should be shown at the avatar tier',
      );
      expect(
        find.byKey(Key('orb-inline-${state.name}')),
        findsOneWidget,
        reason: '${state.name} should be shown at the inline tier',
      );
      expect(find.text(state.name), findsOneWidget);
    }

    // Nine states x two tiers, plus the three inline-with-copy samples.
    expect(find.byType(ThinkingOrb),
        findsNWidgets(OrbState.values.length * 2 + 3));

    // Orbs keep animating; pausing them must not throw or unmount anything.
    await scrollAndTap(tester, find.byKey(const Key('orb-pause-switch')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ThinkingOrb),
        findsNWidgets(OrbState.values.length * 2 + 3));
  });

  testWidgets('every page lays out without overflowing a phone-sized window',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    // Narrow windows get the bottom navigation bar instead of the rail.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    for (final IconData icon in <IconData>[
      Icons.smart_button_outlined,
      Icons.autorenew_outlined,
      Icons.swipe_left_outlined,
      Icons.blur_on_outlined,
      Icons.dashboard_outlined,
    ]) {
      await goTo(tester, icon);
      expect(
        tester.takeException(),
        isNull,
        reason: 'page behind $icon should lay out cleanly at 390px wide',
      );
      // Scroll through the whole page so sections below the fold are laid out.
      for (int i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'scrolling the page behind $icon should not overflow',
        );
      }
    }

    // Let the countdown button on the argon page finish its timer.
    await pumpSeconds(tester, 10);
  });

  testWidgets('the argon page builds and its countdown runs down',
      (WidgetTester tester) async {
    useLargeWindow(tester);
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    await goTo(tester, Icons.swipe_left_outlined);

    expect(find.byKey(const Key('argon-basic')), findsOneWidget);
    expect(find.byKey(const Key('argon-timer')), findsOneWidget);

    // One of the timer buttons starts counting down on mount; let it finish so
    // no periodic timer outlives the test.
    await pumpSeconds(tester, 10);
    expect(find.text('initialTimer: 5'), findsOneWidget);
  });
}
