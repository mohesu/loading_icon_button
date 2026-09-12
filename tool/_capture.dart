import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared rasterising helpers for the tools in this directory.
///
/// `flutter_test` substitutes a placeholder font that paints every glyph as a
/// filled box, so screenshots need the real Roboto and MaterialIcons faces
/// loaded first. Both ship inside the Flutter SDK, which is located from
/// `Platform.resolvedExecutable` so this works on any machine.
const String _fontsRelative = 'artifacts/material_fonts';

/// Loads Roboto and MaterialIcons so rendered text and icons are real glyphs.
///
/// Initialises the binding itself: called from `setUpAll`, `FontLoader.load`
/// needs a binding that the first `testWidgets` has not created yet.
Future<void> loadRealFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Directory fonts = _materialFontsDir();

  Future<void> load(String family, List<String> files) async {
    final FontLoader loader = FontLoader(family);
    for (final String file in files) {
      final File f = File('${fonts.path}/$file');
      if (!f.existsSync()) throw StateError('font not found: ${f.path}');
      loader.addFont(
        Future<ByteData>.value(ByteData.sublistView(f.readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Roboto', <String>['Roboto-Regular.ttf', 'Roboto-Medium.ttf']);
  await load('MaterialIcons', <String>['MaterialIcons-Regular.otf']);
}

Directory _materialFontsDir() {
  // .../flutter/bin/cache/dart-sdk/bin/dart -> .../flutter/bin/cache
  Directory dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path) {
    final Directory candidate = Directory('${dir.path}/$_fontsRelative');
    if (candidate.existsSync()) return candidate;
    dir = dir.parent;
  }
  throw StateError(
    'Could not find $_fontsRelative above ${Platform.resolvedExecutable}',
  );
}

/// Pumps [child] inside a captureable boundary at a fixed logical size, and
/// returns the key to hand to [capture].
///
/// A FRESH key per scene: reusing one [GlobalKey] across successive
/// `pumpWidget` calls makes the framework try to re-parent the old boundary
/// into the new tree, which hangs instead of failing.
///
/// [scale] renders the scene larger than its logical [size]. The golden
/// pipeline always rasterises at 1x no matter what `devicePixelRatio` is set
/// to, so a bigger viewport plus a paint-time [Transform.scale] is what gets a
/// crisp image — the transform applies before rasterisation, so text and dots
/// stay sharp rather than being a scaled-up bitmap.
Future<GlobalKey> pumpScene(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required Brightness brightness,
  Color? background,
  double scale = 2,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size * scale;
  addTearDown(tester.view.reset);

  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4F46E5),
    brightness: brightness,
  );
  final GlobalKey key = GlobalKey();

  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: scheme,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: Scaffold(
          backgroundColor: background ?? scheme.surface,
          body: Center(
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return key;
}

/// Installs the comparator that makes [capture] write files.
///
/// Rasterising goes through the golden-file machinery rather than
/// `RenderRepaintBoundary.toImage`. `toImage` succeeds exactly once per test
/// process here and then hangs on the next call, whereas the golden pipeline
/// is built to rasterise repeatedly — which is what a multi-scene, multi-frame
/// screenshot run needs. The comparator simply writes what it is given instead
/// of comparing it.
void installScreenshotWriter() {
  goldenFileComparator = _ScreenshotWriter();
}

class _ScreenshotWriter extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final File out = File(golden.toFilePath());
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await compare(imageBytes, golden);
  }

  /// Keep the path exactly as written, rather than resolving it against the
  /// test file's directory the way [LocalFileComparator] does.
  @override
  Uri getTestUri(Uri key, int? version) => key;
}

/// Rasterises the scene behind [key] to [path], relative to the package root.
Future<void> capture(WidgetTester tester, GlobalKey key, String path) async {
  await expectLater(find.byKey(key), matchesGoldenFile(path));
}

/// Writes numbered animation frames to a scratch directory and returns it.
Directory framesDir(String name) {
  final Directory dir = Directory('.dart_tool/screenshot_frames/$name');
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);
  return dir;
}
