import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart' show FlameGame;
import 'package:flutter/material.dart' show Canvas, Color, Colors, Paint, PaintingStyle, RRect, Radius, Rect, Offset, VoidCallback;
import '../game/board.dart';
import '../game/score_manager.dart';
import '../utils/constants.dart';
import 'tile_component.dart';

typedef SwapCallback = void Function(int r1, int c1, int r2, int c2);
typedef PowerCallback = void Function(String power, int r, int c);

/// 棋盘 Flame 组件（包含交互逻辑）
class BoardComponent extends PositionComponent with TapCallbacks, HasGameRef<FlameGame> {
  final Board board;
  final ScoreManager scoreManager;
  final SwapCallback onSwap;
  final PowerCallback onPowerUsed;

  late List<List<TileComponent>> tileComponents;
  TileComponent? _selectedTile;
  int? _selectedRow;
  int? _selectedCol;

  String? _activePower; // 当前激活的道具
  double _adaptiveTileSize = GameConstants.tileSize;

  BoardComponent({
    required this.board,
    required this.scoreManager,
    required this.onSwap,
    required this.onPowerUsed,
  }) : super(anchor: Anchor.topLeft);

  @override
  FutureOr<void> onLoad() async {
    // 使用实际屏幕尺寸居中棋盘（修复左右截断问题）
    final screenW = gameRef.size.x;
    final screenH = gameRef.size.y;

    // 自适应 tileSize：让棋盘宽度不超过屏幕，高度留出 HUD 和道具栏
    final availableW = screenW - GameConstants.boardPadding * 2;
    final availableH = screenH - 80 - 80 - GameConstants.boardPadding * 2; // 80 top HUD, 80 bottom bar
    final adaptiveTileSize = (availableW / board.cols).clamp(
        16.0, (availableH / board.rows).clamp(16.0, GameConstants.tileSize));

    final boardWidth = board.cols * adaptiveTileSize + GameConstants.boardPadding * 2;
    final boardHeight = board.rows * adaptiveTileSize + GameConstants.boardPadding * 2;

    position = Vector2(
      (screenW - boardWidth) / 2,
      80, // HUD 顶部占用
    );
    size = Vector2(boardWidth, boardHeight);
    _adaptiveTileSize = adaptiveTileSize;

    // 初始化所有方块组件
    tileComponents = List.generate(
      board.rows,
      (r) => List.generate(board.cols, (c) {
        final tile = board.get(r, c);
        final pos = _getTilePosition(r, c);
        final comp = TileComponent(
            tile: tile, row: r, col: c, position: pos,
            tileSize: _adaptiveTileSize);
        add(comp);
        return comp;
      }),
    );
  }

  // ─── 位置计算 ─────────────────────────────────────────────

  Vector2 _getTilePosition(int r, int c) {
    return Vector2(
      GameConstants.boardPadding + c * _adaptiveTileSize + _adaptiveTileSize / 2,
      GameConstants.boardPadding + r * _adaptiveTileSize + _adaptiveTileSize / 2,
    );
  }

  // ─── 触摸交互 ─────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    final localPos = event.localPosition;
    // 修复：用自适应 tileSize 做坐标映射，不能用常量
    final row = ((localPos.y - GameConstants.boardPadding) / _adaptiveTileSize).floor();
    final col = ((localPos.x - GameConstants.boardPadding) / _adaptiveTileSize).floor();

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
  /// 修复：原来用 comp.tile != tile 引用比较不可靠，改为直接比较视觉位置与目标位置
  /// 用 epsilon 避免浮点误差导致误判，同时加安全超时防止卡死
  void animateFall(VoidCallback onComplete) {
    const epsilon = 2.0; // 位置误差容忍（px）
    int moving = 0;
    int done = 0;

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final comp = tileComponents[r][c];
        final targetPos = _getTilePosition(r, c);
        final dx = (comp.position.x - targetPos.x).abs();
        final dy = (comp.position.y - targetPos.y).abs();
        if (dx > epsilon || dy > epsilon) {
          moving++;
          comp.playFallAnimation(targetPos, () {
            done++;
            if (done >= moving) onComplete();
          });
        }
      }
    }

    if (moving == 0) {
      onComplete();
    } else {
      // 安全超时：若动画回调 600ms 内未全部触发，强制继续（防止游戏卡死）
      Future.delayed(const Duration(milliseconds: 600), () {
        if (done < moving) onComplete();
      });
    }
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
