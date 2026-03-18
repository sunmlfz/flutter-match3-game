/// 元素类型枚举（6种基础颜色）
enum TileColor {
  red,
  blue,
  green,
  yellow,
  purple,
  cyan,
}

/// 特殊元素类型
enum SpecialType {
  none,
  lineH,      // 横向直线消除（4连生成）
  lineV,      // 纵向直线消除（4连生成）
  bomb,       // 3x3范围爆炸（T/L形生成）
  colorBomb,  // 全屏同色消除（5连生成）
}

/// 障碍物类型
enum ObstacleType {
  none,
  ice,    // 冰块：需要被相邻消除才能破坏
  rock,   // 石块：不可移动，附近消除可破坏
  chain,  // 锁链：锁定元素，需消除才能解锁
  slime,  // 粘液：每回合扩散
}

/// 游戏元素（Tile）数据模型
class Tile {
  TileColor color;
  SpecialType special;
  ObstacleType obstacle;
  int iceLayer;       // 冰块层数（1-2）
  bool isLocked;      // 是否被锁链锁定
  bool isMatched;     // 是否已被标记为消除
  bool isNew;         // 是否是新生成的
  bool isFalling;     // 是否正在下落

  Tile({
    required this.color,
    this.special = SpecialType.none,
    this.obstacle = ObstacleType.none,
    this.iceLayer = 0,
    this.isLocked = false,
    this.isMatched = false,
    this.isNew = false,
    this.isFalling = false,
  });

  /// 是否有障碍物
  bool get hasObstacle => obstacle != ObstacleType.none;

  /// 是否可以被交换
  bool get canSwap =>
      !isLocked &&
      obstacle == ObstacleType.none &&
      special != SpecialType.none ||
      (!isLocked && obstacle == ObstacleType.none);

  /// 是否为特殊元素
  bool get isSpecial => special != SpecialType.none;

  /// 克隆元素
  Tile clone() => Tile(
        color: color,
        special: special,
        obstacle: obstacle,
        iceLayer: iceLayer,
        isLocked: isLocked,
        isMatched: isMatched,
        isNew: isNew,
        isFalling: isFalling,
      );

  /// 转为字符串（调试用）
  @override
  String toString() =>
      'Tile(${color.name}, special:${special.name}, obs:${obstacle.name})';
}
