import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart' show FlameGame;
import 'package:flutter/material.dart' show Canvas, Color, Colors, Paint, PaintingStyle, RRect, Radius, Rect, Offset, VoidCallback, LinearGradient, Alignment;
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

  /// animateFall 已废弃，board 状态更新后直接由 refresh() + spawn 动画处理
  /// 保留签名兼容，直接透传
  void animateFall(List<GravityMove> moves, VoidCallback onComplete) {
    onComplete();
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

        // 先清除所有进行中的动画效果，避免残留动画干扰位置
        comp.clearEffects();

        comp.updateTile(tile);
        comp.row = r;
        comp.col = c;
        // 强制 snap 到正确格子位置（彻底消除重叠）
        comp.position = _getTilePosition(r, c).clone();
        comp.scale = Vector2.all(1.0);

        // 新生成的 tile 从正上方落入（spawn 动画）
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
    // 棋盘背景（深色圆角卡片）
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1040), Color(0xFF0F0C29)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(20)),
      bgPaint,
    );

    // 边框光晕
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y),
          const Radius.circular(20)),
      borderPaint,
    );

    // 网格线（极淡）
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int r = 0; r <= board.rows; r++) {
      final y = GameConstants.boardPadding + r * _adaptiveTileSize;
      canvas.drawLine(Offset(GameConstants.boardPadding, y),
          Offset(size.x - GameConstants.boardPadding, y), gridPaint);
    }
    for (int c = 0; c <= board.cols; c++) {
      final x = GameConstants.boardPadding + c * _adaptiveTileSize;
      canvas.drawLine(Offset(x, GameConstants.boardPadding),
          Offset(x, size.y - GameConstants.boardPadding), gridPaint);
    }

    super.render(canvas);
  }
}
