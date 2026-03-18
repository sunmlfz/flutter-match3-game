import "tile.dart";
import 'dart:async';
import 'package:flame/game.dart';
import '../components/board_component.dart';
import '../components/hud_component.dart';
import 'board.dart';
import 'level_config.dart';
import 'score_manager.dart';

/// 游戏状态
enum GameState {
  loading,
  playing,
  paused,
  animating,  // 正在执行消除/下落动画
  levelComplete,
  gameOver,
}

/// 主游戏类（继承 FlameGame）
class Match3Game extends FlameGame {
  final int level;
  final void Function(int score, int stars)? onLevelComplete;
  final void Function()? onGameOver;

  late LevelConfig levelConfig;
  late Board board;
  late ScoreManager scoreManager;
  late BoardComponent boardComponent;
  late HudComponent hudComponent;

  GameState gameState = GameState.loading;
  int elapsedSeconds = 0;
  Timer? _gameTimer;

  Match3Game({
    required this.level,
    this.onLevelComplete,
    this.onGameOver,
  });

  @override
  FutureOr<void> onLoad() async {
    levelConfig = Levels.get(level);
    board = Board(
        rows: 8,
        cols: 8);
    scoreManager = ScoreManager(config: levelConfig);

    // 应用关卡障碍物设置
    _applyLevelObstacles();

    // 创建棋盘组件
    boardComponent = BoardComponent(
      board: board,
      scoreManager: scoreManager,
      onSwap: _handleSwap,
      onPowerUsed: _handlePowerUsed,
    );
    await add(boardComponent);

    // 创建 HUD 组件
    hudComponent = HudComponent(
      scoreManager: scoreManager,
      levelConfig: levelConfig,
      onPause: _togglePause,
      onReshuffle: _handleReshuffle,
    );
    await add(hudComponent);

    // 启动计时器（限时模式）
    if (levelConfig.isTimedMode) {
      _startTimer();
    }

    gameState = GameState.playing;
  }

