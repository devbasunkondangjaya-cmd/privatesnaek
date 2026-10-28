import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'image_store.dart';

/// Shared palette so every screen feels like the same game.
class Palette {
  static const ink = Color(0xff08231f);
  static const panel = Color(0xff13251e);
  static const panelLine = Color(0xff75df69);
  static const leaf = Color(0xff68c84c);
  static const leafBright = Color(0xff9bf07a);
  static const gold = Color(0xffffd76a);
  static const cream = Color(0xfffff2cd);
  static const mist = Color(0xffc3d1b9);
  static const danger = Color(0xffff5b55);
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

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: ImageStore.instance.revision,
    builder: (context, _, _) {
      final sheet = ImageStore.instance.sheet(file);
      return SizedBox(
        width: size,
        height: size,
        child: sheet == null
            ? null
            : CustomPaint(
                painter: _CellPainter(
                  sheet,
                  cell % cols,
                  cell ~/ cols,
                  opacity,
                ),
              ),
      );
    },
  );
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

enum GameButtonStyle { primary, secondary, danger, ghost }

/// The one button style used across menus and overlays.
class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = GameButtonStyle.secondary,
    this.icon,
    this.subtitle,
    this.height,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final GameButtonStyle style;
  final Widget? icon;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final primary = style == GameButtonStyle.primary;
    final danger = style == GameButtonStyle.danger;
    final ghost = style == GameButtonStyle.ghost;
    final fg = primary
        ? const Color(0xff102114)
        : danger
        ? const Color(0xffffb4ae)
        : const Color(0xffe6f2da);
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(primary ? 20 : 16),
      gradient: primary
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xffa8f27f), Color(0xff4fb54a)],
            )
          : null,
      color: primary
          ? null
          : ghost
          ? Colors.transparent
          : const Color(0xcc10201d),
      border: Border.all(
        color: primary
            ? const Color(0xffe4ffc6)
            : danger
            ? const Color(0x99ff5b55)
            : ghost
            ? Colors.transparent
            : const Color(0x995e8a55),
        width: primary ? 2 : 1.4,
      ),
      boxShadow: primary
          ? [
              BoxShadow(
                color: const Color(0xff5fe05a).withValues(alpha: 0.45),
                blurRadius: 22,
                spreadRadius: 1,
              ),
              const BoxShadow(color: Color(0xff1f5a26), offset: Offset(0, 4)),
            ]
          : null,
    );
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          UiKit.onTap?.call();
          onTap();
        },
        child: Container(
          height: height ?? (primary ? 62 : 46),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: decoration,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 10)],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: primary ? 20 : 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: primary ? 2.4 : 1.3,
                        color: fg,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: fg.withValues(alpha: 0.78),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button used in the HUD and menus.
class RoundIconButton extends StatelessWidget {
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        UiKit.onTap?.call();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xdd10201d),
          border: Border.all(color: const Color(0x8858e86c), width: 1.3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}

/// Gradient text for titles.
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
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.srcIn,
    shaderCallback: (bounds) => ui.Gradient.linear(
      Offset(0, bounds.top),
      Offset(0, bounds.bottom),
      colors,
      [for (var i = 0; i < colors.length; i++) i / (colors.length - 1)],
    ),
    child: Text(text, style: style, textAlign: TextAlign.center),
  );
}

String formatTime(double seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds.floor() % 60).toString().padLeft(2, '0');
  final tenths = ((seconds * 10).floor() % 10);
  return '$minutes:$secs.$tenths';
}
