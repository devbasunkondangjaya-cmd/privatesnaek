import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/image_store.dart';
import 'package:snake/save_data.dart';
import 'package:snake/venomcoil_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('frame stays cheap and HUD quiet while idle', () async {
    SharedPreferences.setMockInitialValues({});
    final game = VenomcoilGame(await SaveData.load());
    game.onGameResize(Vector2(1688, 780));
    await game.onLoad();
    var publishes = 0;
    game.hud.addListener(() => publishes++);
    for (var i = 0; i < 300; i++) {
      game.update(1 / 60);
    }
    expect(publishes, 0, reason: 'an idle title screen must not rebuild the UI');

    await game.selectArea(1);
    game.startOrResume();
    game.setMove(right: true);
    final watch = Stopwatch()..start();
    for (var frame = 0; frame < 1200; frame++) {
      game.update(1 / 60);
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    }
    watch.stop();
    // ignore: avoid_print
    print('BENCH update+record: ${(watch.elapsedMicroseconds / 1200).toStringAsFixed(0)} us/frame');
    game.onRemove();
  });

  test('only the current area and what it uses stays in memory', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ImageStore.instance;
    final game = VenomcoilGame(await SaveData.load());
    game.onGameResize(Vector2(1688, 780));
    await game.onLoad();
    final menu = store.loadedFiles.toSet();
    expect(menu.any((f) => f.startsWith('fx_') || f.contains('_tiles')), isFalse);
    // ignore: avoid_print
    print('MEM menu: ${store.loadedBytes >> 20} MB, ${menu.length} sheets');

    await game.selectArea(1);
    expect(store.sheet('area_02_bg.webp'), isNotNull);
    // ignore: avoid_print
    print('MEM area 2: ${store.loadedBytes >> 20} MB, ${store.loadedFiles.length} sheets');
    await game.selectArea(2);
    expect(store.sheet('area_03_bg.webp'), isNotNull);
    expect(store.loadedFiles.any((f) => f.startsWith('area_02')), isFalse);
    expect(store.loadedFiles.where((f) => f.contains('_motion_b')), isEmpty);

    await game.resetProgress();
    expect(store.loadedFiles.any((f) => f.contains('_tiles')), isFalse);
    game.onRemove();
  });
}
