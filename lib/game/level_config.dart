import 'tile.dart';

/// 关卡目标类型
enum GoalType {
  collectColor,   // 消除指定颜色 N 个
  clearIce,       // 清除所有冰块
  clearRock,      // 清除所有石块
  scoreTarget,    // 达到目标分数
  collectItem,    // 收集掉落物品
}

/// 单个关卡目标
class LevelGoal {
  final GoalType type;
  final TileColor? targetColor;
  final int targetCount;
  int currentCount;

  LevelGoal({
    required this.type,
    this.targetColor,
    required this.targetCount,
    this.currentCount = 0,
  });

  bool get isComplete => currentCount >= targetCount;

  double get progress =>
      (currentCount / targetCount).clamp(0.0, 1.0);

  String get description {
    switch (type) {
      case GoalType.collectColor:
        return '消除 ${targetColor?.name ?? ''} ${targetCount} 个';
      case GoalType.clearIce:
        return '清除 $targetCount 个冰块';
      case GoalType.clearRock:
        return '消除 $targetCount 个石块';
      case GoalType.scoreTarget:
        return '达到 $targetCount 分';
      case GoalType.collectItem:
        return '收集 $targetCount 个物品';
    }
  }
}

/// 关卡配置
class LevelConfig {
  final int level;
  final String name;
  final String description;
  final int maxMoves;       // 最大步数（0=限时）
  final int timeLimitSec;   // 时间限制秒（0=限步数）
  final List<LevelGoal> goals;
  final List<List<int>> icePositions;   // [row, col, layers]
  final List<List<int>> rockPositions;  // [row, col]
  final List<List<int>> chainPositions; // [row, col]
  final int starThreshold2; // 2星分数线
  final int starThreshold3; // 3星分数线

  const LevelConfig({
    required this.level,
    required this.name,
    required this.description,
    required this.maxMoves,
    required this.timeLimitSec,
    required this.goals,
    this.icePositions = const [],
    this.rockPositions = const [],
    this.chainPositions = const [],
    required this.starThreshold2,
    required this.starThreshold3,
  });

  bool get isTimedMode => timeLimitSec > 0;
}

/// 所有关卡定义
class Levels {
  static final List<LevelConfig> all = [
    // ─── 关卡 1：新手教程 ────────────────────────────────────
    LevelConfig(
      level: 1,
      name: '初识消消乐',
      description: '消除红色元素，熟悉基本操作',
      maxMoves: 20,
      timeLimitSec: 0,
      goals: [
        LevelGoal(type: GoalType.collectColor, targetColor: TileColor.red, targetCount: 30),
      ],
      starThreshold2: 1500,
      starThreshold3: 3000,
    ),

    // ─── 关卡 2：冰块挑战 ────────────────────────────────────
    LevelConfig(
      level: 2,
      name: '寒冰之地',
      description: '清除所有冰块，小心别浪费步数',
      maxMoves: 25,
      timeLimitSec: 0,
      goals: [
        LevelGoal(type: GoalType.clearIce, targetCount: 10),
        LevelGoal(type: GoalType.collectColor, targetColor: TileColor.blue, targetCount: 20),
      ],
      icePositions: [
        [3, 1], [3, 2], [3, 3],
        [4, 4], [4, 5], [4, 6],
        [5, 2], [5, 3], [5, 4], [5, 5],
      ],
      starThreshold2: 2000,
      starThreshold3: 4000,
    ),

    // ─── 关卡 3：石块迷宫 ────────────────────────────────────
    LevelConfig(
      level: 3,
      name: '石之迷宫',
      description: '绕过石块，完成消除目标',
      maxMoves: 30,
      timeLimitSec: 0,
      goals: [
        LevelGoal(type: GoalType.scoreTarget, targetCount: 5000),
        LevelGoal(type: GoalType.clearRock, targetCount: 6),
      ],
      rockPositions: [
        [2, 2], [2, 5],
        [4, 0], [4, 7],
        [6, 3], [6, 4],
      ],
      starThreshold2: 5000,
      starThreshold3: 8000,
    ),

    // ─── 关卡 4：限时冲分 ────────────────────────────────────
    LevelConfig(
      level: 4,
      name: '极速消除',
      description: '60秒内冲高分！连击是关键',
      maxMoves: 0,
      timeLimitSec: 60,
      goals: [
        LevelGoal(type: GoalType.scoreTarget, targetCount: 8000),
      ],
      starThreshold2: 8000,
      starThreshold3: 15000,
    ),

    // ─── 关卡 5：终极挑战 ────────────────────────────────────
    LevelConfig(
      level: 5,
      name: '终极消消乐',
      description: '冰块 + 石块 + 锁链，全部克服！',
      maxMoves: 40,
      timeLimitSec: 0,
      goals: [
        LevelGoal(type: GoalType.clearIce, targetCount: 8),
        LevelGoal(type: GoalType.clearRock, targetCount: 4),
        LevelGoal(type: GoalType.scoreTarget, targetCount: 10000),
      ],
      icePositions: [
        [1, 1], [1, 6],
        [2, 2], [2, 5],
        [3, 3], [3, 4],
        [5, 2], [5, 5],
      ],
      rockPositions: [
        [4, 1], [4, 6],
        [6, 3], [6, 4],
      ],
      chainPositions: [
        [3, 0], [3, 7],
      ],
      starThreshold2: 10000,
      starThreshold3: 18000,
    ),
  ];

  static LevelConfig get(int level) => all[level - 1];
}
