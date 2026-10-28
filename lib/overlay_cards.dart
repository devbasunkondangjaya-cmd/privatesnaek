import 'package:flutter/material.dart';

import 'pause_panel.dart';
import 'pickers.dart';
import 'ui_kit.dart';
import 'venomcoil_game.dart';

/// Dimmed full-screen layer with a centred card for pause, game over, area
/// clear and the area / skin pickers.
class OverlayCard extends StatelessWidget {
  const OverlayCard({
    super.key,
    required this.game,
    required this.state,
    required this.overlay,
  });

  final VenomcoilGame game;
  final GameHudState state;
  final String overlay;

  @override
  Widget build(BuildContext context) => PopIn(
    key: ValueKey(overlay),
    child: overlay == 'pause'
        ? PausePanel(game: game, state: state)
        : _buildCard(context),
  );

  Widget _buildCard(BuildContext context) {
    final isAreas = overlay == 'areas';
    final isSkins = overlay == 'skins';
    final areaNo = state.area.toString().padLeft(2, '0');
    final best = state.bestTimes[state.area - 1];
    final titles = <String, (String, String, String)>{
      'areas': (
        'JEJAK 20 AREA',
        'PILIH AREA',
        'Selesai ${state.completed.length}/20. Ketuk area untuk preview.',
      ),
      'pause': ('AREA $areaNo', 'JEDA', 'Waktu berhenti. Ambil napas dulu.'),
      'skins': (
        'SEMUA BENTUK TERBUKA',
        'PILIH SKIN',
        'Ketuk skin untuk melihat preview, lalu pakai.',
      ),
      'death': (
        'JEJAK TERPUTUS',
        'COBA LAGI',
        state.bossWipe
            ? 'Dikalahkan bos besar. Ulang dari checkpoint pertama tema ini.'
            : 'Ulang dari checkpoint terakhir. Rutemu masih segar.',
      ),
      'complete': (
        'AREA SELESAI',
        state.areaName.toUpperCase(),
        best == null
            ? 'Jejak berlanjut. Lanjut ke area berikutnya.'
            : 'Waktu terbaik ${formatTime(best)}',
      ),
    }[overlay]!;

    final screen = MediaQuery.sizeOf(context);
    final safe = safeInsets(context, extra: 8);
    return Container(
      color: const Color(0x99030d0a),
      padding: safe,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isAreas || isSkins ? 660 : 470),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            color: Palette.panel.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Palette.panelLine.withValues(alpha: 0.65),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff45df5a).withValues(alpha: 0.12),
                blurRadius: 36,
                spreadRadius: 3,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titles.$1,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff83e86a),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  titles.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Palette.cream,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  titles.$3,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Palette.mist,
                  ),
                ),
                if (isAreas || isSkins) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: (screen.height * 0.46).clamp(170.0, 280.0),
                    child: isAreas
                        ? AreaPicker(game: game, state: state)
                        : SkinPicker(game: game, state: state),
                  ),
                  const SizedBox(height: 12),
                  if (isSkins)
                    Row(
                      children: [
                        Expanded(
                          child: GameButton(
                            label: 'KEMBALI',
                            style: GameButtonStyle.primary,
                            height: 46,
                            onTap: game.backFromSubmenu,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: GameButton(
                            label: 'PILIH AREA',
                            height: 46,
                            onTap: game.openAreaSelect,
                          ),
                        ),
                      ],
                    )
                  else
                    GameButton(
                      label: 'KEMBALI',
                      style: GameButtonStyle.primary,
                      height: 46,
                      onTap: game.backFromSubmenu,
                    ),
                ] else if (overlay == 'pause') ...[
                  const SizedBox(height: 18),
                  GameButton(
                    label: 'LANJUT',
                    style: GameButtonStyle.primary,
                    height: 52,
                    onTap: game.startOrResume,
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: GameButton(
                          label: 'SKIN',
                          onTap: game.openSkinSelect,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: GameButton(
                          label: 'AREA',
                          onTap: game.openAreaSelect,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  GameButton(
                    label: 'MENU UTAMA',
                    style: GameButtonStyle.ghost,
                    height: 40,
                    onTap: game.quitToMenu,
                  ),
                ] else if (overlay == 'death') ...[
                  const SizedBox(height: 18),
                  GameButton(
                    label: 'ULANGI',
                    style: GameButtonStyle.primary,
                    height: 52,
                    onTap: game.retry,
                  ),
                  const SizedBox(height: 9),
                  GameButton(label: 'PILIH AREA', onTap: game.openAreaSelect),
                  const SizedBox(height: 9),
                  GameButton(
                    label: 'MENU UTAMA',
                    style: GameButtonStyle.ghost,
                    height: 40,
                    onTap: game.quitToMenu,
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  GameButton(
                    label: state.area < 20 ? 'AREA BERIKUTNYA' : 'PILIH AREA',
                    style: GameButtonStyle.primary,
                    height: 52,
                    onTap: game.nextArea,
                  ),
                  const SizedBox(height: 9),
                  GameButton(
                    label: 'ULANGI AREA',
                    onTap: () => game.selectArea(state.area - 1),
                  ),
                  const SizedBox(height: 9),
                  GameButton(
                    label: 'MENU UTAMA',
                    style: GameButtonStyle.ghost,
                    height: 40,
                    onTap: game.quitToMenu,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
