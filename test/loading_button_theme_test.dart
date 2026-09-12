import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

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

const Color _primary = Color(0xFF123456);

ThemeData _appTheme({List<ThemeExtension<dynamic>> extensions = const []}) =>
    ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      primaryColor: _primary,
      extensions: extensions,
    );

/// Pumps a [LoadingButton] under an optional [ThemeExtension] and an optional
/// [LoadingButtonTheme] widget, so resolution order can be exercised.
Future<void> _pumpThemedButton(
  WidgetTester tester, {
  LoadingButtonThemeData? extension,
  LoadingButtonThemeData? widgetTheme,
  LoadingButtonController? controller,
  LoadingButtonColorStrategy? colorStrategy,
  bool resetAfterDuration = false,
}) {
  final Widget button = LoadingButton(
    controller: controller,
    onPressed: () async {},
    colorStrategy: colorStrategy,
    resetAfterDuration: resetAfterDuration,
    enableHapticFeedback: false,
    child: const Text('Go'),
  );
  return tester.pumpWidget(
    MaterialApp(
      theme: _appTheme(
        extensions: <ThemeExtension<dynamic>>[
          if (extension != null) extension,
        ],
      ),
      home: Scaffold(
        body: Center(
          child: widgetTheme == null
              ? button
              : LoadingButtonTheme(data: widgetTheme, child: button),
        ),
      ),
    ),
  );
}

/// The colour actually painted behind the button's label.
Color? _paintedBackground(WidgetTester tester) => tester
    .widget<Material>(
      find
          .descendant(
            of: find.byType(ElevatedButton),
            matching: find.byType(Material),
          )
          .first,
    )
    .color;

/// Counts its own builds, so a test can tell an inherited-widget notification
/// from an ordinary parent rebuild.
class _ThemeProbe extends StatelessWidget {
  const _ThemeProbe();

  static int builds = 0;
  static LoadingButtonThemeData? seen;

  static void reset() {
    builds = 0;
    seen = null;
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    seen = LoadingButtonThemeData.of(context);
    return const SizedBox.shrink();
  }
}

