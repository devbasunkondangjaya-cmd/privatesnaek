import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'image_store.dart';

/// Shared palette so every screen feels like the same game: obsidian panels,
/// antique gold trim and venom-emerald accents.
class Palette {
  static const ink = Color(0xff050b0a);
  static const panel = Color(0xff101c18);
  static const panelLine = Color(0xffc9a35a);
  static const leaf = Color(0xff38c978);
  static const leafBright = Color(0xff8dffb0);
  static const gold = Color(0xffe9c77d);
  static const goldBright = Color(0xfffff1c7);
  static const goldDeep = Color(0xff7c5c28);
  static const cream = Color(0xfff8ecd0);
  static const mist = Color(0xffb7c4b6);
  static const danger = Color(0xffff5b55);
  static const crimson = Color(0xff8c1b26);
}

/// Type ramp: Cinzel for anything engraved, Alegreya Sans for reading.
class Ts {
  static const _numbers = [
    ui.FontFeature.liningFigures(),
    ui.FontFeature.tabularFigures(),
  ];

  static TextStyle display(double size, {Color color = Palette.cream}) =>
      TextStyle(
        fontFamily: 'CinzelDecorative',
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 1,
        color: color,
      );

  static TextStyle head(
    double size, {
    Color color = Palette.cream,
    double spacing = 1.2,
    FontWeight weight = FontWeight.w900,
    List<Shadow>? shadows,
  }) => TextStyle(
    fontFamily: 'Cinzel',
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    height: 1.1,
    color: color,
    shadows: shadows,
  );

  static TextStyle body(
    double size, {
    Color color = Palette.mist,
    FontWeight weight = FontWeight.w500,
    double height = 1.32,
  }) => TextStyle(
    fontFamily: 'AlegreyaSans',
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    fontFeatures: const [ui.FontFeature.liningFigures()],
  );

  static TextStyle value(double size, {Color color = Palette.cream}) =>
      TextStyle(
        fontFamily: 'AlegreyaSans',
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: color,
        fontFeatures: _numbers,
      );
}

/// Called on every UI tap (click sound + audio unlock); set by the game screen.
class UiKit {
  static VoidCallback? onTap;
}

/// Minimum margins that keep controls clear of notches, rounded corners and
/// gesture bars on phones (viewPadding keeps notch insets in immersive mode).
EdgeInsets safeInsets(BuildContext context, {double extra = 0}) {
  final pad = MediaQuery.viewPaddingOf(context);
  final inset = MediaQuery.paddingOf(context);
  return EdgeInsets.fromLTRB(
    math.max(math.max(pad.left, inset.left), 14) + extra,
    math.max(math.max(pad.top, inset.top), 10) + extra,
    math.max(math.max(pad.right, inset.right), 14) + extra,
    math.max(math.max(pad.bottom, inset.bottom), 12) + extra,
  );
}

/// HUD atlas cells (4 x 3 grid in hud_atlas-transparent.webp).
class Hud {
  static const file = 'hud_atlas-transparent.webp';
  static const heart = 0;
  static const brokenHeart = 1;
  static const dash = 2;
  static const coil = 3;
  static const venom = 4;
  static const tail = 5;
  static const flag = 6;
  static const pause = 7;
  static const left = 8;
  static const right = 9;
  static const restart = 10;
  static const lock = 11;
}

/// One icon cut out of a sprite sheet, trimmed and scaled to fit [size].
class AtlasIcon extends StatelessWidget {
  const AtlasIcon(
    this.cell, {
    super.key,
    this.size = 28,
    this.file = Hud.file,
    this.cols = 4,
    this.opacity = 1,
  });

  final int cell;
  final double size;
  final String file;
  final int cols;
  final double opacity;

  Widget _icon(SheetInfo? sheet) => SizedBox(
    width: size,
    height: size,
    child: sheet == null
        ? null
        : CustomPaint(
            painter: _CellPainter(sheet, cell % cols, cell ~/ cols, opacity),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final loaded = ImageStore.instance.sheet(file);
    // Only an icon still waiting for its sheet has to listen for it; dozens of
    // listeners would all rebuild on every load during an area change.
    if (loaded != null) return _icon(loaded);
    return ValueListenableBuilder<int>(
      valueListenable: ImageStore.instance.revision,
      builder: (context, _, _) => _icon(ImageStore.instance.sheet(file)),
    );
  }
}

class _CellPainter extends CustomPainter {
  _CellPainter(this.sheet, this.col, this.row, this.opacity);

