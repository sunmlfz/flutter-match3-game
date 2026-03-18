import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart'
    show
        Colors,
        Color,
        BorderRadius,
        RRect,
        Radius,
        Rect,
        LinearGradient,
        SweepGradient,
        Alignment,
        Curves,
        Canvas,
        Paint,
        PaintingStyle,
        Offset,
        Gradient,
        VoidCallback;
import '../game/tile.dart';
import '../utils/constants.dart';

/// 单个方块的 Flame 组件（负责渲染和动画）
class TileComponent extends PositionComponent {
  Tile? tile;
  int row;
  int col;

  bool _isSelected = false;
  double _shakeOffset = 0;

  static const double _cornerRadius = 10.0;

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

    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_cornerRadius));

    // 底色
    final baseColor = _getTileColor();
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRRect(rrect, bgPaint);

    // 障碍物覆盖层
    if (tile!.obstacle != ObstacleType.none) {
      _renderObstacle(canvas, rect, rrect);
    }

    // 特殊元素标记
    if (tile!.isSpecial) {
      _renderSpecialIndicator(canvas, rect);
    }

    // 选中高亮
    if (_isSelected) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(rrect, highlightPaint);
    }

    // 光泽效果（顶部高光）
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.25), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y / 2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y / 2),
        const Radius.circular(_cornerRadius),
      ),
      glossPaint,
    );
  }

  Color _getTileColor() {
    if (tile == null) return Colors.transparent;
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

  void _renderObstacle(Canvas canvas, Rect rect, RRect rrect) {
    final overlayPaint = Paint();
    switch (tile!.obstacle) {
      case ObstacleType.ice:
        overlayPaint.color = GameConstants.iceColor.withOpacity(0.6);
        canvas.drawRRect(rrect, overlayPaint);
        // 冰裂纹
        if (tile!.iceLayer >= 2) {
          _drawCracks(canvas, rect, Colors.lightBlue.shade200);
        }
        break;
      case ObstacleType.rock:
        overlayPaint.color = GameConstants.rockColor.withOpacity(0.8);
        canvas.drawRRect(rrect, overlayPaint);
        break;
      case ObstacleType.chain:
        _drawChain(canvas, rect);
        break;
      case ObstacleType.slime:
        overlayPaint.color = GameConstants.slimeColor.withOpacity(0.5);
        canvas.drawRRect(rrect, overlayPaint);
        break;
      default:
        break;
    }
  }

  void _drawCracks(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.5;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    canvas.drawLine(Offset(cx - 10, cy - 10), Offset(cx + 5, cy + 8), paint);
    canvas.drawLine(Offset(cx + 5, cy - 5), Offset(cx - 5, cy + 12), paint);
  }

  void _drawChain(Canvas canvas, Rect rect) {
    final chainPaint = Paint()
      ..color = GameConstants.chainColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 30, height: 20), chainPaint);
    canvas.drawLine(Offset(cx - 15, cy), Offset(cx - 30, cy), chainPaint);
    canvas.drawLine(Offset(cx + 15, cy), Offset(cx + 30, cy), chainPaint);
  }

  void _renderSpecialIndicator(Canvas canvas, Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (tile!.special) {
      case SpecialType.lineH:
        // 横向箭头
        canvas.drawLine(Offset(4, cy), Offset(rect.right - 4, cy), paint);
        canvas.drawLine(Offset(rect.right - 10, cy - 6), Offset(rect.right - 4, cy), paint);
        canvas.drawLine(Offset(rect.right - 10, cy + 6), Offset(rect.right - 4, cy), paint);
        break;
      case SpecialType.lineV:
        // 纵向箭头
        canvas.drawLine(Offset(cx, 4), Offset(cx, rect.bottom - 4), paint);
        canvas.drawLine(Offset(cx - 6, rect.bottom - 10), Offset(cx, rect.bottom - 4), paint);
        canvas.drawLine(Offset(cx + 6, rect.bottom - 10), Offset(cx, rect.bottom - 4), paint);
        break;
      case SpecialType.bomb:
        // 爆炸圆
        canvas.drawCircle(Offset(cx, cy), 12, paint);
        canvas.drawLine(Offset(cx, cy - 12), Offset(cx + 6, cy - 18), paint);
        break;
      case SpecialType.colorBomb:
        // 彩虹圆
        final rainbowPaint = Paint()
          ..shader = const SweepGradient(
            colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 15))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(Offset(cx, cy), 15, rainbowPaint);
        break;
      default:
        break;
    }
  }

  // ─── 动画 ─────────────────────────────────────────────────

  /// 选中动画（放大）
  void select() {
    _isSelected = true;
    add(ScaleEffect.to(
      Vector2.all(1.1),
      EffectController(duration: 0.15),
    ));
  }

  /// 取消选中
  void deselect() {
    _isSelected = false;
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.1),
    ));
  }

  /// 无效交换抖动
  void shake() {
    add(SequenceEffect([
      MoveEffect.by(Vector2(8, 0), EffectController(duration: 0.05)),
      MoveEffect.by(Vector2(-16, 0), EffectController(duration: 0.05)),
      MoveEffect.by(Vector2(8, 0), EffectController(duration: 0.05)),
    ]));
  }

  /// 消除动画（缩小消失）
  void playMatchAnimation(VoidCallback? onComplete) {
    add(ScaleEffect.to(
      Vector2.zero(),
      EffectController(duration: 0.2),
      onComplete: () {
        tile = null;
        onComplete?.call();
      },
    ));
  }

  /// 下落动画
  void playFallAnimation(Vector2 targetPosition, VoidCallback? onComplete) {
    add(MoveToEffect(
      targetPosition,
      EffectController(duration: 0.25, curve: Curves.easeIn),
      onComplete: onComplete,
    ));
  }

  /// 交换动画
  void playSwapAnimation(Vector2 targetPosition, VoidCallback? onComplete) {
    add(MoveToEffect(
      targetPosition,
      EffectController(duration: 0.2),
      onComplete: onComplete,
    ));
  }

  /// 新元素从上方落入
  void playSpawnAnimation() {
    final origY = position.y;
    position.y -= GameConstants.tileSize * 3;
    add(MoveToEffect(
      Vector2(position.x, origY),
      EffectController(duration: 0.3, curve: Curves.bounceOut),
    ));
  }

  void updateTile(Tile? newTile) {
    tile = newTile;
    scale = Vector2.all(1.0);
    _isSelected = false;
  }

  /// 清除所有进行中的动画效果（refresh 前调用，避免残留效果干扰位置）
  void clearEffects() {
    // 移除所有 Effect 子组件，防止残留动画覆盖 snap 后的位置
    final effects = children.whereType<Effect>().toList();
    for (final e in effects) {
      e.removeFromParent();
    }
  }
}
