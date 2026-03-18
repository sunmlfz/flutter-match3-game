import 'dart:math';
import 'tile.dart';
import '../utils/constants.dart';

/// 内部辅助：一段连续匹配的描述
/// [rc] = 行（横段）或列（纵段），[a,b) = 范围（另一轴），[isH] = 是否横向
class _MatchSeg {
  final int rc;
  final int a;
  final int b;
  final bool isH;
  _MatchSeg(this.rc, this.a, this.b, this.isH);
}

/// 消除结果
class MatchResult {
  final List<List<bool>> matched;  // 哪些位置被消除
  final List<SpecialType> newSpecials;  // 新生成的特殊元素
  final List<List<int>> specialPositions;  // 特殊元素位置
  final int score;
  final int cascadeLevel;

  MatchResult({
    required this.matched,
    required this.newSpecials,
    required this.specialPositions,
    required this.score,
    required this.cascadeLevel,
  });

  bool get hasMatch => matched.any((row) => row.any((v) => v));
}

/// 棋盘核心逻辑（纯 Dart，无 Flame 依赖）
class Board {
  final int rows;
  final int cols;
  final Random _random = Random();

  late List<List<Tile?>> grid;

  Board({required this.rows, required this.cols}) {
    _initBoard();
  }

  // ─── 初始化 ───────────────────────────────────────────────

