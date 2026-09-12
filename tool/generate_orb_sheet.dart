import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loading_icon_button/src/orbs/orb_painter.dart';
import 'package:loading_icon_button/src/orbs/orb_presets.dart';

/// Regenerates `doc/thinking-orbs.png`, the contact sheet README.md links to.
///
/// This is a tool, not a test. It lives outside `test/` on purpose, so
/// `flutter test` never picks it up; rasterising needs the test binding, hence
/// the `testWidgets`-shaped entry point. Run it by hand after changing any orb
/// tuning:
///
/// ```sh
/// flutter test tool/generate_orb_sheet.dart
/// ```
///
/// The sheet carries no text: `flutter_test` substitutes a placeholder font
/// that paints every glyph as a filled box, so the state names live in the
/// README table instead.
void main() {
  test('regenerate the thinking-orb contact sheet', () async {
    const double scale = 2; // render at 2x for crisp display
    const double cell = 132;
    const double gutter = 10;
    const double orbBig = 72;
    const double orbSmall = 20;
    const int cols = 3;
    const int rowsOfStates = 3;

    const Color paper = Color(0xFFF7F7F5);

    final List<OrbState> states = OrbState.values;
    const double sheetW = cell * cols;
    const double sheetH = cell * rowsOfStates;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(scale);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, sheetW, sheetH),
      Paint()..color = paper,
    );

    for (int i = 0; i < states.length; i++) {
      final OrbState st = states[i];
      final int col = i % cols;
      final int row = i ~/ cols;
      final double x0 = col * cell;
      final double y0 = row * cell;

      // The 64px avatar tuning, and the 20px inline tuning beside it.
      canvas.save();
      canvas.translate(
          x0 + (cell - orbBig) / 2 - gutter, y0 + (cell - orbBig) / 2);
      OrbPainter(
        resolved: resolvePreset(st, tierForSize(orbBig)),
        time: ValueNotifier<double>(
            1.7 * resolvePreset(st, tierForSize(orbBig)).speed),
        dark: false,
        color: null,
      ).paint(canvas, const Size(orbBig, orbBig));
      canvas.restore();

      canvas.save();
      canvas.translate(x0 + cell - orbSmall - gutter * 1.6,
          y0 + cell - orbSmall - gutter * 1.4);
      OrbPainter(
        resolved: resolvePreset(st, tierForSize(orbSmall)),
        time: ValueNotifier<double>(
            1.7 * resolvePreset(st, tierForSize(orbSmall)).speed),
        dark: false,
        color: null,
      ).paint(canvas, const Size(orbSmall, orbSmall));
      canvas.restore();
    }

    final ui.Image img = await recorder.endRecording().toImage(
          (sheetW * scale).ceil(),
          (sheetH * scale).ceil(),
        );
    final ByteData bytes =
        (await img.toByteData(format: ui.ImageByteFormat.png))!;
    Directory('doc').createSync(recursive: true);
    File('doc/thinking-orbs.png').writeAsBytesSync(bytes.buffer.asUint8List());
    debugPrint('>>> doc/thinking-orbs.png: ${bytes.lengthInBytes} bytes');
  });
}
