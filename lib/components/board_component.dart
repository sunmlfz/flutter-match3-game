import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart' show FlameGame;
import 'package:flutter/material.dart' show Canvas, Color, Colors, Paint, PaintingStyle, RRect, Radius, Rect, Offset, VoidCallback;
import '../game/board.dart' show Board, GravityMove;
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
      // 第一次选中
      _selectedTile = comp;
      _selectedRow = row;
      _selectedCol = col;
      comp.select();
    } else {
      final r1 = _selectedRow!;
      final c1 = _selectedCol!;

      if (r1 == row && c1 == col) {
        // 点同一个，取消选中
        _selectedTile!.deselect();
        _selectedTile = null;
        _selectedRow = null;
        _selectedCol = null;
        return;
      }

      // 修复 Bug2：非相邻格子不触发交换，改为重新选中
      if (!board.areAdjacent(r1, c1, row, col)) {
        _selectedTile!.deselect();
        _selectedTile = comp;
        _selectedRow = row;
        _selectedCol = col;
        comp.select();
        return;
      }

      // 相邻才尝试交换
      _selectedTile!.deselect();
      _selectedTile = null;
      _selectedRow = null;
      _selectedCol = null;
      onSwap(r1, c1, row, col);
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

  /// 消除动画（加 guard 防止 onComplete 重复调用）
  void animateMatch(List<List<bool>> matched, VoidCallback onComplete) {
    bool _completed = false;
    void safeComplete() {
      if (_completed) return;
      _completed = true;
      onComplete();
    }

    int total = 0;
    int done = 0;

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        if (matched[r][c]) total++;
      }
    }

    if (total == 0) {
      safeComplete();
      return;
    }

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        if (matched[r][c]) {
          tileComponents[r][c].playMatchAnimation(() {
            done++;
            if (done >= total) safeComplete();
          });
        }
      }
    }

    // 超时兜底
    Future.delayed(const Duration(milliseconds: 500), safeComplete);
  }

  /// 下落动画（修复版）
  /// 根据 board.applyGravity() 返回的精确移动记录来动画，不依赖组件位置比较
  /// 同时更新 tileComponents 映射，保持组件与格子的正确对应关系
  void animateFall(List<GravityMove> moves, VoidCallback onComplete) {
    if (moves.isEmpty) {
      onComplete();
      return;
    }

    // 防止 onComplete 被重复调用（超时 + 正常完成都可能触发）
    bool _completed = false;
    void safeComplete() {
      if (_completed) return;
      _completed = true;
      onComplete();
    }

    // 先按照移动记录更新 tileComponents 映射（从下往上，避免覆盖）
    // moves 已按 fromRow 降序排列（applyGravity 从底部扫描）
    final sortedMoves = List<GravityMove>.from(moves)
      ..sort((a, b) => b.fromRow.compareTo(a.fromRow));

    for (final move in sortedMoves) {
      final comp = tileComponents[move.fromRow][move.col];
      tileComponents[move.toRow][move.col] = comp;
      // fromRow 的格子将由 fillEmpty 填充新 tile，暂置 null guard
      if (move.fromRow != move.toRow) {
        tileComponents[move.fromRow][move.col] = comp; // 暂时保留，refresh 会修正
      }
      comp.row = move.toRow;
    }

    int total = moves.length;
    int done = 0;
    for (final move in moves) {
      final comp = tileComponents[move.toRow][move.col];
      final targetPos = _getTilePosition(move.toRow, move.col);
      comp.playFallAnimation(targetPos, () {
        done++;
        if (done >= total) safeComplete();
      });
    }

    // 超时兜底（400ms），防止某帧回调未触发导致卡死
    Future.delayed(const Duration(milliseconds: 400), safeComplete);
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