  void _initBoard() {
    grid = List.generate(rows, (_) => List.generate(cols, (_) => null));
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        grid[r][c] = _generateTile(r, c);
      }
    }
    // 确保初始棋盘无匹配
    while (_hasInitialMatch()) {
      _reshuffleWithoutMatch();
    }
  }

  Tile _generateTile(int row, int col) {
    // 避免初始就产生匹配
    final forbidden = <TileColor>{};
    if (col >= 2 &&
        grid[row][col - 1] != null &&
        grid[row][col - 2] != null &&
        grid[row][col - 1]!.color == grid[row][col - 2]!.color) {
      forbidden.add(grid[row][col - 1]!.color);
    }
    if (row >= 2 &&
        grid[row - 1][col] != null &&
        grid[row - 2][col] != null &&
        grid[row - 1][col]!.color == grid[row - 2][col]!.color) {
      forbidden.add(grid[row - 1][col]!.color);
    }

    final available = TileColor.values.where((c) => !forbidden.contains(c)).toList();
    final color = available.isEmpty
        ? TileColor.values[_random.nextInt(TileColor.values.length)]
        : available[_random.nextInt(available.length)];

    return Tile(color: color);
  }

  bool _hasInitialMatch() {
    return findMatches().hasMatch;
  }

  void _reshuffleWithoutMatch() {
    final colors = TileColor.values.toList()..shuffle(_random);
    int colorIdx = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] != null && grid[r][c]!.special == SpecialType.none) {
          grid[r][c] = Tile(color: colors[colorIdx % colors.length]);
          colorIdx++;
        }
      }
    }
  }

  // ─── 交换 ─────────────────────────────────────────────────

  /// 检查两个位置是否相邻
  bool areAdjacent(int r1, int c1, int r2, int c2) {
    return (r1 == r2 && (c1 - c2).abs() == 1) ||
        (c1 == c2 && (r1 - r2).abs() == 1);
  }

  /// 交换两个位置的元素
  void swap(int r1, int c1, int r2, int c2) {
    final temp = grid[r1][c1];
    grid[r1][c1] = grid[r2][c2];
    grid[r2][c2] = temp;
  }

  /// 检查交换是否产生匹配（含特殊元素组合）
  bool isValidSwap(int r1, int c1, int r2, int c2) {
    if (!areAdjacent(r1, c1, r2, c2)) return false;
    // 特殊元素互换总是有效
    if ((grid[r1][c1]?.isSpecial ?? false) || (grid[r2][c2]?.isSpecial ?? false)) {
      return true;
    }
    swap(r1, c1, r2, c2);
    final hasMatch = findMatches().hasMatch;
    swap(r1, c1, r2, c2); // 撤销
    return hasMatch;
  }

  // ─── 匹配检测 ─────────────────────────────────────────────

  /// 查找所有匹配（≥3连），并检测 T/L/十字形生成炸弹
  MatchResult findMatches({int cascadeLevel = 0}) {
    final matched = List.generate(rows, (_) => List.filled(cols, false));
    final newSpecials = <SpecialType>[];
    final specialPositions = <List<int>>[];
    int totalScore = 0;

    // 记录每个位置所在横向/纵向匹配段的长度（0=无匹配）
    final hLen = List.generate(rows, (_) => List.filled(cols, 0));
    final vLen = List.generate(rows, (_) => List.filled(cols, 0));

    // ── 第一遍：收集横向匹配 ────────────────────────────────
    // 存储每段：{row, colStart, colEnd, len}
    final hSegments = <_MatchSeg>[];
    for (int r = 0; r < rows; r++) {
      int start = 0;
      while (start < cols) {
        final tile = grid[r][start];
        if (tile == null || tile.isSpecial) { start++; continue; }
        int end = start + 1;
        while (end < cols &&
            grid[r][end] != null &&
            !grid[r][end]!.isSpecial &&
            grid[r][end]!.color == tile.color) {
          end++;
        }
        final len = end - start;
        if (len >= 3) {
          hSegments.add(_MatchSeg(r, start, end, true));
          for (int c = start; c < end; c++) {
            matched[r][c] = true;
            hLen[r][c] = len;
          }
          totalScore += _calcScore(len, cascadeLevel);
        }
        start = end;
      }
    }

    // ── 第二遍：收集纵向匹配 ────────────────────────────────
    final vSegments = <_MatchSeg>[];
    for (int c = 0; c < cols; c++) {
      int start = 0;
      while (start < rows) {
        final tile = grid[start][c];
        if (tile == null || tile.isSpecial) { start++; continue; }
        int end = start + 1;
        while (end < rows &&
            grid[end][c] != null &&
            !grid[end][c]!.isSpecial &&
            grid[end][c]!.color == tile.color) {
          end++;
        }
        final len = end - start;
        if (len >= 3) {
          vSegments.add(_MatchSeg(start, c, end, false));
          for (int r = start; r < end; r++) {
            matched[r][c] = true;
            vLen[r][c] = len;
          }
          totalScore += _calcScore(len, cascadeLevel);
        }
        start = end;
      }
    }

    // ── 第三遍：检测交叉点（T/L/十字）→ 生成炸弹 ────────────
    // 同一位置 hLen ≥ 3 AND vLen ≥ 3 → T/L/+ 形，在交叉点生成炸弹
    final crossPoints = <List<int>>{};
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (hLen[r][c] >= 3 && vLen[r][c] >= 3) {
          crossPoints.add([r, c]);
        }
      }
    }
    for (final pos in crossPoints) {
      newSpecials.add(SpecialType.bomb);
      specialPositions.add(pos);
    }

    // ── 非交叉段：检测 4连/5连 生成直线/彩虹 ────────────────
    // 对每个匹配段，若段中没有交叉点，才生成对应直线/彩虹特殊元素
    for (final seg in hSegments) {
      // 该段是否有交叉点
      bool hasCross = false;
      for (int c = seg.a; c < seg.b; c++) {
        if (vLen[seg.rc][c] >= 3) { hasCross = true; break; }
      }
      if (!hasCross) {
        _checkSpecialGeneration(
            matched, seg.rc, seg.a, seg.b, true, seg.b - seg.a,
            newSpecials, specialPositions);
      }
    }
    for (final seg in vSegments) {
      bool hasCross = false;
      for (int r = seg.a; r < seg.b; r++) {
        if (hLen[r][seg.rc] >= 3) { hasCross = true; break; }
      }
      if (!hasCross) {
        _checkSpecialGeneration(
            matched, seg.a, seg.rc, seg.b, false, seg.b - seg.a,
            newSpecials, specialPositions);
      }
    }

    return MatchResult(
      matched: matched,
      newSpecials: newSpecials,
      specialPositions: specialPositions,
      score: totalScore,
      cascadeLevel: cascadeLevel,
    );
  }

  /// 计算分数（连击加成）
  int _calcScore(int matchLen, int cascade) {
    int base = GameConstants.baseMatchScore * matchLen;
    return base * (1 + cascade);
  }

  /// 检测是否应生成特殊元素
  void _checkSpecialGeneration(
    List<List<bool>> matched,
    int startR,
    int startC,
    int end,
    bool isHorizontal,
    int len,
    List<SpecialType> newSpecials,
    List<List<int>> positions,
  ) {
    // 简单判断：优先生成最中间位置的特殊元素
    SpecialType special = SpecialType.none;
    if (len == 4) {
      special = isHorizontal ? SpecialType.lineH : SpecialType.lineV;
    } else if (len >= 5) {
      special = SpecialType.colorBomb;
    }

    if (special != SpecialType.none) {
      final mid = isHorizontal
          ? [startR, (startC + end) ~/ 2]
          : [(startR + end) ~/ 2, startC];
      newSpecials.add(special);
      positions.add(mid);
    }
  }

  // ─── 消除 & 下落 ──────────────────────────────────────────

  /// 触发特殊元素效果（返回额外消除位置）
  List<List<int>> triggerSpecial(int r, int c) {
    final tile = grid[r][c];
    if (tile == null || !tile.isSpecial) return [];

    final extra = <List<int>>[];

    switch (tile.special) {
      case SpecialType.lineH:
        for (int col = 0; col < cols; col++) {
          extra.add([r, col]);
        }
        break;
      case SpecialType.lineV:
        for (int row = 0; row < rows; row++) {
          extra.add([row, c]);
        }
        break;
      case SpecialType.bomb:
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = r + dr;
            final nc = c + dc;
            if (_inBounds(nr, nc)) extra.add([nr, nc]);
          }
        }
        break;
      case SpecialType.colorBomb:
        final targetColor = _getAdjacentColor(r, c);
        if (targetColor != null) {
          for (int row = 0; row < rows; row++) {
            for (int col = 0; col < cols; col++) {
              if (grid[row][col]?.color == targetColor) {
                extra.add([row, col]);
              }
            }
          }
        }
        break;
      default:
        break;
    }

    return extra;
  }

  TileColor? _getAdjacentColor(int r, int c) {
    final dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (final d in dirs) {
      final nr = r + d[0];
      final nc = c + d[1];
      if (_inBounds(nr, nc) && grid[nr][nc] != null && !grid[nr][nc]!.isSpecial) {
        return grid[nr][nc]!.color;
      }
    }
    return null;
  }

  /// 移除已匹配的元素，处理障碍物
  void removeMatched(List<List<bool>> matched) {
    // 先处理特殊元素触发
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (matched[r][c] && grid[r][c] != null && grid[r][c]!.isSpecial) {
          final extra = triggerSpecial(r, c);
          for (final pos in extra) {
            matched[pos[0]][pos[1]] = true;
          }
        }
      }
    }

    // 处理冰块/障碍物
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (matched[r][c]) {
          final tile = grid[r][c];
          if (tile != null) {
            if (tile.obstacle == ObstacleType.ice && tile.iceLayer > 1) {
              tile.iceLayer--;
              matched[r][c] = false; // 未完全消除
            } else if (tile.obstacle == ObstacleType.rock) {
              matched[r][c] = false; // 石块不被直接消除
            } else {
              grid[r][c] = null;
            }
          }
        }
      }
    }

    // 消除相邻冰块
    _damageAdjacentIce(matched);
  }

  void _damageAdjacentIce(List<List<bool>> matched) {
    final dirs = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (matched[r][c]) {
          for (final d in dirs) {
            final nr = r + d[0];
            final nc = c + d[1];
            if (_inBounds(nr, nc)) {
              final neighbor = grid[nr][nc];
              if (neighbor != null && neighbor.obstacle == ObstacleType.ice) {
                if (neighbor.iceLayer <= 1) {
                  neighbor.obstacle = ObstacleType.none;
                  neighbor.iceLayer = 0;
                } else {
                  neighbor.iceLayer--;
                }
              }
            }
          }
        }
      }
    }
  }

  /// 元素下落填补空位
  List<List<int>> applyGravity() {
    final movedPositions = <List<int>>[];
    for (int c = 0; c < cols; c++) {
      int emptyRow = rows - 1;
      for (int r = rows - 1; r >= 0; r--) {
        if (grid[r][c] != null) {
          if (r != emptyRow) {
            grid[emptyRow][c] = grid[r][c];
            grid[r][c] = null;
            movedPositions.add([emptyRow, c]);
          }
          emptyRow--;
        }
      }
    }
    return movedPositions;
  }

  /// 用新元素补充空位（从顶部生成）
  List<List<int>> fillEmpty() {
    final newPositions = <List<int>>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == null) {
          final color = TileColor.values[_random.nextInt(TileColor.values.length)];
          grid[r][c] = Tile(color: color, isNew: true);
          newPositions.add([r, c]);
        }
      }
    }
    return newPositions;
  }

  /// 将新特殊元素放入棋盘
  void placeSpecials(MatchResult result) {
    for (int i = 0; i < result.newSpecials.length; i++) {
      final pos = result.specialPositions[i];
      final r = pos[0];
      final c = pos[1];
      if (_inBounds(r, c)) {
        final existing = grid[r][c];
        final color = existing?.color ??
            TileColor.values[_random.nextInt(TileColor.values.length)];
        grid[r][c] = Tile(color: color, special: result.newSpecials[i]);
      }
    }
  }

  // ─── 重排 ─────────────────────────────────────────────────

  /// 检查是否有可用移动
  bool hasPossibleMove() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (c + 1 < cols && isValidSwap(r, c, r, c + 1)) return true;
        if (r + 1 < rows && isValidSwap(r, c, r + 1, c)) return true;
      }
    }
    return false;
  }

  /// 重新打乱棋盘（保证有可用移动）
  void reshuffle() {
    final colors = <TileColor>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] != null && grid[r][c]!.special == SpecialType.none) {
          colors.add(grid[r][c]!.color);
        }
      }
    }
    colors.shuffle(_random);
    int idx = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] != null && grid[r][c]!.special == SpecialType.none) {
          grid[r][c] = Tile(color: colors[idx++]);
        }
      }
    }
    if (!hasPossibleMove()) reshuffle();
  }

  // ─── 障碍物设置 ───────────────────────────────────────────

  void setIce(int r, int c, {int layers = 1}) {
    grid[r][c]?.obstacle = ObstacleType.ice;
    grid[r][c]?.iceLayer = layers;
  }

  void setRock(int r, int c) {
    grid[r][c] = Tile(
      color: TileColor.values[_random.nextInt(TileColor.values.length)],
      obstacle: ObstacleType.rock,
    );
  }

  void setChain(int r, int c) {
    grid[r][c]?.obstacle = ObstacleType.chain;
    grid[r][c]?.isLocked = true;
  }

  // ─── 工具 ─────────────────────────────────────────────────

  bool _inBounds(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  Tile? get(int r, int c) => _inBounds(r, c) ? grid[r][c] : null;

  void set(int r, int c, Tile? tile) {
    if (_inBounds(r, c)) grid[r][c] = tile;
  }

  /// 统计指定颜色的剩余数量
  int countColor(TileColor color) {
    int count = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c]?.color == color) count++;
      }
    }
    return count;
  }

  /// 统计剩余障碍物数量
  int countObstacle(ObstacleType type) {
    int count = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c]?.obstacle == type) count++;
      }
    }
    return count;
  }
}
