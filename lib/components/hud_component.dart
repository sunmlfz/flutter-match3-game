import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/score_manager.dart';
import '../game/level_config.dart';
import '../utils/constants.dart';

/// HUD 覆盖层（分数、步数、目标、道具栏）
class HudComponent extends PositionComponent {
  final ScoreManager scoreManager;
  final LevelConfig levelConfig;
  final VoidCallback onPause;
  final VoidCallback onReshuffle;

  int _timerRemaining = 0;
  bool _showLevelComplete = false;
  bool _showGameOver = false;
  int _resultScore = 0;
  int _resultStars = 0;
  VoidCallback? _onContinue;
  VoidCallback? _onRetry;

  HudComponent({
    required this.scoreManager,
    required this.levelConfig,
    required this.onPause,
    required this.onReshuffle,
  }) : super(anchor: Anchor.topLeft);

  @override
  FutureOr<void> onLoad() async {
    // HUD 全屏覆盖（不拦截棋盘区域点击）
    size = Vector2(360, 80);
    position = Vector2.zero();
    _timerRemaining = levelConfig.timeLimitSec;
  }

  void updateTimer(int remaining) {
    _timerRemaining = remaining;
  }

  void updateGoals() {
    // 触发重绘
  }

  void showLevelComplete({
    required int score,
    required int stars,
    required VoidCallback onContinue,
  }) {
    _showLevelComplete = true;
    _resultScore = score;
    _resultStars = stars;
    _onContinue = onContinue;
  }

  void showGameOver({
    required int score,
    required VoidCallback onRetry,
  }) {
    _showGameOver = true;
    _resultScore = score;
    _onRetry = onRetry;
  }

  @override
  void render(Canvas canvas) {
    // 顶部 HUD 背景
    final hudPaint = Paint()..color = GameConstants.hudColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, 360, 80), hudPaint);

    // 分数文字
    _drawText(canvas, '分数', 20, 12, fontSize: 11, color: Colors.white70);
    _drawText(canvas, '${scoreManager.score}', 20, 28, fontSize: 20, bold: true);

    // 步数 or 计时
    if (levelConfig.isTimedMode) {
      _drawText(canvas, '时间', 160, 12, fontSize: 11, color: Colors.white70);
      _drawText(canvas, '$_timerRemaining s', 160, 28, fontSize: 20, bold: true,
          color: _timerRemaining < 10 ? Colors.red : Colors.white);
    } else {
      _drawText(canvas, '步数', 160, 12, fontSize: 11, color: Colors.white70);
      _drawText(canvas, '${scoreManager.movesLeft}', 160, 28, fontSize: 20, bold: true);
    }

    // 连击
    if (scoreManager.combo > 1) {
      _drawText(canvas, '🔥 ×${scoreManager.combo}', 260, 20, fontSize: 16,
          color: Colors.orange);
    }

    // 关卡目标（简短显示）
    double yOff = 56;
    for (final goal in levelConfig.goals) {
      final text = '${goal.description}: ${goal.currentCount}/${goal.targetCount}';
      _drawText(canvas, text, 20, yOff, fontSize: 10,
          color: goal.isComplete ? Colors.greenAccent : Colors.white70);
      yOff += 14;
    }

    // 结算界面
    if (_showLevelComplete) {
      _renderLevelComplete(canvas);
    } else if (_showGameOver) {
      _renderGameOver(canvas);
    }
  }

  void _renderLevelComplete(Canvas canvas) {
    // 半透明遮罩
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 360, 800), overlayPaint);

    _drawText(canvas, '🎉 关卡完成！', 180, 280, fontSize: 28, bold: true,
        color: Colors.yellow, centered: true);
    _drawText(canvas, '分数: $_resultScore', 180, 330, fontSize: 22,
        color: Colors.white, centered: true);

    // 星级
    final stars = '⭐' * _resultStars + '☆' * (3 - _resultStars);
    _drawText(canvas, stars, 180, 370, fontSize: 32, centered: true);

    // 继续按钮
    _drawButton(canvas, '继续', 100, 430, 160, 48);
  }

  void _renderGameOver(Canvas canvas) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 360, 800), overlayPaint);

    _drawText(canvas, '😢 游戏结束', 180, 280, fontSize: 28, bold: true,
        color: Colors.red, centered: true);
    _drawText(canvas, '分数: $_resultScore', 180, 330, fontSize: 22,
        color: Colors.white, centered: true);

    _drawButton(canvas, '重试', 100, 400, 160, 48);
  }

  void _drawButton(Canvas canvas, String text, double x, double y, double w, double h) {
    final btnPaint = Paint()..color = GameConstants.accentColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(24)),
      btnPaint,
    );
    _drawText(canvas, text, x + w / 2, y + h / 2 - 8, fontSize: 18,
        bold: true, color: Colors.white, centered: true);
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y, {
    double fontSize = 14,
    bool bold = false,
    Color color = Colors.white,
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = centered ? x - painter.width / 2 : x;
    painter.paint(canvas, Offset(dx, y));
  }
}