  final SheetInfo sheet;
  final int col;
  final int row;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final src = sheet.content(col, row);
    final scale = math.min(size.width / src.width, size.height / src.height);
    final w = src.width * scale, h = src.height * scale;
    canvas.drawImageRect(
      sheet.image,
      src,
      Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  @override
  bool shouldRepaint(_CellPainter old) =>
      old.sheet != sheet ||
      old.col != col ||
      old.row != row ||
      old.opacity != opacity;
}

/// Draws a complete character pose with a stable scale and ground anchor.
class SpriteFrame extends CustomPainter {
  SpriteFrame(this.sheet, this.col, this.row);

  final SheetInfo sheet;
  final int col;
  final int row;

  @override
  void paint(Canvas canvas, Size size) {
    final src = sheet.content(col, row);
    final scale = size.width / sheet.cellWidth;
    final width = src.width * scale;
    final height = src.height * scale;
    canvas.drawImageRect(
      sheet.image,
      src,
      Rect.fromLTWH(
        (size.width - width) / 2,
        size.height - height,
        width,
        height,
      ),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(SpriteFrame old) =>
      old.sheet != sheet || old.col != col || old.row != row;
}

/// Octagon outline shared by every panel and button.
Path chamferPath(Rect r, double c) => Path()
  ..moveTo(r.left + c, r.top)
  ..lineTo(r.right - c, r.top)
  ..lineTo(r.right, r.top + c)
  ..lineTo(r.right, r.bottom - c)
  ..lineTo(r.right - c, r.bottom)
  ..lineTo(r.left + c, r.bottom)
  ..lineTo(r.left, r.bottom - c)
  ..lineTo(r.left, r.top + c)
  ..close();

Path _diamond(Offset c, double w, double h) => Path()
  ..moveTo(c.dx, c.dy - h)
  ..lineTo(c.dx + w, c.dy)
  ..lineTo(c.dx, c.dy + h)
  ..lineTo(c.dx - w, c.dy)
  ..close();

/// Polished-metal gradient used for all gold trim.
Shader goldTrim(Rect rect) => ui.Gradient.linear(
  rect.topCenter,
  rect.bottomCenter,
  const [
    Palette.goldBright,
    Color(0xffcfa458),
    Palette.goldDeep,
    Palette.gold,
    Color(0xff6b4d1f),
  ],
  const [0, 0.22, 0.5, 0.74, 1],
);

void _paintGem(Canvas canvas, Offset c, double size, Color color) {
  canvas.drawPath(
    _diamond(c, size + 1.6, size + 1.6),
    Paint()..color = const Color(0xff1a1206),
  );
  canvas.drawPath(
    _diamond(c, size, size),
    Paint()
      ..shader = ui.Gradient.linear(
        c.translate(0, -size),
        c.translate(0, size),
        [Color.lerp(color, Colors.white, 0.6)!, color],
      ),
  );
}

/// The ornate frame behind every popup: drop shadow, dark enamel, faint
/// serpent-scale engraving, double gold trim and gem-set corners. Static, so
/// wrapping it in a RepaintBoundary makes it free after the first frame.
class OrnateFramePainter extends CustomPainter {
  const OrnateFramePainter({
    required this.accent,
    this.chamfer = 16,
    this.scales = true,
  });

  final Color accent;
  final double chamfer;
  final bool scales;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outline = chamferPath(rect, chamfer);
    canvas.drawPath(
      outline.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0xcc000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..color = accent.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          const [Color(0xff16261f), Color(0xff0c1612), Color(0xff070d0b)],
          const [0, 0.5, 1],
        ),
    );
    canvas.save();
    canvas.clipPath(outline);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, math.min(120, size.height)),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, 120), [
          accent.withValues(alpha: 0.2),
          accent.withValues(alpha: 0),
        ]),
    );
    if (scales) {
      final engraving = Path();
      const w = 26.0, h = 13.0;
      for (var row = 0; row * h < size.height + h; row++) {
        final shift = row.isOdd ? w / 2 : 0.0;
        for (var col = -1; col * w < size.width + w; col++) {
          final x = col * w + shift, y = row * h;
          engraving
            ..moveTo(x, y)
            ..quadraticBezierTo(x + w / 2, y + h * 1.7, x + w, y);
        }
      }
      canvas.drawPath(
        engraving,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = const Color(0x12e9c77d),
      );
    }
    canvas.restore();
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xff120c04),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = goldTrim(rect),
    );
    canvas.drawPath(
      chamferPath(rect.deflate(5), math.max(0, chamfer - 2.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Palette.gold.withValues(alpha: 0.35),
    );
    final c = chamfer / 2;
    for (final corner in [
      Offset(c, c),
      Offset(size.width - c, c),
      Offset(c, size.height - c),
      Offset(size.width - c, size.height - c),
    ]) {
      _paintGem(canvas, corner, 4.2, accent);
    }
  }

  @override
  bool shouldRepaint(OrnateFramePainter old) =>
      old.accent != accent || old.chamfer != chamfer || old.scales != scales;
}

