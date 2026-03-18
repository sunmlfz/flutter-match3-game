import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show
        Canvas,
        Color,
        Colors,
        Paint,
        PaintingStyle,
        Offset,
        Rect,
        RRect,
        Radius,
        LinearGradient,
        Alignment,
        HSLColor,
        VoidCallback,
        Curves,
        TextPainter,
        TextSpan,
        TextStyle,
        TextDirection,
        FontWeight,
        MaskFilter,
        BlurStyle;
import '../game/tile.dart';
import '../utils/constants.dart';

/// 单个水果方块的 Flame 组件
class TileComponent extends PositionComponent {
  Tile? tile;
  int row;
  int col;
  bool _isSelected = false;

  static const double _cornerRadius = 14.0;

  TileComponent({
    required this.tile,
    required this.row,
    required this.col,
    required Vector2 position,
    double tileSize = GameConstants.tileSize,
  }) : super(
          position: position,
          size: Vector2.all(tileSize - GameConstants.tilePadding * 2),
          anchor: Anchor.center,
        );

  // ─── 渲染 ─────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (tile == null) return;

    final w = size.x;
    final h = size.y;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_cornerRadius));

    _drawShadow(canvas, rect);
    _drawBackground(canvas, rrect);
    _drawObstacle(canvas, rect, rrect);
    _drawFruitEmoji(canvas, rect);
    _drawSpecialIndicator(canvas, rect);
    if (_isSelected) _drawSelectionRing(canvas, rrect);
  }

  void _drawShadow(Canvas canvas, Rect rect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.shift(const Offset(0, 3)), const Radius.circular(_cornerRadius)),
      shadowPaint,
    );
  }

  void _drawBackground(Canvas canvas, RRect rrect) {
    final baseColor = _getBaseColor();
    final lighterColor = _lighten(baseColor, 0.15);

    // 渐变背景
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lighterColor, baseColor],
      ).createShader(rrect.outerRect);
    canvas.drawRRect(rrect, gradPaint);

    // 顶部高光
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y * 0.5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.x - 4, size.y * 0.5 - 2),
        const Radius.circular(_cornerRadius - 2),
      ),
      highlightPaint,
    );
  }

  void _drawObstacle(Canvas canvas, Rect rect, RRect rrect) {
    if (tile == null || tile!.obstacle == ObstacleType.none) return;

    switch (tile!.obstacle) {
      case ObstacleType.ice:
        // 冰蓝色覆盖层 + 雪花
        final icePaint = Paint()..color = GameConstants.iceColor.withValues(alpha: 0.55);
        canvas.drawRRect(rrect, icePaint);
        _drawText(canvas, tile!.iceLayer >= 2 ? '❄️❄️' : '❄️',
            rect.center.dx, rect.center.dy - 6, 16);
        break;
      case ObstacleType.rock:
        final rockPaint = Paint()..color = GameConstants.rockColor.withValues(alpha: 0.75);
        canvas.drawRRect(rrect, rockPaint);
        _drawText(canvas, '🪨', rect.center.dx, rect.center.dy - 8, 20);
        break;
      case ObstacleType.chain:
        _drawText(canvas, '⛓️', rect.center.dx, rect.center.dy - 8, 18);
        break;
      case ObstacleType.slime:
        final slimePaint = Paint()..color = GameConstants.slimeColor.withValues(alpha: 0.45);
        canvas.drawRRect(rrect, slimePaint);
        break;
      default:
        break;
    }
  }

  void _drawFruitEmoji(Canvas canvas, Rect rect) {
    if (tile == null) return;
    if (tile!.obstacle == ObstacleType.rock) return; // 石块不显示水果

    String emoji;
    double fontSize;

    if (tile!.isSpecial) {
      switch (tile!.special) {
        case SpecialType.lineH:
          emoji = '⚡';
          fontSize = size.x * 0.38;
          _drawText(canvas, emoji, rect.center.dx, rect.center.dy - fontSize * 0.55, fontSize);
          _drawText(canvas, '↔', rect.center.dx, rect.center.dy + fontSize * 0.2, fontSize * 0.45,
              color: Colors.white.withValues(alpha: 0.9));
          return;
        case SpecialType.lineV:
          emoji = '⚡';
          fontSize = size.x * 0.38;
          _drawText(canvas, emoji, rect.center.dx, rect.center.dy - fontSize * 0.55, fontSize);
          _drawText(canvas, '↕', rect.center.dx, rect.center.dy + fontSize * 0.2, fontSize * 0.45,
              color: Colors.white.withValues(alpha: 0.9));
          return;
        case SpecialType.bomb:
          _drawText(canvas, '💥', rect.center.dx, rect.center.dy - size.x * 0.22, size.x * 0.45);
          return;
        case SpecialType.colorBomb:
          _drawText(canvas, '🌈', rect.center.dx, rect.center.dy - size.x * 0.22, size.x * 0.45);
          return;
        default:
          break;
      }
    }

    emoji = GameConstants.tileEmojis[tile!.color.index] ?? '🍓';
    fontSize = size.x * 0.48;
    _drawText(canvas, emoji, rect.center.dx, rect.center.dy - fontSize * 0.52, fontSize);
  }

  void _drawSpecialIndicator(Canvas canvas, Rect rect) {
    if (tile == null || !tile!.isSpecial) return;
    // 特殊元素边框光晕
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(_cornerRadius)),
      glowPaint,
    );
  }

  void _drawSelectionRing(Canvas canvas, RRect rrect) {
    // 选中高亮边框
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect, ringPaint);

    // 外层辉光
    final glowPaint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect, glowPaint);
  }

  void _drawText(Canvas canvas, String text, double cx, double cy, double fontSize,
      {Color? color}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color ?? Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(cx - painter.width / 2, cy));
  }

  // ─── 颜色工具 ─────────────────────────────────────────────

  Color _getBaseColor() {
    if (tile == null) return Colors.grey;
    switch (tile!.special) {
      case SpecialType.lineH:
      case SpecialType.lineV:
        return GameConstants.lineBreakerColor;
      case SpecialType.bomb:
        return GameConstants.bombColor;
      case SpecialType.colorBomb:
        return GameConstants.colorBombColor;
      default:
        return GameConstants.tileColors[tile!.color.index] ?? Colors.grey;
    }
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  // ─── 动画 ─────────────────────────────────────────────────

  void select() {
    _isSelected = true;
    add(ScaleEffect.to(Vector2.all(1.12),
        EffectController(duration: 0.12, curve: Curves.easeOut)));
  }

  void deselect() {
    _isSelected = false;
    add(ScaleEffect.to(Vector2.all(1.0),
        EffectController(duration: 0.1)));
  }

  void shake() {
    add(SequenceEffect([
      MoveEffect.by(Vector2(8, 0), EffectController(duration: 0.06)),
      MoveEffect.by(Vector2(-14, 0), EffectController(duration: 0.06)),
      MoveEffect.by(Vector2(6, 0), EffectController(duration: 0.06)),
    ]));
  }

  void playMatchAnimation(VoidCallback? onComplete) {
    add(SequenceEffect([
      ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.08)),
      ScaleEffect.to(Vector2.zero(), EffectController(duration: 0.15)),
    ], onComplete: () {
      tile = null;
      onComplete?.call();
    }));
  }

  void playFallAnimation(Vector2 targetPosition, VoidCallback? onComplete) {
    add(MoveToEffect(targetPosition,
        EffectController(duration: 0.28, curve: Curves.easeIn),
        onComplete: onComplete));
  }

  void playSwapAnimation(Vector2 targetPosition, VoidCallback? onComplete) {
    add(MoveToEffect(targetPosition,
        EffectController(duration: 0.18, curve: Curves.easeInOut),
        onComplete: onComplete));
  }

  void playSpawnAnimation() {
    final origY = position.y;
    position = Vector2(position.x, origY - GameConstants.tileSize * 4);
    scale = Vector2.all(0.5);
    add(MoveToEffect(Vector2(position.x, origY),
        EffectController(duration: 0.32, curve: Curves.bounceOut)));
    add(ScaleEffect.to(Vector2.all(1.0),
        EffectController(duration: 0.2)));
  }

  void updateTile(Tile? newTile) {
    tile = newTile;
    scale = Vector2.all(1.0);
    _isSelected = false;
  }

  /// 清除所有进行中的动画效果
  void clearEffects() {
    final effects = children.whereType<Effect>().toList();
    for (final e in effects) {
      e.removeFromParent();
    }
  }
}


