import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Canvas, Color, Colors, Paint, PaintingStyle, RRect, Radius, Rect;
import '../game/board.dart';
import '../game/score_manager.dart';
import '../utils/constants.dart';
import 'tile_component.dart';

typedef SwapCallback = void Function(int r1, int c1, int r2, int c2);
typedef PowerCallback = void Function(String power, int r, int c);

/// 棋盘 Flame 组件（包含交互逻辑）
class BoardComponent extends PositionComponent with TapCallbacks {
  final Board board;
  final ScoreManager scoreManager;
  final SwapCallback onSwap;
  final PowerCallback onPowerUsed;

  late List<List<TileComponent>> tileComponents;
  TileComponent? _selectedTile;
  int? _selectedRow;
  int? _selectedCol;

  String? _activePower; // 当前激活的道具

  BoardComponent({
    required this.board,
    required this.scoreManager,
    required this.onSwap,
    required this.onPowerUsed,
  }) : super(anchor: Anchor.topLeft);

  @override
  FutureOr<void> onLoad() async {
    // 计算棋盘位置（居中）
    final boardWidth = board.cols * GameConstants.tileSize + GameConstants.boardPadding * 2;
    final boardHeight = board.rows * GameConstants.tileSize + GameConstants.boardPadding * 2;

    // 居中放置（假设屏幕宽度360，高度720）
    position = Vector2(
      (360 - boardWidth) / 2,
      80, // HUD 占用顶部
    );
    size = Vector2(boardWidth, boardHeight);

    // 初始化所有方块组件
    tileComponents = List.generate(
      board.rows,
      (r) => List.generate(board.cols, (c) {
        final tile = board.get(r, c);
        final pos = _getTilePosition(r, c);
        final comp = TileComponent(tile: tile, row: r, col: c, position: pos);
        add(comp);
        return comp;
      }),
    );
  }

  // ─── 位置计算 ─────────────────────────────────────────────

  Vector2 _getTilePosition(int r, int c) {
    return Vector2(
      GameConstants.boardPadding + c * GameConstants.tileSize + GameConstants.tileSize / 2,
      GameConstants.boardPadding + r * GameConstants.tileSize + GameConstants.tileSize / 2,
    );
  }

  // ─── 触摸交互 ─────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    final localPos = event.localPosition;
    final row = ((localPos.y - GameConstants.boardPadding) / GameConstants.tileSize).floor();
    final col = ((localPos.x - GameConstants.boardPadding) / GameConstants.tileSize).floor();

    if (row < 0 || row >= board.rows || col < 0 || col >= board.cols) return;

    // 激活道具模式
    if (_activePower != null) {
      onPowerUsed(_activePower!, row, col);
      _activePower = null;
      return;
    }

    final comp = tileComponents[row][col];

    if (_selectedTile == null) {
      // 选中
      _selectedTile = comp;
      _selectedRow = row;
      _selectedCol = col;
      comp.select();
    } else {
      // 尝试交换
      final r1 = _selectedRow!;
      final c1 = _selectedCol!;
      _selectedTile!.deselect();
      _selectedTile = null;

      if (r1 == row && c1 == col) {
        // 点同一个，取消选中
        return;
      }

      onSwap(r1, c1, row, col);
      _selectedRow = null;
      _selectedCol = null;
    }
  }

  // ─── 动画 ─────────────────────────────────────────────────

  /// 交换动画
  void animateSwap(int r1, int c1, int r2, int c2, VoidCallback onComplete) {
    final comp1 = tileComponents[r1][c1];
    final comp2 = tileComponents[r2][c2];
    final pos1 = _getTilePosition(r1, c1);
    final pos2 = _getTilePosition(r2, c2);

    int done = 0;
    comp1.playSwapAnimation(pos2, () {
      done++;
      if (done == 2) {
        // 交换组件引用
        tileComponents[r1][c1] = comp2;
        tileComponents[r2][c2] = comp1;
        comp1.row = r2; comp1.col = c2;
        comp2.row = r1; comp2.col = c1;
        onComplete();
      }
    });
    comp2.playSwapAnimation(pos1, () {
      done++;
      if (done == 2) {
        tileComponents[r1][c1] = comp2;
        tileComponents[r2][c2] = comp1;
        comp1.row = r2; comp1.col = c2;
        comp2.row = r1; comp2.col = c1;
        onComplete();
      }
    });
  }

  /// 无效交换抖动
  void animateInvalidSwap(int r1, int c1, int r2, int c2) {
    tileComponents[r1][c1].shake();
    tileComponents[r2][c2].shake();
  }

  /// 消除动画
  void animateMatch(List<List<bool>> matched, VoidCallback onComplete) {
    int total = 0;
    int done = 0;

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        if (matched[r][c]) total++;
      }
    }

    if (total == 0) {
      onComplete();
      return;
    }

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        if (matched[r][c]) {
          tileComponents[r][c].playMatchAnimation(() {
            done++;
            if (done == total) onComplete();
          });
        }
      }
    }
  }

  /// 下落动画
  void animateFall(VoidCallback onComplete) {
    int moving = 0;
    int done = 0;

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final tile = board.get(r, c);
        final comp = tileComponents[r][c];
        if (comp.tile != tile) {
          final targetPos = _getTilePosition(r, c);
          if (comp.position != targetPos) {
            moving++;
            comp.playFallAnimation(targetPos, () {
              done++;
              if (done == moving) onComplete();
            });
          }
        }
      }
    }

    if (moving == 0) onComplete();
  }

  /// 重排动画
  void animateReshuffle(VoidCallback onComplete) {
    // 闪烁效果后重排
    Future.delayed(const Duration(milliseconds: 300), onComplete);
  }

  // ─── 刷新显示 ─────────────────────────────────────────────

  void refresh() {
    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final tile = board.get(r, c);
        final comp = tileComponents[r][c];
        comp.updateTile(tile);
        comp.row = r;
        comp.col = c;
        comp.position = _getTilePosition(r, c);

        // 新生成的元素播放入场动画
        if (tile?.isNew == true) {
          comp.playSpawnAnimation();
          tile?.isNew = false;
        }
      }
    }
  }

  /// 激活道具
  void activatePower(String power) {
    _activePower = power;
    _selectedTile?.deselect();
    _selectedTile = null;
  }

  // ─── 背景渲染 ─────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    // 棋盘背景
    final bgPaint = Paint()..color = GameConstants.boardBackgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(16),
      ),
      bgPaint,
    );

    // 网格线
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int r = 0; r <= board.rows; r++) {
      final y = GameConstants.boardPadding + r * GameConstants.tileSize;
      canvas.drawLine(
        Offset(GameConstants.boardPadding, y),
        Offset(size.x - GameConstants.boardPadding, y),
        gridPaint,
      );
    }
    for (int c = 0; c <= board.cols; c++) {
      final x = GameConstants.boardPadding + c * GameConstants.tileSize;
      canvas.drawLine(
        Offset(x, GameConstants.boardPadding),
        Offset(x, size.y - GameConstants.boardPadding),
        gridPaint,
      );
    }

    super.render(canvas);
  }
}