  void _applyLevelObstacles() {
    for (final pos in levelConfig.icePositions) {
      board.setIce(pos[0], pos[1], layers: pos.length > 2 ? pos[2] : 1);
    }
    for (final pos in levelConfig.rockPositions) {
      board.setRock(pos[0], pos[1]);
    }
    for (final pos in levelConfig.chainPositions) {
      board.setChain(pos[0], pos[1]);
    }
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameState != GameState.playing) return;
      elapsedSeconds++;
      hudComponent.updateTimer(levelConfig.timeLimitSec - elapsedSeconds);
      if (elapsedSeconds >= levelConfig.timeLimitSec) {
        _checkGameEnd();
      }
    });
  }

  // ─── 游戏逻辑 ─────────────────────────────────────────────

  void _handleSwap(int r1, int c1, int r2, int c2) {
    if (gameState != GameState.playing) return;

    if (!board.isValidSwap(r1, c1, r2, c2)) {
      boardComponent.animateInvalidSwap(r1, c1, r2, c2);
      return;
    }

    gameState = GameState.animating;
    scoreManager.recordMove();
    board.swap(r1, c1, r2, c2);

    boardComponent.animateSwap(r1, c1, r2, c2, () {
      _processCascade(0);
    });
  }

  void _processCascade(int cascadeLevel) {
    final result = board.findMatches(cascadeLevel: cascadeLevel);
    if (!result.hasMatch) {
      // 无匹配 → 检查是否无可用移动
      if (!board.hasPossibleMove()) {
        boardComponent.animateReshuffle(() {
          board.reshuffle();
          boardComponent.refresh();
          gameState = GameState.playing;
        });
      } else {
        scoreManager.resetCombo();
        boardComponent.refresh();
        gameState = GameState.playing;
        _checkGameEnd();
      }
      return;
    }

    // 有匹配 → 动画 + 消除 + 下落
    scoreManager.incrementCombo();
    scoreManager.addMatchScore(result.score, cascadeLevel);

    // 追踪目标进度
    _trackGoals(result);

    boardComponent.animateMatch(result.matched, () {
      // ★ 在 removeMatched 前保存快照，确保统计正确
      final snapshot = _snapshotMatched(result.matched);

      board.removeMatched(result.matched);
      board.placeSpecials(result);
      // ★ 获取精确下落记录，传给 animateFall
      final moves = board.applyGravity();

      _trackGoalsFromSnapshot(snapshot);

      boardComponent.animateFall(moves, () {
        board.fillEmpty();
        boardComponent.refresh();

        Future.delayed(const Duration(milliseconds: 100), () {
          _processCascade(cascadeLevel + 1);
        });
      });
    });
  }

  /// 在消除前对将要被消除的格子做快照
  /// 返回 [{color, obstacle}] 列表，只包含 iceLayer≤1 和非石块（即真正会被移除的）
  List<_TileSnapshot> _snapshotMatched(List<List<bool>> matched) {
    final snaps = <_TileSnapshot>[];
    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        if (!matched[r][c]) continue;
        final tile = board.grid[r][c];
        if (tile == null) continue;
        // 石块不会被直接消除，跳过
        if (tile.obstacle == ObstacleType.rock) continue;
        // 冰块多层时本次只减一层，不算做消除
        if (tile.obstacle == ObstacleType.ice && tile.iceLayer > 1) continue;
        snaps.add(_TileSnapshot(tile.color, tile.obstacle));
      }
    }
    return snaps;
  }

  void _trackGoalsFromSnapshot(List<_TileSnapshot> snaps) {
    for (final snap in snaps) {
      scoreManager.recordColorMatch(snap.color, 1);
      if (snap.obstacle == ObstacleType.ice) scoreManager.recordIceCleared(1);
      if (snap.obstacle == ObstacleType.rock) scoreManager.recordRockCleared(1);
    }
    hudComponent.updateGoals();
  }

  // 保留旧方法签名兼容（不再使用）
  void _trackGoals(MatchResult result) {
    _trackGoalsFromSnapshot(_snapshotMatched(result.matched));
  }

  void _checkGameEnd() {
    if (scoreManager.allGoalsComplete) {
      _triggerLevelComplete();
    } else if (scoreManager.outOfMoves ||
        (levelConfig.isTimedMode && elapsedSeconds >= levelConfig.timeLimitSec)) {
      _triggerGameOver();
    }
  }

  void _triggerLevelComplete() {
    _gameTimer?.cancel();
    scoreManager.applyEndBonus();
    gameState = GameState.levelComplete;
    hudComponent.showLevelComplete(
      score: scoreManager.score,
      stars: scoreManager.stars,
      onContinue: () => onLevelComplete?.call(scoreManager.score, scoreManager.stars),
    );
  }

  void _triggerGameOver() {
    _gameTimer?.cancel();
    gameState = GameState.gameOver;
    hudComponent.showGameOver(
      score: scoreManager.score,
      onRetry: () => onGameOver?.call(),
    );
  }

  // ─── 道具 ─────────────────────────────────────────────────

  void _handlePowerUsed(String powerType, int r, int c) {
    if (gameState != GameState.playing) return;

    gameState = GameState.animating;
    switch (powerType) {
      case 'hammer':
        board.grid[r][c] = null;
        scoreManager.addMatchScore(100, 0);
        break;
      case 'bomb':
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr >= 0 && nr < board.rows && nc >= 0 && nc < board.cols) {
              board.grid[nr][nc] = null;
            }
          }
        }
        scoreManager.addMatchScore(500, 0);
        break;
      case 'reshuffle':
        board.reshuffle();
        break;
    }

    scoreManager.recordMove();
    board.applyGravity();
    board.fillEmpty();
    boardComponent.refresh();
    gameState = GameState.playing;
    _checkGameEnd();
  }

  void _handleReshuffle() {
    if (gameState != GameState.playing) return;
    _handlePowerUsed('reshuffle', 0, 0);
  }

  void _togglePause() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      _gameTimer?.cancel();
    } else if (gameState == GameState.paused) {
      gameState = GameState.playing;
      if (levelConfig.isTimedMode) _startTimer();
    }
  }

  @override
  void onRemove() {
    _gameTimer?.cancel();
    super.onRemove();
  }
}

/// 消除前的瓦片快照（用于准确统计目标进度）
class _TileSnapshot {
  final TileColor color;
  final ObstacleType obstacle;
  _TileSnapshot(this.color, this.obstacle);
}
