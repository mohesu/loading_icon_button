import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

import '_capture.dart';

/// Regenerates the README screenshots in `doc/`.
///
/// A tool, not a test — it lives outside `test/` so `flutter test` never runs
/// it, and it is shaped like a test because rasterising needs the test
/// binding. Every image is a real render of the real widgets.
///
/// ```sh
/// flutter test tool/generate_screenshots.dart
/// tool/pack_animations.sh          # stitches the frame folders into .webp
/// ```
void main() {
  installScreenshotWriter();
  setUpAll(loadRealFonts);

  testWidgets('button-states', (WidgetTester tester) async {
    for (final Brightness brightness in Brightness.values) {
      final GlobalKey key = await pumpScene(
        tester,
        size: const Size(760, 384),
        brightness: brightness,
        child: const _StatesGrid(),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await capture(tester, key, 'doc/button-states-${brightness.name}.png');
    }
  });

  testWidgets('families', (WidgetTester tester) async {
    final GlobalKey key = await pumpScene(
      tester,
      size: const Size(760, 430),
      brightness: Brightness.light,
      child: const _FamiliesSheet(),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await capture(tester, key, 'doc/families.png');
  });

  // --- animations -------------------------------------------------------
  // Frames are written as numbered PNGs; tool/pack_animations.sh stitches
  // them into animated WebP with img2webp.

  testWidgets('hero animation frames', (WidgetTester tester) async {
    final GlobalKey key = await pumpScene(
      tester,
      size: const Size(760, 320),
      brightness: Brightness.light,
      child: const _HeroScene(),
    );
    // Let the scene settle, then start every button at once.
    await tester.pump(const Duration(milliseconds: 300));
    for (final Finder f in <Finder>[
      find.byKey(const ValueKey<String>('hero-spinner')),
      find.byKey(const ValueKey<String>('hero-orb')),
      find.byKey(const ValueKey<String>('hero-progress')),
    ]) {
      await tester.tap(f, warnIfMissed: false);
    }

    final Directory frames = framesDir('hero');
    const int frameCount = 56;
    const Duration step = Duration(milliseconds: 60);
    for (int i = 0; i < frameCount; i++) {
      await tester.pump(step);
      await capture(
        tester,
        key,
        '${frames.path}/${i.toString().padLeft(3, '0')}.png',
      );
    }
    debugPrint('>>> ${frames.path}: $frameCount frames');
    // Drain the buttons' reset timers so the test ends clean.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('orb animation frames', (WidgetTester tester) async {
    final GlobalKey key = await pumpScene(
      tester,
      size: const Size(720, 172),
      brightness: Brightness.light,
      // A decorative motion strip rather than a reference asset, and fine dot
      // fields compress badly, so it is rendered 1:1 to keep it web-sized.
      scale: 1,
      child: const _OrbStrip(),
    );

    final Directory frames = framesDir('orbs');
    const int frameCount = 48;
    const Duration step = Duration(milliseconds: 55);
    for (int i = 0; i < frameCount; i++) {
      await tester.pump(step);
      await capture(
        tester,
        key,
        '${frames.path}/${i.toString().padLeft(3, '0')}.png',
      );
    }
    debugPrint('>>> ${frames.path}: $frameCount frames');
  });
}

// ---------------------------------------------------------------- scenes

const List<String> _stateNames = <String>[
  'Idle',
  'Loading',
  'Success',
  'Error'
];

/// Every button type in every state, driven by a controller per cell so the
/// grid is deterministic rather than mid-animation.
class _StatesGrid extends StatefulWidget {
  const _StatesGrid();

  @override
  State<_StatesGrid> createState() => _StatesGridState();
}

class _StatesGridState extends State<_StatesGrid> {
  static const List<(ButtonType, String)> _types = <(ButtonType, String)>[
    (ButtonType.elevated, 'elevated'),
    (ButtonType.filled, 'filled'),
    (ButtonType.outlined, 'outlined'),
    (ButtonType.text, 'text'),
  ];

  late final Map<ActionState, LoadingButtonController> _controllers =
      <ActionState, LoadingButtonController>{
    for (final ActionState s in <ActionState>[
      ActionState.idle,
      ActionState.loading,
      ActionState.success,
      ActionState.error,
    ])
      s: LoadingButtonController(value: LoadingButtonValue(state: s)),
  };

  @override
  void dispose() {
    for (final LoadingButtonController c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle head = Theme.of(context).textTheme.labelMedium!.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        );
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: 78),
              for (final String name in _stateNames)
                Expanded(child: Center(child: Text(name, style: head))),
            ],
          ),
          const SizedBox(height: 10),
          for (final (ButtonType type, String label) in _types)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 78, child: Text(label, style: head)),
                  for (final ActionState state in _controllers.keys)
                    Expanded(
                      child: Center(
                        child: LoadingButton(
                          type: type,
                          controller: _controllers[state],
                          sizing: const LoadingButtonSizing.fixed(
                            width: 124,
                            height: 42,
                          ),
                          colorStrategy: LoadingButtonColorStrategy.material3,
                          // Traffic-light success/error, plus a soft container
                          // while loading so a working button does not read as
                          // a disabled one.
                          colors: LoadingButtonColors.traffic(
                            Theme.of(context).brightness,
                          ).copyWith(
                            loading: scheme.primaryContainer,
                            onLoading: scheme.onPrimaryContainer,
                          ),
                          resetAfterDuration: false,
                          onPressed: () async {},
                          child: const Text('Submit'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One row per button family, in its resting state.
class _FamiliesSheet extends StatelessWidget {
  const _FamiliesSheet();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Widget row(String title, String subtitle, Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title,
                        style: theme.textTheme.titleSmall!
                            .copyWith(fontWeight: FontWeight.w500)),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: child)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          row(
            'LoadingButton',
            'Its own state machine, plus a controller',
            LoadingButton(
              sizing: const LoadingButtonSizing.intrinsic(),
              colorStrategy: LoadingButtonColorStrategy.material3,
              onPressed: () async {},
              child: const Text('Submit order'),
            ),
          ),
          row(
            'ElevatedAutoLoadingButton',
            'Loading for as long as the callback runs',
            ElevatedAutoLoadingButton.icon(
              onPressed: () async {},
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Upload'),
            ),
          ),
          row(
            'FilledAutoLoadingButton.tonal',
            'Every Material variant is covered',
            FilledAutoLoadingButton.tonal(
              onPressed: () async {},
              child: const Text('Sync now'),
            ),
          ),
          row(
            'IconAutoLoadingButton.filled',
            'Icon buttons too',
            IconAutoLoadingButton.filled(
              onPressed: () async {},
              icon: const Icon(Icons.favorite_border),
            ),
          ),
          row(
            'ArgonButton',
            'Collapses into its own loader',
            ArgonButton(
              height: 42,
              width: 190,
              borderRadius: 21,
              color: theme.colorScheme.primary,
              loader: const ThinkingOrb(
                state: OrbState.working,
                size: 26,
                theme: OrbTheme.dark,
              ),
              onTap: (Function start, Function stop, ArgonButtonState state) {},
              child: Text(
                'Continue',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The animated hero: three buttons mid-flight, orbs underneath.
///
/// Each button keeps its label while loading by supplying a `loadingWidget`
/// of indicator + text, which is what a real app does and what makes the
/// still frames readable.
class _HeroScene extends StatefulWidget {
  const _HeroScene();

  @override
  State<_HeroScene> createState() => _HeroSceneState();
}

class _HeroSceneState extends State<_HeroScene> {
  final LoadingButtonController _upload = LoadingButtonController();

  @override
  void dispose() {
    _upload.dispose();
    super.dispose();
  }

  Future<void> _fakeUpload() async {
    for (int i = 1; i <= 24; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
      if (!mounted) return;
      _upload.setProgress(i / 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // Explicit state colours so a working button stays vivid instead of
    // falling back to Material's disabled palette while it is busy.
    LoadingButtonColors colors(Color container, Color onContainer) =>
        LoadingButtonColors(
          loading: container,
          onLoading: onContainer,
          success: const Color(0xFF2E7D32),
          onSuccess: Colors.white,
          error: const Color(0xFFD32F2F),
          onError: Colors.white,
        );

    Widget label(Widget indicator, String text, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            indicator,
            const SizedBox(width: 9),
            Text(text, style: TextStyle(color: color, fontSize: 14.5)),
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: <Widget>[
              LoadingButton(
                key: const ValueKey<String>('hero-spinner'),
                type: ButtonType.filled,
                sizing: const LoadingButtonSizing.fixed(width: 196, height: 48),
                colorStrategy: LoadingButtonColorStrategy.material3,
                colors: colors(scheme.primary, scheme.onPrimary),
                loadingWidget: label(
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  ),
                  'Signing in…',
                  scheme.onPrimary,
                ),
                successWidget: label(
                  const Icon(Icons.check, size: 18, color: Colors.white),
                  'Signed in',
                  Colors.white,
                ),
                onPressed: () =>
                    Future<void>.delayed(const Duration(milliseconds: 1500)),
                child: const Text('Sign in'),
              ),
              LoadingButton(
                key: const ValueKey<String>('hero-orb'),
                type: ButtonType.filled,
                sizing: const LoadingButtonSizing.fixed(width: 196, height: 48),
                colorStrategy: LoadingButtonColorStrategy.material3,
                colors: colors(
                  scheme.tertiaryContainer,
                  scheme.onTertiaryContainer,
                ),
                loadingWidget: label(
                  ThinkingOrb(
                    state: OrbState.searching,
                    size: 22,
                    color: scheme.onTertiaryContainer,
                  ),
                  'Searching…',
                  scheme.onTertiaryContainer,
                ),
                successWidget: label(
                  const Icon(Icons.check, size: 18, color: Colors.white),
                  'Found it',
                  Colors.white,
                ),
                onPressed: () =>
                    Future<void>.delayed(const Duration(milliseconds: 2100)),
                child: const Text('Ask the agent'),
              ),
              LoadingButton(
                key: const ValueKey<String>('hero-progress'),
                type: ButtonType.filled,
                controller: _upload,
                sizing: const LoadingButtonSizing.fixed(width: 196, height: 48),
                colorStrategy: LoadingButtonColorStrategy.material3,
                colors: colors(
                  scheme.secondaryContainer,
                  scheme.onSecondaryContainer,
                ),
                progressStyle: LoadingProgressStyle.both,
                loadingWidget: ValueListenableBuilder<LoadingButtonValue>(
                  valueListenable: _upload,
                  builder: (BuildContext context, LoadingButtonValue v, _) {
                    final int percent = ((v.progress ?? 0) * 100).round();
                    return label(
                      SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          value: v.progress,
                          strokeWidth: 2,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                      'Uploading $percent%',
                      scheme.onSecondaryContainer,
                    );
                  },
                ),
                successWidget: label(
                  const Icon(Icons.check, size: 18, color: Colors.white),
                  'Uploaded',
                  Colors.white,
                ),
                onPressed: _fakeUpload,
                child: const Text('Upload file'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Nine thinking-orb states for AI and agent interfaces',
            style: theme.textTheme.bodySmall!.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 22,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final OrbState state in OrbState.values)
                ThinkingOrb(state: state, size: 48),
            ],
          ),
        ],
      ),
    );
  }
}

/// All nine orbs, animating, at the avatar tuning.
class _OrbStrip extends StatelessWidget {
  const _OrbStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Wrap(
        spacing: 12,
        alignment: WrapAlignment.center,
        children: <Widget>[
          for (final OrbState state in OrbState.values)
            ThinkingOrb(state: state, size: 64),
        ],
      ),
    );
  }
}
