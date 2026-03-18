import 'package:flutter/material.dart';

/// 游戏常量定义
class GameConstants {
  // 棋盘配置
  static const int boardRows = 8;
  static const int boardCols = 8;
  static const double tileSize = 64.0;
  static const double tilePadding = 2.0;
  static const double boardPadding = 16.0;

  // 动画时长
  static const Duration swapDuration = Duration(milliseconds: 250);
  static const Duration fallDuration = Duration(milliseconds: 300);
  static const Duration matchDuration = Duration(milliseconds: 200);
  static const Duration cascadeDelay = Duration(milliseconds: 100);

  // 评分配置
  static const int baseMatchScore = 50;
  static const int cascadeMultiplierIncrement = 1;
  static const int specialTileBonus = 200;
  static const int remainingMoveBonus = 100;

  // 关卡数量
  static const int totalLevels = 5;

  // 元素颜色
  static const Map<int, Color> tileColors = {
    0: Color(0xFFE74C3C), // 红
    1: Color(0xFF3498DB), // 蓝
    2: Color(0xFF2ECC71), // 绿
    3: Color(0xFFF39C12), // 黄
    4: Color(0xFF9B59B6), // 紫
    5: Color(0xFF1ABC9C), // 青
  };

  // 元素图标
  static const Map<int, String> tileEmojis = {
    0: '🔴',
    1: '🔵',
    2: '🟢',
    3: '🟡',
    4: '🟣',
    5: '🩵',
  };

  // 特殊元素颜色
  static const Color lineBreakerColor = Color(0xFFFFD700);
  static const Color bombColor = Color(0xFFFF6B35);
  static const Color colorBombColor = Color(0xFFFFFFFF);

  // 障碍物颜色
  static const Color iceColor = Color(0xFFADD8E6);
  static const Color rockColor = Color(0xFF808080);
  static const Color chainColor = Color(0xFF8B4513);
  static const Color slimeColor = Color(0xFF7CFC00);

  // UI 颜色
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color boardBackgroundColor = Color(0xFF16213E);
  static const Color hudColor = Color(0xFF0F3460);
  static const Color accentColor = Color(0xFFE94560);
}
