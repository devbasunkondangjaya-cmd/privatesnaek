import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake/save_data.dart';
import 'package:snake/main.dart';
import 'package:snake/venomcoil_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void advance(VenomcoilGame game, double seconds) {
    for (var frame = 0; frame < (seconds * 60).round(); frame++) {
      game.update(1 / 60);
    }
  }

  Future<VenomcoilGame> playableGame() async {
    SharedPreferences.setMockInitialValues({});
    final game = VenomcoilGame(await SaveData.load());
    game.onGameResize(Vector2(960, 540));
    await game.onLoad();
    await game.selectArea(1);
    game.startOrResume();
    addTearDown(game.onRemove);
    return game;
  }

  test('small stick input controls speed and release stops on the ground', () async {
    final game = await playableGame();
    game.setMoveAxis(.25);
    advance(game, .25);
    expect(game.debugPlayerState.velocity.dx, closeTo(130, 1));
    game.setMoveAxis(1);
    advance(game, .25);
    expect(game.debugPlayerState.velocity.dx, closeTo(520, 1));
    final releasedAt = game.debugPlayerState.position.dx;
    game.setMoveAxis(0);
    advance(game, .25);
    expect(game.debugPlayerState.velocity.dx, 0);
    expect(game.debugPlayerState.position.dx - releasedAt, lessThan(40));
  });

  test('reverse responds promptly and pause clears movement', () async {
    final game = await playableGame();
    game.setMove(right: true);
    advance(game, .25);
    game.setMove(right: false, left: true);
    advance(game, .2);
    expect(game.debugPlayerState.velocity.dx, lessThan(0));
    game.togglePause();
    final pausedAt = game.debugPlayerState.position;
    advance(game, .5);
    expect(game.debugPlayerState.position, pausedAt);
    game.togglePause();
    advance(game, .25);
    expect(game.debugPlayerState.velocity.dx, 0);
  });

  test('stationary coil jumps vertically, air jump is single use, landing resets it', () async {
    final game = await playableGame();
    final start = game.debugPlayerState.position;
    game.setJumpHeld(true);
    advance(game, .25);
    game.setJumpHeld(false);
    advance(game, .2);
    expect(game.debugPlayerState.grounded, isFalse);
    expect(game.debugPlayerState.position.dy, lessThan(start.dy));
    expect(game.debugPlayerState.position.dx, closeTo(start.dx, .01));
    game.setJumpHeld(true);
    expect(game.debugPlayerState.airJumpUsed, isTrue);
    game.setJumpHeld(false);
    advance(game, .1);
    final fallingVelocity = game.debugPlayerState.velocity.dy;
    game.setJumpHeld(true);
    expect(game.debugPlayerState.velocity.dy, fallingVelocity);
    game.setJumpHeld(false);
    advance(game, 2);
    expect(game.debugPlayerState.grounded, isTrue);
    expect(game.debugPlayerState.airJumpUsed, isFalse);
    expect(game.debugPlayerState.position.dy, closeTo(start.dy, .01));
  });

  test('venom fires in area two and cooldown prevents repeated shots', () async {
    final game = await playableGame();
    game.useVenom();
    advance(game, 1 / 60);
    expect(game.debugPlayerState.projectiles, 1);
    game.useVenom();
    advance(game, 1 / 60);
    expect(game.debugPlayerState.projectiles, 1);
  });

  test('menu starts a playable area and renders moving gameplay', () async {
    SharedPreferences.setMockInitialValues({});
    final game = VenomcoilGame(await SaveData.load());
    game.onGameResize(Vector2(960, 540));
    await game.onLoad();
    expect(game.hud.value.overlay, 'menu');
    await game.playFromMenu();
    expect(game.hud.value.overlay, 'tutorial');
    game.closeTutorial();
    expect(game.hud.value.overlay, isNull);
    for (var frame = 0; frame < 12; frame++) {
      game.update(1 / 60);
    }
    expect(game.hud.value.elapsed, greaterThan(0));
    final before = game.hud.value.progress;
    game.setMove(right: true);
    for (var frame = 0; frame < 60; frame++) {
      game.update(1 / 60);
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    }
    expect(game.hud.value.elapsed, greaterThan(0));
    expect(game.hud.value.progress, greaterThan(before));
    game.onRemove();
  });

  testWidgets('loading finishes before menu can start gameplay', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final save = await SaveData.load();
    await tester.pumpWidget(VenomcoilApp(save: save));
    expect(find.text('Memuat permainan…'), findsOneWidget);
    expect(find.text('MAIN'), findsNothing);
    final game = tester
        .widget<GameWidget<VenomcoilGame>>(
          find.byType(GameWidget<VenomcoilGame>),
        )
        .game!;
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    await tester.pump();
    expect(find.text('MAIN'), findsOneWidget);
    await tester.tap(find.text('MAIN'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    // Every run opens with the skippable how-to-play cards.
    expect(game.hud.value.overlay, 'tutorial');
    expect(find.text('CARA MAIN'), findsOneWidget);
    await tester.tap(find.text('LEWATI  ›'));
    await tester.pump();
    expect(game.hud.value.overlay, isNull);
    expect(find.text('LOMPAT'), findsOneWidget);
    expect(find.text('CARA MAIN'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