/// A framed popup body. Its frame sits in its own layer and never repaints.
class OrnatePanel extends StatelessWidget {
  const OrnatePanel({
    super.key,
    required this.child,
    this.accent = Palette.leaf,
    this.padding = const EdgeInsets.fromLTRB(22, 16, 22, 16),
  });

  final Widget child;
  final Color accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: OrnateFramePainter(accent: accent),
    child: Padding(padding: padding, child: child),
  );
}

/// Eyebrow, gold engraved title, ornament rule and an optional line of text.
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.accent = Palette.leafBright,
    this.titleSize = 26,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Color accent;
  final double titleSize;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        eyebrow,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Ts.head(10.5, color: accent, spacing: 3, weight: FontWeight.w700),
      ),
      const SizedBox(height: 5),
      GradientText(
        title,
        colors: const [Palette.goldBright, Palette.gold, Color(0xffa97f3a)],
        style: Ts.head(
          titleSize,
          spacing: 1.6,
          shadows: const [
            Shadow(color: Color(0xcc000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
      ),
      const SizedBox(height: 6),
      OrnateDivider(color: accent),
      if (subtitle != null) ...[
        const SizedBox(height: 7),
        Text(subtitle!, textAlign: TextAlign.center, style: Ts.body(13.5)),
      ],
    ],
  );
}

/// Gold rule with a gem at its centre, fading out at both ends.
class OrnateDivider extends StatelessWidget {
  const OrnateDivider({super.key, this.color = Palette.leaf, this.width = 240});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: 12,
    child: CustomPaint(painter: _DividerPainter(color)),
  );
}

class _DividerPainter extends CustomPainter {
  const _DividerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.center(Offset.zero);
    final rule = Paint()
      ..strokeWidth = 1.2
      ..shader = ui.Gradient.linear(
        Offset(0, mid.dy),
        Offset(size.width, mid.dy),
        const [
          Color(0x00e9c77d),
          Palette.gold,
          Palette.gold,
          Color(0x00e9c77d),
        ],
        const [0, 0.42, 0.58, 1],
      );
    canvas.drawLine(Offset(0, mid.dy), Offset(size.width, mid.dy), rule);
    _paintGem(canvas, mid, 4.4, color);
  }

  @override
  bool shouldRepaint(_DividerPainter old) => old.color != color;
}

/// Full-screen dim behind popups. A flat veil plus a vignette replaces the old
/// BackdropFilter, which re-blurred the whole screen on every frame.
class ModalVeil extends StatelessWidget {
  const ModalVeil({
    super.key,
    required this.child,
    this.extra = 8,
    this.color = const Color(0xb8020605),
  });

  final Widget child;
  final double extra;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        radius: 1.15,
        colors: [color.withValues(alpha: color.a * 0.72), color],
      ),
    ),
    child: Padding(
      padding: safeInsets(context, extra: extra),
      child: Center(child: child),
    ),
  );
}

/// Fades a popup in and springs it up from slightly smaller.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutBack,
    builder: (context, t, child) => FadeTransition(
      opacity: AlwaysStoppedAnimation(t.clamp(0.0, 1.0)),
      child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
    ),
    child: child,
  );
}

enum GameButtonStyle { primary, secondary, danger, ghost }

