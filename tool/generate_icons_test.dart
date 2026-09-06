import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nestik_game/ui/mask_logo.dart';

/// Renders the app's theater-mask icon into the platform launcher-icon files.
///
/// Run once after changing the brand:  `flutter test tool/generate_icons_test.dart`
class _IconTarget {
  const _IconTarget(this.path, this.size, {this.foreground = false});
  final String path;
  final double size;
  final bool foreground;
}

const _targets = <_IconTarget>[
  // Android legacy mipmaps
  _IconTarget('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48),
  _IconTarget('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72),
  _IconTarget('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96),
  _IconTarget('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144),
  _IconTarget('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192),
  // Android adaptive-icon foreground layers (transparent bg, safe-zone mask)
  _IconTarget(
      'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png', 108,
      foreground: true),
  _IconTarget(
      'android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png', 162,
      foreground: true),
  _IconTarget(
      'android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png', 216,
      foreground: true),
  _IconTarget(
      'android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png', 324,
      foreground: true),
  _IconTarget(
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png', 432,
      foreground: true),
  // Web
  _IconTarget('web/icons/Icon-192.png', 192),
  _IconTarget('web/icons/Icon-512.png', 512),
  _IconTarget('web/icons/Icon-maskable-192.png', 192),
  _IconTarget('web/icons/Icon-maskable-512.png', 512),
  _IconTarget('web/favicon.png', 64),
  // iOS AppIcon.appiconset
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png', 20),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png', 40),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png', 60),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png', 29),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png', 58),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png', 87),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png', 40),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png', 80),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png', 120),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png', 120),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png', 180),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png', 76),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png', 152),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png', 167),
  _IconTarget('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', 1024),
];

class _IconCanvas extends StatelessWidget {
  final double size;
  final bool foreground;
  const _IconCanvas({required this.size, this.foreground = false});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: foreground
            ? null
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3A2D6E),
                    Color(0xFF5546C0),
                    Color(0xFF2F3B5F),
                  ],
                ),
              ),
        child: Center(
          child: MaskLogo(
            size: size * (foreground ? 0.50 : 0.60),
            glow: true,
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('generate launcher icons', (WidgetTester tester) async {
    for (final target in _targets) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(target.size + 64, target.size + 64);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Center(
            child: _IconCanvas(size: target.size, foreground: target.foreground),
          ),
        ),
      );
      await tester.pump();

      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final image = await boundary.toImage(pixelRatio: 1.0);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(target.path);
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}