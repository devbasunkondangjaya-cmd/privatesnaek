import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/main.dart';
import 'package:snake/save_data.dart';
import 'package:snake/venomcoil_game.dart';

/// Renders every screen with the real fonts and art into build/review, on a
/// landscape phone-sized surface, for checking the look by eye.
void main() {
  Future<void> loadFonts() async {
    const families = {
      'CinzelDecorative': ['CinzelDecorative-Black'],
      'Cinzel': ['Cinzel-Bold', 'Cinzel-Black'],
      'AlegreyaSans': [
        'AlegreyaSans-Medium',
        'AlegreyaSans-Bold',
        'AlegreyaSans-ExtraBold',
      ],
    };
    for (final family in families.entries) {
      final loader = FontLoader(family.key);
      for (final file in family.value) {
        loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
      }
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons');
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root == null) return;
    icons.addFont(
      File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes().then((b) => ByteData.sublistView(b)),
    );
    await icons.load();
  }

  testWidgets('capture every screen', timeout: const Timeout(Duration(seconds: 150)), (tester) async {
    final output = Directory('build/review')..createSync(recursive: true);
    tester.view.physicalSize = const Size(844 * 2.0, 390 * 2.0);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.runAsync(loadFonts);
    SharedPreferences.setMockInitialValues({
      'completedAreas': ['0', '2'],
      'bestTimes': ['0:84.5'],
    });
    final save = await tester.runAsync(SaveData.load);
    await tester.pumpWidget(VenomcoilApp(save: save!));
    final game = tester
        .widget<GameWidget<VenomcoilGame>>(
          find.byType(GameWidget<VenomcoilGame>),
        )
        .game!;

    Future<void> settle([int frames = 12]) async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 33));
    }

    Future<void> shot(String name) async {
      await settle();
      final element = tester.element(find.byType(GameScreen));
      await tester.runAsync(() async {
        final image = await captureImage(element);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${output.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> idle(bool Function() ready) async {
      for (var i = 0; i < 900 && !ready(); i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
    }

    // Art decoding finishes on real time but resumes inside the fake-time zone,
    // so keep pumping while waiting for it.
    while (!game.isLoaded) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await shot('1_menu');

    game.openSkinSelect();
    await shot('2_skins');
    game.backFromSubmenu();
    game.openAreaSelect();
    await shot('3_areas');
    game.backFromSubmenu();

    await tester.runAsync(() => game.selectArea(1));
    game.showTutorial(beforeRun: true);
    await shot('4_tutorial');
    game.closeTutorial();
    await settle(10);
    await shot('5a_stand');
    game.setJumpHeld(true);
    await tester.pump(const Duration(milliseconds: 100));
    game.setJumpHeld(false);
    await settle(3);
    await shot('5b_jump');
    await settle(40);
    game.setMoveAxis(1);
    await settle(60);
    await shot('5_play');
    game.setMoveAxis(0);
    game.useAttack();
    await tester.pump(const Duration(milliseconds: 60));
    game.togglePause();
    await shot('6_pause');
    game.startOrResume();
    await tester.runAsync(() => game.selectArea(4, checkpoint: 12));
    game.startOrResume();
    game.setMoveAxis(1);
    await idle(() => game.hud.value.bossMaxHp > 0 || game.hud.value.overlay != null);
    await settle(150);
    await shot('7_boss');
    game.setMoveAxis(0);
    game.debugKillPlayer();
    await shot('8_death');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
