import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snake/level_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every character and enemy sprite sheet has usable frames', () async {
    final files = <String>{
      for (var skin = 1; skin <= 10; skin++)
        for (final kind in [
          'motion_a',
          'motion_b',
          'combat',
          'reactions',
          'outcomes',
          'fx',
        ])
          'skin_${skin.toString().padLeft(2, '0')}_$kind-transparent.webp',
      for (final level in campaignLevels) level['enemy'] as String,
      'vexa_motion_a-transparent.webp',
      'boss_15_a-transparent.webp',
      'boss_15_b-transparent.webp',
      'boss_20_a-transparent.webp',
      'boss_20_b-transparent.webp',
    };

    for (final file in files) {
      final data = await rootBundle.load('assets/images/$file');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      final rows = file.contains('_outcomes-') ? 2 : 4;
      expect(image.width / 5, greaterThan(2), reason: file);
      expect(image.height / rows, greaterThan(2), reason: file);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      final rowsInUse = file.startsWith('enemy_') || file.startsWith('boss_')
          ? 1
          : rows;
      for (var row = 0; row < rowsInUse; row++) {
        for (var col = 0; col < 5; col++) {
          var visible = false;
          final left = (col * image.width / 5).ceil();
          final right = ((col + 1) * image.width / 5).floor();
          final top = (row * image.height / rows).ceil();
          final bottom = ((row + 1) * image.height / rows).floor();
          for (var y = top; y < bottom && !visible; y += 4) {
            for (var x = left; x < right; x += 4) {
              if (pixels[(y * image.width + x) * 4 + 3] != 0) {
                visible = true;
                break;
              }
            }
          }
          expect(visible, isTrue, reason: '$file frame ($col, $row)');
        }
      }
      image.dispose();
    }
  });
}