/// The one button style used across menus and overlays: a forged metal plate
/// that physically sinks when pressed.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = GameButtonStyle.secondary,
    this.icon,
    this.subtitle,
    this.height,
    this.sheen = false,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final GameButtonStyle style;
  final Widget? icon;
  final double? height;

  /// Occasional light sweep; keep it to the one main call to action on screen.
  final bool sheen;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final primary = style == GameButtonStyle.primary;
    final danger = style == GameButtonStyle.danger;
    final fg = primary
        ? Palette.goldBright
        : danger
        ? const Color(0xffffc4bd)
        : Palette.cream;
    final height = widget.height ?? (primary ? 60 : 44);
    final labelSize = primary
        ? (height * 0.33).clamp(13.0, 20.0)
        : (height * 0.3).clamp(11.0, 13.5);
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapCancel: () => _setDown(false),
        onTapUp: (_) => _setDown(false),
        onTap: () {
          UiKit.onTap?.call();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.965 : 1,
          duration: const Duration(milliseconds: 90),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _PlatePainter(style, _down),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.sheen) const _Sheen(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 9),
                        ],
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Ts.head(
                                  labelSize,
                                  color: fg,
                                  spacing: primary ? 2.6 : 1.4,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xdd000000),
                                      blurRadius: 3,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 1),
                                Text(
                                  widget.subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Ts.body(
                                    11.5,
                                    color: fg.withValues(alpha: 0.85),
                                    weight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  const _PlatePainter(this.style, this.down);

  final GameButtonStyle style;
  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final primary = style == GameButtonStyle.primary;
    const c = 9.0;
    final outline = chamferPath(rect, c);
    if (style == GameButtonStyle.ghost) {
      canvas.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Palette.gold.withValues(alpha: down ? 0.75 : 0.4),
      );
      if (down) {
        canvas.drawPath(outline, Paint()..color = const Color(0x22e9c77d));
      }
      return;
    }
    if (primary) {
      canvas.drawPath(
        outline,
        Paint()
          ..color = const Color(0xff27e07a).withValues(alpha: down ? 0.3 : 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    final colors = switch (style) {
      GameButtonStyle.primary =>
        down
            ? const [Color(0xff0f7a44), Color(0xff0a5230), Color(0xff06331f)]
            : const [Color(0xff2bcf78), Color(0xff0f8a4d), Color(0xff075a32)],
      GameButtonStyle.danger =>
        down
            ? const [Color(0xff5c1219), Color(0xff400b11), Color(0xff2a070b)]
            : const [Color(0xff8c1f2a), Color(0xff5e131b), Color(0xff370a10)],
      _ =>
        down
            ? const [Color(0xff121d19), Color(0xff0c1512), Color(0xff080e0c)]
            : const [Color(0xff2a3a31), Color(0xff17231d), Color(0xff0d1512)],
    };
    canvas.drawPath(
      outline,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          colors,
          const [0, 0.55, 1],
        ),
    );
    if (!down) {
      // The upper bevel catching light.
      canvas.save();
      canvas.clipPath(outline);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.44),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, size.height * 0.44),
            const [Color(0x40ffffff), Color(0x06ffffff)],
          ),
      );
      canvas.restore();
    }
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xff120c04),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = primary ? 1.8 : 1.3
        ..shader = goldTrim(rect),
    );
    if (primary) {
      final mid = size.height / 2;
      _paintGem(canvas, Offset(c + 5, mid), 3.2, Palette.goldBright);
      _paintGem(canvas, Offset(size.width - c - 5, mid), 3.2, Palette.goldBright);
    }
  }

  @override
  bool shouldRepaint(_PlatePainter old) =>
      old.style != style || old.down != down;
}

/// A diagonal glint that crosses the button, then stays idle for a few
/// seconds; while idle its ticker is off and it costs no frames.
class _Sheen extends StatefulWidget {
  const _Sheen();

  @override
  State<_Sheen> createState() => _SheenState();
}

class _SheenState extends State<_Sheen> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  Timer? _idle;

  @override
  void initState() {
    super.initState();
    _sweep.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _idle = Timer(const Duration(milliseconds: 3200), () {
          _sweep.forward(from: 0);
        });
      }
    });
    _idle = Timer(const Duration(milliseconds: 700), () {
      _sweep.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _SheenPainter(_sweep)),
    ),
  );
}

class _SheenPainter extends CustomPainter {
  _SheenPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v <= 0 || v >= 1) return;
    canvas.clipPath(chamferPath(Offset.zero & size, 9));
    final x = -size.height + (size.width + size.height * 2) * v;
    canvas.drawPath(
      Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + 34, 0)
        ..lineTo(x + 34, size.height)
        ..close(),
      Paint()..color = const Color(0x38fff6d8),
    );
  }

  @override
  bool shouldRepaint(_SheenPainter old) => false;
}

/// Gold ring medallion used in the HUD and menus.
class RoundIconButton extends StatefulWidget {
  const RoundIconButton({
    super.key,
    required this.child,
    required this.onTap,
    this.size = 40,
    this.label,
  });

  final Widget child;
  final VoidCallback onTap;
  final double size;
  final String? label;

  @override
  State<RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<RoundIconButton> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapCancel: () => _setDown(false),
      onTapUp: (_) => _setDown(false),
      onTap: () {
        UiKit.onTap?.call();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: const MedallionPainter(),
            child: Center(child: widget.child),
          ),
        ),
      ),
    ),
  );
}