void main() {
  group('LoadingButtonThemeData.of resolution order', () {
    testWidgets('the LoadingButtonTheme widget beats the ThemeExtension',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await _pumpThemedButton(
        tester,
        controller: controller,
        extension: const LoadingButtonThemeData(
          indicator: LoadingIndicator.widget(Text('from-extension')),
        ),
        widgetTheme: const LoadingButtonThemeData(
          indicator: LoadingIndicator.widget(Text('from-widget')),
        ),
      );

      controller.start();
      await _swap(tester);

      expect(find.text('from-widget'), findsOneWidget);
      expect(find.text('from-extension'), findsNothing);
    });

    testWidgets('the ThemeExtension is used when there is no widget theme',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await _pumpThemedButton(
        tester,
        controller: controller,
        extension: const LoadingButtonThemeData(
          indicator: LoadingIndicator.widget(Text('from-extension')),
        ),
      );

      controller.start();
      await _swap(tester);

      expect(find.text('from-extension'), findsOneWidget);
    });

    testWidgets('with neither, the button falls back to the default spinner',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await _pumpThemedButton(tester, controller: controller);

      controller.start();
      await _swap(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('from-widget'), findsNothing);
      expect(find.text('from-extension'), findsNothing);
    });

    testWidgets('an empty widget theme shadows the ThemeExtension entirely',
        (WidgetTester tester) async {
      // Resolution stops at the nearest LoadingButtonTheme; it does not merge
      // field by field with the extension underneath it.
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await _pumpThemedButton(
        tester,
        controller: controller,
        extension: const LoadingButtonThemeData(
          indicator: LoadingIndicator.widget(Text('from-extension')),
        ),
        widgetTheme: const LoadingButtonThemeData(),
      );

      controller.start();
      await _swap(tester);

      expect(find.text('from-extension'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('the nearest of two nested widget themes wins',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButtonTheme(
              data: const LoadingButtonThemeData(
                indicator: LoadingIndicator.widget(Text('outer')),
              ),
              child: LoadingButtonTheme(
                data: const LoadingButtonThemeData(
                  indicator: LoadingIndicator.widget(Text('inner')),
                ),
                child: LoadingButton(
                  controller: controller,
                  onPressed: () async {},
                  resetAfterDuration: false,
                  enableHapticFeedback: false,
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await _swap(tester);

      expect(find.text('inner'), findsOneWidget);
      expect(find.text('outer'), findsNothing);
    });

    testWidgets('of() returns an empty instance when nothing is installed',
        (WidgetTester tester) async {
      _ThemeProbe.reset();
      await tester.pumpWidget(const MaterialApp(home: _ThemeProbe()));

      expect(_ThemeProbe.seen, isNotNull);
      expect(_ThemeProbe.seen, const LoadingButtonThemeData());
      expect(_ThemeProbe.seen!.indicator, isNull);
      expect(_ThemeProbe.seen!.animationDuration, isNull);
    });

    testWidgets('maybeOf returns null without a theme and the data with one',
        (WidgetTester tester) async {
      LoadingButtonThemeData? outside;
      LoadingButtonThemeData? inside;
      const LoadingButtonThemeData data = LoadingButtonThemeData(
        cooldown: Duration(seconds: 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              outside = LoadingButtonTheme.maybeOf(context);
              return LoadingButtonTheme(
                data: data,
                child: Builder(
                  builder: (BuildContext context) {
                    inside = LoadingButtonTheme.maybeOf(context);
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(outside, isNull);
      expect(inside, same(data));
    });
  });

  group('a real LoadingButton reads its defaults from the theme', () {
    testWidgets('theme successDuration governs when success resets to idle',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await _pumpThemedButton(
        tester,
        controller: controller,
        // Five seconds, well past the 2s package default: if the default were
        // still in force the button would have reset long before the last
        // assertion below.
        widgetTheme: const LoadingButtonThemeData(
          successDuration: Duration(seconds: 5),
        ),
        resetAfterDuration: true,
      );

      controller.success();
      await _swap(tester);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      expect(find.byIcon(Icons.check), findsOneWidget,
          reason: 'the 2s default must not be what is in force');

      await tester.pump(const Duration(seconds: 3));
      await _swap(tester);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.text('Go'), findsOneWidget);
      expect(controller.state, ActionState.idle);
    });

    testWidgets('theme errorDuration governs when error resets to idle',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await _pumpThemedButton(
        tester,
        controller: controller,
        widgetTheme: const LoadingButtonThemeData(
          errorDuration: Duration(seconds: 6),
        ),
        resetAfterDuration: true,
      );

      controller.error('bad');
      await _swap(tester);
      expect(find.byIcon(Icons.error), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.byIcon(Icons.error), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await _swap(tester);
      expect(find.text('Go'), findsOneWidget);
      expect(controller.state, ActionState.idle);
    });

    testWidgets('theme animationDuration drives the cross-fade',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await _pumpThemedButton(
        tester,
        controller: controller,
        widgetTheme: const LoadingButtonThemeData(
          animationDuration: Duration(seconds: 1),
        ),
      );

      expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        const Duration(seconds: 1),
      );

      controller.start();
      await tester.pump();
      // Half way through a one-second cross-fade both children are on screen;
      // under the 300ms default the swap would already be over.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Go'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _swap(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Go'), findsNothing);
    });

    testWidgets('theme sizing decides the box the button is laid out in',
        (WidgetTester tester) async {
      await _pumpThemedButton(
        tester,
        widgetTheme: const LoadingButtonThemeData(
          sizing: LoadingButtonSizing.fixed(width: 123, height: 45),
        ),
      );

      expect(
        tester.getSize(find.byType(ElevatedButton)),
        const Size(123, 45),
      );
    });

    testWidgets('theme colors win over the colour strategy',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await _pumpThemedButton(
        tester,
        controller: controller,
        colorStrategy: LoadingButtonColorStrategy.material3,
        widgetTheme: const LoadingButtonThemeData(
          colors: LoadingButtonColors(success: Color(0xFF00FF00)),
        ),
      );

      controller.success();
      await _swap(tester);
      expect(_paintedBackground(tester), const Color(0xFF00FF00));
    });

    testWidgets('a widget argument still wins over the theme',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButtonTheme(
              data: const LoadingButtonThemeData(
                indicator: LoadingIndicator.widget(Text('from-theme')),
              ),
              child: LoadingButton(
                controller: controller,
                onPressed: () async {},
                indicator: const LoadingIndicator.widget(Text('from-widget')),
                resetAfterDuration: false,
                enableHapticFeedback: false,
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await _swap(tester);
      expect(find.text('from-widget'), findsOneWidget);
      expect(find.text('from-theme'), findsNothing);
    });
  });

  group('LoadingButtonTheme rebuilds its dependents', () {
    Widget app(LoadingButtonThemeData data) => MaterialApp(
          home: LoadingButtonTheme(data: data, child: const _ThemeProbe()),
        );

    testWidgets('a changed data rebuilds descendants; an equal one does not',
        (WidgetTester tester) async {
      _ThemeProbe.reset();

      final LoadingButtonThemeData first = LoadingButtonThemeData(
        animationDuration: const Duration(milliseconds: 100),
      );
      // Equal by value, but a different instance: updateShouldNotify must
      // compare with ==, not identical().
      final LoadingButtonThemeData sameAgain = LoadingButtonThemeData(
        animationDuration: const Duration(milliseconds: 100),
      );
      final LoadingButtonThemeData changed = LoadingButtonThemeData(
        animationDuration: const Duration(milliseconds: 900),
      );

      await tester.pumpWidget(app(first));
      expect(_ThemeProbe.builds, 1);
      expect(_ThemeProbe.seen, first);

      await tester.pumpWidget(app(sameAgain));
      expect(_ThemeProbe.builds, 1,
          reason: 'equal data must not notify dependents');

      await tester.pumpWidget(app(changed));
      expect(_ThemeProbe.builds, 2);
      expect(_ThemeProbe.seen, changed);
      expect(
        _ThemeProbe.seen!.animationDuration,
        const Duration(milliseconds: 900),
      );
    });

    testWidgets('updateShouldNotify is false for equal data and true otherwise',
        (WidgetTester tester) async {
      const LoadingButtonTheme a = LoadingButtonTheme(
        data: LoadingButtonThemeData(cooldown: Duration(seconds: 1)),
        child: SizedBox.shrink(),
      );
      const LoadingButtonTheme sameAgain = LoadingButtonTheme(
        data: LoadingButtonThemeData(cooldown: Duration(seconds: 1)),
        child: SizedBox.shrink(),
      );
      const LoadingButtonTheme different = LoadingButtonTheme(
        data: LoadingButtonThemeData(cooldown: Duration(seconds: 2)),
        child: SizedBox.shrink(),
      );

      expect(sameAgain.updateShouldNotify(a), isFalse);
      expect(different.updateShouldNotify(a), isTrue);
    });
  });

  group('LoadingButtonThemeData value semantics', () {
    const LoadingIndicator indicator = LoadingIndicator.orb();
    const Widget success = Icon(Icons.done);
    const Widget error = Icon(Icons.warning);
    const LoadingButtonColors colors = LoadingButtonColors(
      success: Color(0xFF00FF00),
    );

    LoadingButtonThemeData full() => const LoadingButtonThemeData(
          indicator: indicator,
          successWidget: success,
          errorWidget: error,
          sizing: LoadingButtonSizing.expand(height: 40),
          colors: colors,
          colorStrategy: LoadingButtonColorStrategy.material3,
          animationDuration: Duration(milliseconds: 111),
          successDuration: Duration(milliseconds: 222),
          errorDuration: Duration(milliseconds: 333),
          enableHapticFeedback: false,
          progressStyle: LoadingProgressStyle.fill,
          debounce: Duration(milliseconds: 444),
          cooldown: Duration(milliseconds: 555),
        );

    test('every field survives copyWith when nothing is overridden', () {
      final LoadingButtonThemeData copy = full().copyWith();
      expect(copy, full());
      expect(copy.indicator, same(indicator));
      expect(copy.successWidget, same(success));
      expect(copy.errorWidget, same(error));
      expect(copy.colors, colors);
      expect(copy.colorStrategy, LoadingButtonColorStrategy.material3);
      expect(copy.animationDuration, const Duration(milliseconds: 111));
      expect(copy.successDuration, const Duration(milliseconds: 222));
      expect(copy.errorDuration, const Duration(milliseconds: 333));
      expect(copy.enableHapticFeedback, isFalse);
      expect(copy.progressStyle, LoadingProgressStyle.fill);
      expect(copy.debounce, const Duration(milliseconds: 444));
      expect(copy.cooldown, const Duration(milliseconds: 555));
    });

    test('copyWith replaces only the fields it is given', () {
      final LoadingButtonThemeData copy = full().copyWith(
        animationDuration: const Duration(seconds: 9),
        progressStyle: LoadingProgressStyle.both,
      );
      expect(copy.animationDuration, const Duration(seconds: 9));
      expect(copy.progressStyle, LoadingProgressStyle.both);
      // Untouched fields are carried over.
      expect(copy.successDuration, const Duration(milliseconds: 222));
      expect(copy.indicator, same(indicator));
      expect(copy, isNot(full()));
    });

    test('copyWith fills empty fields on an otherwise empty instance', () {
      const LoadingButtonThemeData empty = LoadingButtonThemeData();
      final LoadingButtonThemeData copy = empty.copyWith(
        cooldown: const Duration(seconds: 2),
      );
      expect(copy.cooldown, const Duration(seconds: 2));
      expect(copy.indicator, isNull);
      expect(copy.animationDuration, isNull);
    });

    test('instances with identical fields are equal and share a hashCode', () {
      expect(full(), equals(full()));
      expect(full().hashCode, equals(full().hashCode));
      expect(
        const LoadingButtonThemeData(),
        equals(const LoadingButtonThemeData()),
      );
    });

    test('a difference in any single field breaks equality', () {
      final LoadingButtonThemeData base = full();
      expect(
          base,
          isNot(base.copyWith(
              indicator: const LoadingIndicator.circular(strokeWidth: 9))));
      expect(base, isNot(base.copyWith(successWidget: const Icon(Icons.add))));
      expect(base, isNot(base.copyWith(errorWidget: const Icon(Icons.add))));
      expect(
        base,
        isNot(base.copyWith(sizing: const LoadingButtonSizing.intrinsic())),
      );
      expect(
        base,
        isNot(base.copyWith(
          colors: const LoadingButtonColors(success: Color(0xFF0000FF)),
        )),
      );
      expect(
        base,
        isNot(base.copyWith(
          colorStrategy: LoadingButtonColorStrategy.legacy,
        )),
      );
      expect(base, isNot(base.copyWith(animationDuration: Duration.zero)));
      expect(base, isNot(base.copyWith(successDuration: Duration.zero)));
      expect(base, isNot(base.copyWith(errorDuration: Duration.zero)));
      expect(base, isNot(base.copyWith(enableHapticFeedback: true)));
      expect(
        base,
        isNot(base.copyWith(progressStyle: LoadingProgressStyle.indicator)),
      );
      expect(base, isNot(base.copyWith(debounce: Duration.zero)));
      expect(base, isNot(base.copyWith(cooldown: Duration.zero)));
      expect(base, isNot(const LoadingButtonThemeData()));
    });
  });

  group('LoadingButtonThemeData.lerp', () {
    const LoadingIndicator fromIndicator = LoadingIndicator.circular();
    const LoadingIndicator toIndicator = LoadingIndicator.orb();

    LoadingButtonThemeData from() => const LoadingButtonThemeData(
          indicator: fromIndicator,
          successWidget: Icon(Icons.done),
          sizing: LoadingButtonSizing.legacy,
          colorStrategy: LoadingButtonColorStrategy.legacy,
          animationDuration: Duration(milliseconds: 100),
          successDuration: Duration(milliseconds: 100),
          errorDuration: Duration(milliseconds: 100),
          enableHapticFeedback: true,
          progressStyle: LoadingProgressStyle.indicator,
          debounce: Duration(milliseconds: 100),
          cooldown: Duration(milliseconds: 100),
          colors: LoadingButtonColors(
            success: Color(0xFF000000),
            error: Color(0xFF000000),
          ),
        );

    LoadingButtonThemeData to() => const LoadingButtonThemeData(
          indicator: toIndicator,
          successWidget: Icon(Icons.warning),
          sizing: LoadingButtonSizing.intrinsic(),
          colorStrategy: LoadingButtonColorStrategy.material3,
          animationDuration: Duration(milliseconds: 900),
          successDuration: Duration(milliseconds: 900),
          errorDuration: Duration(milliseconds: 900),
          enableHapticFeedback: false,
          progressStyle: LoadingProgressStyle.fill,
          debounce: Duration(milliseconds: 900),
          cooldown: Duration(milliseconds: 900),
          colors: LoadingButtonColors(
            success: Color(0xFFFFFFFF),
            error: Color(0xFFFFFFFF),
          ),
        );

    test('non-interpolable fields still hold this side just below t=0.5', () {
      final LoadingButtonThemeData mid = from().lerp(to(), 0.49);
      expect(mid.indicator, same(fromIndicator));
      expect(
          mid.successWidget,
          isA<Icon>().having(
            (Icon i) => i.icon,
            'icon',
            Icons.done,
          ));
      expect(mid.sizing, LoadingButtonSizing.legacy);
      expect(mid.colorStrategy, LoadingButtonColorStrategy.legacy);
      expect(mid.animationDuration, const Duration(milliseconds: 100));
      expect(mid.successDuration, const Duration(milliseconds: 100));
      expect(mid.errorDuration, const Duration(milliseconds: 100));
      expect(mid.enableHapticFeedback, isTrue);
      expect(mid.progressStyle, LoadingProgressStyle.indicator);
      expect(mid.debounce, const Duration(milliseconds: 100));
      expect(mid.cooldown, const Duration(milliseconds: 100));
    });

    test('non-interpolable fields snap to the other side at t=0.5', () {
      final LoadingButtonThemeData mid = from().lerp(to(), 0.5);
      expect(mid.indicator, same(toIndicator));
      expect(
          mid.successWidget,
          isA<Icon>().having(
            (Icon i) => i.icon,
            'icon',
            Icons.warning,
          ));
      expect(mid.sizing, isA<LoadingButtonSizing>());
      expect(mid.sizing, isNot(LoadingButtonSizing.legacy));
      expect(mid.colorStrategy, LoadingButtonColorStrategy.material3);
      expect(mid.animationDuration, const Duration(milliseconds: 900));
      expect(mid.successDuration, const Duration(milliseconds: 900));
      expect(mid.errorDuration, const Duration(milliseconds: 900));
      expect(mid.enableHapticFeedback, isFalse);
      expect(mid.progressStyle, LoadingProgressStyle.fill);
      expect(mid.debounce, const Duration(milliseconds: 900));
      expect(mid.cooldown, const Duration(milliseconds: 900));
    });

    test('colours are interpolated rather than snapped', () {
      final LoadingButtonThemeData mid = from().lerp(to(), 0.5);
      final Color? success = mid.colors!.success;
      expect(success, isNot(const Color(0xFF000000)));
      expect(success, isNot(const Color(0xFFFFFFFF)));
      expect(
        success,
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
      expect(
        mid.colors!.error,
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
      // A quarter of the way is a quarter of the way, not a snap.
      expect(
        from().lerp(to(), 0.25).colors!.success,
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.25),
      );
    });

    test('t=0 and t=1 reproduce the endpoints', () {
      expect(from().lerp(to(), 0), from());
      expect(from().lerp(to(), 1), to());
    });

    test('lerping with null colours on both sides yields null colours', () {
      const LoadingButtonThemeData a = LoadingButtonThemeData(
        animationDuration: Duration(milliseconds: 100),
      );
      const LoadingButtonThemeData b = LoadingButtonThemeData(
        animationDuration: Duration(milliseconds: 900),
      );
      expect(a.lerp(b, 0.5).colors, isNull);
    });

    test('lerp returns this when the other side is not the same extension', () {
      final LoadingButtonThemeData a = from();
      expect(a.lerp(null, 0.5), same(a));
    });

    testWidgets('a ThemeData animation lerps the extension',
        (WidgetTester tester) async {
      // ThemeData.lerp drives ThemeExtension.lerp; this proves the extension is
      // registered and reachable through the Theme, not just callable directly.
      final ThemeData lerped = ThemeData.lerp(
        _appTheme(extensions: <ThemeExtension<dynamic>>[from()]),
        _appTheme(extensions: <ThemeExtension<dynamic>>[to()]),
        0.5,
      );
      final LoadingButtonThemeData? data =
          lerped.extension<LoadingButtonThemeData>();
      expect(data, isNotNull);
      expect(data!.animationDuration, const Duration(milliseconds: 900));
      expect(
        data.colors!.success,
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
    });
  });

  group('LoadingButtonColors', () {
    test('fromScheme maps success and error onto container role pairs', () {
      final ColorScheme scheme =
          ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
      final LoadingButtonColors colors = LoadingButtonColors.fromScheme(scheme);

      expect(colors.success, scheme.tertiaryContainer);
      expect(colors.onSuccess, scheme.onTertiaryContainer);
      expect(colors.error, scheme.errorContainer);
      expect(colors.onError, scheme.onErrorContainer);
      // Loading is left to the button's own ButtonStyle.
      expect(colors.loading, isNull);
      expect(colors.onLoading, isNull);
    });

    test('fromScheme follows the brightness of the scheme it is given', () {
      final ColorScheme light = ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
      );
      final ColorScheme dark = ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      );
      expect(
        LoadingButtonColors.fromScheme(light).success,
        isNot(LoadingButtonColors.fromScheme(dark).success),
      );
      expect(
          LoadingButtonColors.fromScheme(dark).success, dark.tertiaryContainer);
    });

    test('traffic uses the documented light tones', () {
      final LoadingButtonColors colors =
          LoadingButtonColors.traffic(Brightness.light);
      expect(colors.success, const Color(0xFF2E7D32));
      expect(colors.error, const Color(0xFFD32F2F));
      expect(colors.onSuccess, Colors.white);
      expect(colors.onError, Colors.white);
      expect(colors.loading, isNull);
    });

    test('traffic uses the documented darker tones in dark mode', () {
      final LoadingButtonColors colors =
          LoadingButtonColors.traffic(Brightness.dark);
      expect(colors.success, const Color(0xFF1B5E20));
      expect(colors.error, const Color(0xFFB3261E));
      expect(colors.onSuccess, Colors.white);
      expect(colors.onError, Colors.white);
    });

    test('legacy is exactly the pre-1.1.0 green, red and white', () {
      const LoadingButtonColors colors = LoadingButtonColors.legacy;
      expect(colors.success, Colors.green);
      expect(colors.error, Colors.red);
      expect(colors.onSuccess, Colors.white);
      expect(colors.onError, Colors.white);
      expect(colors.loading, isNull);
      expect(colors.onLoading, isNull);
    });

    test('copyWith replaces only the fields it is given', () {
      final LoadingButtonColors copy = LoadingButtonColors.legacy.copyWith(
        loading: const Color(0xFF010203),
      );
      expect(copy.loading, const Color(0xFF010203));
      expect(copy.success, Colors.green);
      expect(copy.error, Colors.red);
    });

    test('equality and hashCode are by value', () {
      const LoadingButtonColors a = LoadingButtonColors(
        success: Color(0xFF00FF00),
        onSuccess: Color(0xFFFFFFFF),
      );
      const LoadingButtonColors b = LoadingButtonColors(
        success: Color(0xFF00FF00),
        onSuccess: Color(0xFFFFFFFF),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(const LoadingButtonColors(success: Color(0xFF00FF00))));
    });
  });

  group('LoadingButtonColorStrategy changes the painted background', () {
    testWidgets('legacy paints primaryColor while idle',
        (WidgetTester tester) async {
      await _pumpThemedButton(
        tester,
        colorStrategy: LoadingButtonColorStrategy.legacy,
      );
      expect(_paintedBackground(tester), _primary);
    });

    testWidgets('material3 leaves the idle background to the ButtonStyle',
        (WidgetTester tester) async {
      await _pumpThemedButton(
        tester,
        colorStrategy: LoadingButtonColorStrategy.material3,
      );

      final Color? painted = _paintedBackground(tester);
      expect(painted, isNot(_primary));
      expect(
        tester
            .widget<ElevatedButton>(find.byType(ElevatedButton))
            .style
            ?.backgroundColor,
        isNull,
        reason: 'material3 must not override the button\'s own background',
      );
    });

    testWidgets('legacy paints green on success and red on error',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      await _pumpThemedButton(
        tester,
        controller: controller,
        colorStrategy: LoadingButtonColorStrategy.legacy,
      );

      controller.success();
      await _swap(tester);
      expect(_paintedBackground(tester), Colors.green);

      controller.error('bad');
      await _swap(tester);
      expect(_paintedBackground(tester), Colors.red);
    });

    testWidgets('material3 paints the scheme container roles instead',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      await _pumpThemedButton(
        tester,
        controller: controller,
        colorStrategy: LoadingButtonColorStrategy.material3,
      );

      final ColorScheme scheme = _appTheme().colorScheme;

      controller.success();
      await _swap(tester);
      expect(_paintedBackground(tester), scheme.tertiaryContainer);
      expect(_paintedBackground(tester), isNot(Colors.green));

      controller.error('bad');
      await _swap(tester);
      expect(_paintedBackground(tester), scheme.errorContainer);
      expect(_paintedBackground(tester), isNot(Colors.red));
    });

    testWidgets('the strategy can be set for a whole subtree from the theme',
        (WidgetTester tester) async {
      final LoadingButtonController controller = LoadingButtonController();
      addTearDown(controller.dispose);
      await _pumpThemedButton(
        tester,
        controller: controller,
        widgetTheme: const LoadingButtonThemeData(
          colorStrategy: LoadingButtonColorStrategy.material3,
        ),
      );

      controller.success();
      await _swap(tester);
      expect(_paintedBackground(tester),
          _appTheme().colorScheme.tertiaryContainer);
    });
  });
}
