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
        SizedBox(width: math.min(240, box.maxWidth * 0.4), child: preview),
        const SizedBox(width: 14),
        Expanded(child: grid),
      ],
    ),
  );
}

Color _hex(String value) =>
    Color(int.parse('ff${value.replaceFirst('#', '')}', radix: 16));

String _areaBg(int index) =>
    (campaignLevels[index]['bg'] as String?) ??
    'area_${(index + 1).toString().padLeft(2, '0')}_bg.webp';

/// A grid whose tiles shrink so every item is visible without scrolling.
class _FittedGrid extends StatelessWidget {
  const _FittedGrid({
    required this.count,
    required this.columns,
    required this.maxAspect,
    required this.itemBuilder,
  });

  final int count;
  final int columns;
  final double maxAspect;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      const gap = 7.0;
      final rows = (count / columns).ceil();
      final width = (box.maxWidth - gap * (columns - 1)) / columns;
      final height = (box.maxHeight - gap * (rows - 1)) / rows;
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: gap,
          mainAxisSpacing: gap,
          childAspectRatio: width / height > maxAspect
              ? maxAspect
              : width / math.max(1, height),
        ),
        itemBuilder: itemBuilder,
      );
    },
  );
}

/// Empties Flutter's image cache so previews do not outlive their picker.
void _dropPreviewImages() {
  PaintingBinding.instance.imageCache.clear();
}

/// Gold edge around a preview, lit brighter when selected.
class _TileFrame extends CustomPainter {
  const _TileFrame({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outline = chamferPath(rect.deflate(0.5), 6);
    if (selected) {
      canvas.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = color.withValues(alpha: 0.35),
      );
      canvas.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..shader = goldTrim(rect),
      );
    } else {
      canvas.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_TileFrame old) =>
      old.selected != selected || old.color != color;
}

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
  void dispose() {
    _dropPreviewImages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final level = campaignLevels[_sel];
    final no = (_sel + 1).toString().padLeft(2, '0');
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipPath(
                  clipper: const _ChamferClip(),
                  child: Image.asset(
                    'assets/images/${_areaBg(_sel)}',
                    fit: BoxFit.cover,
                    cacheWidth: 480,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => ColoredBox(color: colors.first),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xdd04110d)],
                      stops: [0.42, 1],
                    ),
                  ),
                ),
                CustomPaint(
                  painter: _TileFrame(selected: true, color: colors[1]),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AREA $no',
                        style: Ts.head(
                          9.5,
                          color: Palette.leafBright,
                          spacing: 2.2,
                          weight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        (level['shortName'] as String).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Ts.head(14, color: Palette.goldBright),
                      ),
                    ],
                  ),
                ),
                if (done)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: Palette.gold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            level['lesson'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Ts.body(11.5, height: 1.2),
          ),
          Text(
            best != null
                ? 'Terbaik ${formatTime(best)}'
                : done
                ? 'Selesai'
                : 'Belum selesai',
            textAlign: TextAlign.center,
            style: Ts.body(
              12,
              color: done ? Palette.gold : Palette.mist,
              weight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 5),
          GameButton(
            label: 'MAIN',
            style: GameButtonStyle.primary,
            height: 40,
            onTap: () => widget.game.pickArea(_sel),
          ),
        ],
      ),
      grid: _FittedGrid(
        count: 20,
        columns: 5,
        maxAspect: 1.5,
        itemBuilder: (context, index) => _AreaTile(
          index: index,
          selected: index == _sel,
          current: index + 1 == state.area,
          cleared: state.completed.contains(index),
          onTap: () {
            UiKit.onTap?.call();
            setState(() => _sel = index);
          },
        ),
      ),
    );
  }
}

class _ChamferClip extends CustomClipper<Path> {
  const _ChamferClip();

  @override
  Path getClip(Size size) => chamferPath(Offset.zero & size, 6);

  @override
  bool shouldReclip(_ChamferClip oldClipper) => false;
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.index,
    required this.selected,
    required this.current,
    required this.cleared,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final bool current;
  final bool cleared;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        ColoredBox(
          color: const Color(0xff0a1411),
          child: Opacity(
            opacity: selected ? 1 : 0.55,
            child: Image.asset(
              'assets/images/${_areaBg(index)}',
              fit: BoxFit.cover,
              cacheWidth: 140,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
        ),
        CustomPaint(
          painter: _TileFrame(
            selected: selected,
            color: cleared
                ? Palette.gold
                : current
                ? Palette.leafBright
                : const Color(0xff7c8a78),
          ),
        ),
        Center(
          child: Text(
            (index + 1).toString().padLeft(2, '0'),
            style: Ts.head(
              15,
              color: selected ? Palette.goldBright : Palette.cream,
              spacing: 0.4,
              shadows: const [
                Shadow(blurRadius: 5),
                Shadow(blurRadius: 2),
              ],
            ),
          ),
        ),
        if (cleared)
          const Positioned(
            top: 3,
            right: 4,
            child: Icon(Icons.verified_rounded, size: 12, color: Palette.gold),
          ),
      ],
    ),
  );
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        glow.withValues(alpha: 0.42),
                        const Color(0xff0a1411),
                      ],
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: ValueListenableBuilder<int>(
                    valueListenable: ImageStore.instance.revision,
                    builder: (context, _, _) {
                      final sheet = ImageStore.instance.sheet(_file(_sel));
                      if (sheet == null) {
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Palette.gold,
                            ),
                          ),
                        );
                      }
                      return CustomPaint(
                        painter: _PosePainter(sheet, _clock),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
                CustomPaint(painter: _TileFrame(selected: true, color: glow)),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            VenomcoilGame.skinNames[_sel].toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Ts.head(13, color: Palette.goldBright),
          ),
          const SizedBox(height: 5),
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
      grid: _FittedGrid(
        count: VenomcoilGame.skinNames.length,
        columns: 2,
        maxAspect: 4,
        itemBuilder: (context, index) {
          final previewed = index == _sel;
          final inUse = index == state.skinIndex;
          final color = VenomcoilGame.skinColors[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              UiKit.onTap?.call();
              _preview(index);
            },
            child: CustomPaint(
              painter: _TileFrame(selected: previewed, color: color),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: previewed ? 0.34 : 0.1),
                      const Color(0x00000000),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  child: Row(
                    children: [
                      Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(color: Palette.goldBright),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          VenomcoilGame.skinNames[index],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Ts.body(
                            13,
                            color: previewed
                                ? Palette.goldBright
                                : Palette.cream,
                            weight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (inUse)
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Palette.gold,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Cycles the skin through its movement poses without rebuilding any widget.
class _PosePainter extends CustomPainter {
  _PosePainter(this.sheet, this.clock) : super(repaint: clock);

  final SheetInfo sheet;
  final Animation<double> clock;
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value * 10;
    final col = (t * 7).floor() % 5;
    final row = const [0, 1, 2, 3][(t / 2).floor() % 4];
    final src = sheet.content(col, row);
    final side = math.min(size.width, size.height) * 0.92;
    final scale = side / sheet.cellWidth;
    final w = src.width * scale, h = src.height * scale;
    final bob = math.sin(t * 6) * 3;
    canvas.drawImageRect(
      sheet.image,
      src,
      Rect.fromLTWH(
        (size.width - w) / 2,
        (size.height + side) / 2 - h + bob,
        w,
        h,
      ),
      _paint,
    );
  }

  @override
  bool shouldRepaint(_PosePainter old) =>
      old.sheet != sheet || old.clock != clock;
}