/// A dark enamel disc in a gold bezel.
class MedallionPainter extends CustomPainter {
  const MedallionPainter({this.accent = const Color(0xff1f3a2c)});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c.translate(0, 2),
      r,
      Paint()
        ..color = const Color(0xaa000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(c, r, Paint()..shader = goldTrim(rect));
    canvas.drawCircle(c, r - 1.8, Paint()..color = const Color(0xff120c04));
    canvas.drawCircle(
      c,
      r - 2.8,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(0, -r * 0.45),
          r * 1.5,
          [accent, const Color(0xff0a1210)],
        ),
    );
  }

  @override
  bool shouldRepaint(MedallionPainter old) => old.accent != accent;
}

/// Gradient text painted directly with a shader on the glyphs: unlike a
/// ShaderMask it needs no offscreen layer, so it stays cheap on every frame.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.style,
    required this.colors,
  });

  final String text;
  final TextStyle style;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: box.maxWidth);
      final size = painter.size;
      painter.text = TextSpan(
        text: text,
        style: style.copyWith(
          color: null,
          // A shader's coordinates are the canvas', so the painter below draws
          // at the widget's own origin for the gradient to span the glyphs.
          foreground: Paint()
            ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, size.height),
              colors,
              [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)],
            ),
        ),
      );
      painter.layout(maxWidth: box.maxWidth);
      return Semantics(
        label: text,
        child: CustomPaint(size: size, painter: _TextGlyphs(painter)),
      );
    },
  );
}

class _TextGlyphs extends CustomPainter {
  const _TextGlyphs(this.text);

  final TextPainter text;

  @override
  void paint(Canvas canvas, Size size) => text.paint(canvas, Offset.zero);

  @override
  bool shouldRepaint(_TextGlyphs old) => old.text != text;
}

/// Engraved progress bar in a gold-edged groove, optionally notched.
class RuneBar extends StatelessWidget {
  const RuneBar({
    super.key,
    required this.fill,
    required this.color,
    this.width = double.infinity,
    this.height = 8,
    this.notches = 0,
  });

  final double fill;
  final Color color;
  final double width;
  final double height;
  final int notches;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      painter: RuneBarPainter(
        fill: AlwaysStoppedAnimation(fill),
        color: color,
        notches: notches,
      ),
    ),
  );
}

class RuneBarPainter extends CustomPainter {
  RuneBarPainter({required this.fill, required this.color, this.notches = 0})
    : super(repaint: fill);

  final ValueListenable<double> fill;
  final Color color;
  final int notches;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    final groove = RRect.fromRectAndRadius(rect, radius);
    canvas.drawRRect(groove, Paint()..color = const Color(0xee050a08));
    final inner = rect.deflate(1.5);
    final amount = fill.value.clamp(0.0, 1.0);
    if (amount > 0) {
      final bar = Rect.fromLTWH(
        inner.left,
        inner.top,
        inner.width * amount,
        inner.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, radius),
        Paint()
          ..shader = ui.Gradient.linear(bar.topCenter, bar.bottomCenter, [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ], const [0, 0.45, 1]),
      );
    }
    if (notches > 1) {
      final tick = Paint()
        ..color = const Color(0xcc050a08)
        ..strokeWidth = 1;
      for (var i = 1; i < notches; i++) {
        final x = rect.width * i / notches;
        canvas.drawLine(Offset(x, 0), Offset(x, rect.height), tick);
      }
    }
    canvas.drawRRect(
      groove,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = goldTrim(rect),
    );
  }

  @override
  bool shouldRepaint(RuneBarPainter old) =>
      old.fill != fill || old.color != color || old.notches != notches;
}

/// Small name plate: enamel strip with gold edge, used for labels and stats.
class Plaque extends StatelessWidget {
  const Plaque({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.accent,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PlaquePainter(accent),
    child: Padding(padding: padding, child: child),
  );
}

class _PlaquePainter extends CustomPainter {
  const _PlaquePainter(this.accent);

  final Color? accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outline = chamferPath(rect, math.min(6, size.height / 3));
    canvas.drawPath(
      outline,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, const [
          Color(0xf01b2a23),
          Color(0xf00a1310),
        ]),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = accent?.withValues(alpha: 0.85) ?? const Color(0xcce9c77d),
    );
  }

  @override
  bool shouldRepaint(_PlaquePainter old) => old.accent != accent;
}

String formatTime(double seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds.floor() % 60).toString().padLeft(2, '0');
  final tenths = ((seconds * 10).floor() % 10);
  return '$minutes:$secs.$tenths';
}
