import 'level_config.dart';

/// 评分与关卡进度管理
class ScoreManager {
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _movesUsed = 0;
  int _specialsTriggered = 0;

  final LevelConfig config;

  ScoreManager({required this.config});

  // ─── Getters ─────────────────────────────────────────────

  int get score => _score;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get movesUsed => _movesUsed;
  int get movesLeft => config.maxMoves > 0 ? config.maxMoves - _movesUsed : -1;
  int get specialsTriggered => _specialsTriggered;

  // ─── 更新分数 ─────────────────────────────────────────────

  /// 添加消除分数（含连击加成）
  void addMatchScore(int baseScore, int cascadeLevel) {
    final multiplier = 1 + (_combo * 0.5) + (cascadeLevel * 0.3);
    final earned = (baseScore * multiplier).round();
    _score += earned;
    _updateGoalsOnScore(earned);
  }

  /// 连击
  void incrementCombo() {
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
  }

  /// 重置连击
  void resetCombo() {
    _combo = 0;
  }

  /// 记录使用道具
  void recordMove() {
    _movesUsed++;
  }

  /// 记录特殊元素触发
  void recordSpecial() {
    _specialsTriggered++;
    _score += 200;
  }

  /// 关卡结束奖励（剩余步数 → 分数）
  void applyEndBonus() {
    if (config.maxMoves > 0 && movesLeft > 0) {
      _score += movesLeft * 100;
    }
  }

  // ─── 目标追踪 ─────────────────────────────────────────────

  /// 记录消除了某种颜色
  void recordColorMatch(dynamic color, int count) {
    for (final goal in config.goals) {
      if (goal.type == GoalType.collectColor && goal.targetColor == color) {
        goal.currentCount += count;
      }
    }
  }

  /// 记录消除了冰块
  void recordIceCleared(int count) {
    for (final goal in config.goals) {
      if (goal.type == GoalType.clearIce) {
        goal.currentCount += count;
      }
    }
  }

  /// 记录消除了石块
  void recordRockCleared(int count) {
    for (final goal in config.goals) {
      if (goal.type == GoalType.clearRock) {
        goal.currentCount += count;
      }
    }
  }

  void _updateGoalsOnScore(int earned) {
    for (final goal in config.goals) {
      if (goal.type == GoalType.scoreTarget) {
        goal.currentCount = _score;
      }
    }
  }

  /// 所有目标是否完成
  bool get allGoalsComplete => config.goals.every((g) => g.isComplete);

  /// 当前星级（1-3）
  int get stars {
    if (_score >= config.starThreshold3) return 3;
    if (_score >= config.starThreshold2) return 2;
    return 1;
  }

  /// 是否超出步数限制
  bool get outOfMoves => config.maxMoves > 0 && _movesUsed >= config.maxMoves;

  // ─── 调试 ─────────────────────────────────────────────────

  @override
  String toString() =>
      'Score:$_score | Combo:$_combo | Moves:$_movesUsed/${config.maxMoves}';
}
