// Renders the launcher icons and the splash images from NexoLogoPainter, the
// painter the app itself uses (design_system), and writes them into the
// Android and iOS projects. Run it with `make brand-assets` after changing
// the logo.
//
// It is a test only because `flutter test` provides the Flutter engine to
// draw with. `make test` does not run it: it only runs the test/ folders.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:banking_app/app/pages/splash_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _androidRes = 'android/app/src/main/res';
const _iosAssets = 'ios/Runner/Assets.xcassets';

/// Android densities and their pixels per dp.
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

/// Width of the mark on the native splash screens, in dp (Android) and pt
/// (iOS): the same as on [SplashPage], which comes right after them. Android
/// 12+ draws its own splash with the adaptive icon, where the mark also
/// measures about 88 dp (the 72 dp visible of 108 dp, shown at 160 dp).
const splashMarkSize = SplashPage.markSize;

void main() {
  test('renders the app icon and the splash images', () async {
    const mark = NexoLogoPainter(markOnly: true);

    for (final MapEntry(key: density, value: dp) in _densities.entries) {
      // Android 7 launchers: the navy square, 48 dp with a 2 dp margin.
      await _writePng(
        '$_androidRes/mipmap-$density/ic_launcher.png',
        pixels: 48 * dp,
        draw: (canvas) => _drawIn(
          canvas,
          Rect.fromLTWH(2 * dp, 2 * dp, 44 * dp, 44 * dp),
          const NexoLogoPainter(),
        ),
      );

      // Android 8+ adaptive icon: 108 dp layers, of which the launcher shows
      // the middle 72 dp. The navy background is a color (colors.xml); this
      // layer is the mark, as large as in the 72 dp square.
      final markSide = 72 * NexoLogoPainter.markBounds.width * dp;
      final markRect = Rect.fromCenter(
        center: Offset(54 * dp, 54 * dp),
        width: markSide,
        height: markSide,
      );
      await _writePng(
        '$_androidRes/mipmap-$density/ic_launcher_foreground.png',
        pixels: 108 * dp,
        draw: (canvas) => _drawIn(canvas, markRect, mark),
      );
      // Android 13 themed icons: the system tints this silhouette.
      await _writePng(
        '$_androidRes/mipmap-$density/ic_launcher_monochrome.png',
        pixels: 108 * dp,
        draw: (canvas) => _drawIn(
          canvas,
          markRect,
          const NexoLogoPainter(markOnly: true, monochrome: AppColors.white),
        ),
      );

      // Splash before Android 12 (launch_background.xml).
      await _writePng(
        '$_androidRes/drawable-$density/launch_mark.png',
        pixels: splashMarkSize * dp,
        draw: (canvas) => _drawIn(
          canvas,
          Offset.zero & Size.square(splashMarkSize * dp),
          mark,
        ),
      );
    }

    // iOS: a single 1024 px icon (Xcode makes the other sizes). Full bleed,
    // because iOS rounds the corners itself, and opaque, because the App
    // Store rejects icons with an alpha channel.
    await _writePng(
      '$_iosAssets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      pixels: 1024,
      opaque: true,
      draw: (canvas) {
        canvas.drawColor(AppColors.navy, BlendMode.src);
        _drawIn(
          canvas,
          const Rect.fromLTWH(0, 0, 1024, 1024),
          const NexoLogoPainter(),
        );
      },
    );

    // iOS launch screen (LaunchScreen.storyboard): the mark at 88 pt.
    for (final (suffix, scale) in [('', 1), ('@2x', 2), ('@3x', 3)]) {
      await _writePng(
        '$_iosAssets/LaunchImage.imageset/LaunchImage$suffix.png',
        pixels: splashMarkSize * scale,
        draw: (canvas) => _drawIn(
          canvas,
          Offset.zero & Size.square(splashMarkSize * scale),
          mark,
        ),
      );
    }
  });
}

void _drawIn(Canvas canvas, Rect rect, NexoLogoPainter painter) {
  canvas
    ..save()
    ..translate(rect.left, rect.top);
  painter.paint(canvas, rect.size);
  canvas.restore();
}

/// Draws on a transparent square of [pixels] and saves it as PNG.
Future<void> _writePng(
  String path, {
  required double pixels,
  required void Function(Canvas canvas) draw,
  bool opaque = false,
}) async {
  final side = pixels.round();
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(side, side);
  final Uint8List png;
  if (opaque) {
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    png = _encodeRgbPng(side, side, rgba!.buffer.asUint8List());
  } else {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    png = data!.buffer.asUint8List();
  }
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png);
}

/// PNG with 8-bit RGB pixels (no alpha channel) from opaque RGBA bytes.
/// Flutter's encoder always adds alpha, which the App Store rejects.
Uint8List _encodeRgbPng(int width, int height, Uint8List rgba) {
  // Each row starts with its filter type (0: none), then R, G, B per pixel.
  final rows = Uint8List(height * (1 + width * 3));
  var offset = 0;
  for (var y = 0; y < height; y++) {
    rows[offset++] = 0;
    for (var x = 0; x < width; x++) {
      final pixel = (y * width + x) * 4;
      rows[offset++] = rgba[pixel];
      rows[offset++] = rgba[pixel + 1];
      rows[offset++] = rgba[pixel + 2];
    }
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bits per channel
    ..setUint8(9, 2); // color type: RGB
  return (BytesBuilder()
        ..add(const [137, 80, 78, 71, 13, 10, 26, 10]) // PNG signature
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(_chunk('IDAT', ZLibCodec(level: 9).encode(rows)))
        ..add(_chunk('IEND', const [])))
      .takeBytes();
}

/// A PNG chunk: length, type, data and the CRC-32 of type and data.
List<int> _chunk(String type, List<int> data) {
  final body = [...ascii.encode(type), ...data];
  Uint8List uint32(int value) =>
      (ByteData(4)..setUint32(0, value)).buffer.asUint8List();
  return [...uint32(data.length), ...body, ...uint32(_crc32(body))];
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = crc & 1 == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
