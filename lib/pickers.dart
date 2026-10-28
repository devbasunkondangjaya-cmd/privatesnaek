import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'image_store.dart';
import 'level_data.dart';
import 'ui_kit.dart';
import 'venomcoil_game.dart';

/// Preview column on the left, selectable grid on the right.
class _PickerLayout extends StatelessWidget {
  const _PickerLayout({required this.preview, required this.grid});

  final Widget preview;
  final Widget grid;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: math.min(220, box.maxWidth * 0.4), child: preview),
        const SizedBox(width: 14),
        Expanded(child: grid),
      ],
    ),
  );
}

Color _hex(String value) =>
    Color(int.parse('ff${value.replaceFirst('#', '')}', radix: 16));

/// Tap an area to see its backdrop, palette, lesson and best time first; the
/// run only starts from the MAIN button.
class AreaPicker extends StatefulWidget {
  const AreaPicker({super.key, required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  State<AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends State<AreaPicker> {
  late int _sel = widget.state.area - 1;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final level = campaignLevels[_sel];
    final no = (_sel + 1).toString().padLeft(2, '0');
    final bg = (level['bg'] as String?) ?? 'area_${no}_bg.webp';
    final colors = (level['palette'] as List<dynamic>)
        .cast<String>()
        .map(_hex)
        .toList();
    final best = state.bestTimes[_sel];
    final done = state.completed.contains(_sel);
    return _PickerLayout(
      preview: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/$bg',
                    fit: BoxFit.cover,
                    cacheWidth: 560,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => ColoredBox(color: colors.first),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xcc04110d)],
                        stops: [0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AREA $no',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff83e86a),
                          ),
                        ),
                        Text(
                          (level['shortName'] as String).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Palette.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        for (final c in colors)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white54),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level['lesson'] as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              height: 1.25,
              color: Palette.mist,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            best != null
                ? 'Terbaik ${formatTime(best)}'
                : done
                ? 'Selesai'
                : 'Belum selesai',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: done ? Palette.gold : Palette.mist,
            ),
          ),
          const SizedBox(height: 6),
          GameButton(
            label: 'MAIN',
            style: GameButtonStyle.primary,
            height: 40,
            onTap: () => widget.game.pickArea(_sel),
          ),
        ],
      ),
      grid: GridView.builder(
        itemCount: 20,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (context, index) {
          final previewed = index == _sel;
          final current = index + 1 == state.area;
          final cleared = state.completed.contains(index);
          return Material(
            color: previewed
                ? const Color(0xff4b983d)
                : const Color(0xff20352b),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                UiKit.onTap?.call();
                setState(() => _sel = index);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: cleared
                      ? Border.all(
                          color: Palette.gold.withValues(alpha: 0.8),
                          width: 1.6,
                        )
                      : current
                      ? Border.all(
                          color: Palette.leafBright.withValues(alpha: 0.7),
                          width: 1.4,
                        )
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: previewed ? 0.9 : 0.5,
                        child: Image.asset(
                          'assets/images/${campaignLevels[index]['bg'] ?? 'area_${(index + 1).toString().padLeft(2, '0')}_bg.webp'}',
                          fit: BoxFit.cover,
                          cacheWidth: 140,
                          errorBuilder: (_, _, _) => const SizedBox(),
                        ),
                      ),
                    ),
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        shadows: const [Shadow(blurRadius: 6)],
                        color: previewed
                            ? Colors.white
                            : const Color(0xffdcf1d2),
                      ),
                    ),
                    if (cleared)
                      const Positioned(
                        top: 3,
                        right: 4,
                        child: Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Palette.gold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tap a skin to see it animated first; it is only applied by PAKAI SKIN.
class SkinPicker extends StatefulWidget {
  const SkinPicker({super.key, required this.game, required this.state});

  final VenomcoilGame game;
  final GameHudState state;

  @override
  State<SkinPicker> createState() => _SkinPickerState();
}

class _SkinPickerState extends State<SkinPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();
  late int _sel = widget.state.skinIndex;
  int? _applyingSkin;

  static String _file(int skin) =>
      'skin_${(skin + 1).toString().padLeft(2, '0')}_motion_a-transparent.webp';

  @override
  void initState() {
    super.initState();
    ImageStore.instance.loadSheet(_file(_sel), cols: 5, rows: 4);
  }

  /// Frees a previewed sheet unless it belongs to the skin in use.
  void _releasePreview(int skin) {
    if (skin != widget.state.skinIndex && skin != _applyingSkin) {
      ImageStore.instance.release([_file(skin)]);
    }
  }

  void _preview(int index) {
    if (index == _sel) return;
    final old = _sel;
    setState(() => _sel = index);
    ImageStore.instance.loadSheet(_file(index), cols: 5, rows: 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && old != _sel) _releasePreview(old);
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    _releasePreview(_sel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final glow = VenomcoilGame.skinColors[_sel];
    final active = _sel == state.skinIndex;
    return _PickerLayout(
      preview: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: glow.withValues(alpha: 0.5)),
                gradient: RadialGradient(
                  colors: [
                    glow.withValues(alpha: 0.35),
                    const Color(0xff0d1a15),
                  ],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final side = math.min(box.maxWidth, box.maxHeight) * 0.95;
                  return AnimatedBuilder(
                    animation: _clock,
                    builder: (context, _) => ValueListenableBuilder<int>(
                      valueListenable: ImageStore.instance.revision,
                      builder: (context, _, _) {
                        final sheet = ImageStore.instance.sheet(_file(_sel));
                        if (sheet == null) {
                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final t = _clock.value * 10;
                        return Center(
                          child: Transform.translate(
                            offset: Offset(0, math.sin(t * 6) * 3),
                            child: CustomPaint(
                              size: Size(side, side),
                              painter: SpriteFrame(
                                sheet,
                                (t * 7).floor() % 5,
                                const [0, 1, 2, 3][(t / 2).floor() % 4],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            VenomcoilGame.skinNames[_sel].toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Palette.cream,
            ),
          ),
          const SizedBox(height: 6),
          GameButton(
            label: active ? 'DIPAKAI' : 'PAKAI SKIN',
            style: active ? GameButtonStyle.secondary : GameButtonStyle.primary,
            height: 40,
            onTap: () async {
              if (active || _applyingSkin != null) return;
              final selected = _sel;
              _applyingSkin = selected;
              try {
                await widget.game.selectSkin(selected);
              } finally {
                _applyingSkin = null;
              }
            },
          ),
        ],
      ),
      grid: GridView.builder(
        itemCount: VenomcoilGame.skinNames.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3.1,
        ),
        itemBuilder: (context, index) {
          final previewed = index == _sel;
          final inUse = index == state.skinIndex;
          return Material(
            color: previewed
                ? const Color(0xff4b983d)
                : const Color(0xff20352b),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                UiKit.onTap?.call();
                _preview(index);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: VenomcoilGame.skinColors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        VenomcoilGame.skinNames[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: previewed
                              ? Colors.white
                              : const Color(0xffdcf1d2),
                        ),
                      ),
                    ),
                    if (inUse) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.check_circle,
                        size: 13,
                        color: Palette.gold,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
