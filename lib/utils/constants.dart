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

  // 水果背景色（柔和渐变底色）
  static const Map<int, Color> tileColors = {
    0: Color(0xFFFF6B6B), // 草莓红
    1: Color(0xFFFF9F43), // 橙子橙
    2: Color(0xFF54A0FF), // 蓝莓蓝
    3: Color(0xFF5F27CD), // 葡萄紫
    4: Color(0xFF1DD1A1), // 猕猴桃绿
    5: Color(0xFFFECA57), // 柠檬黄
  };

  // 水果 emoji
  static const Map<int, String> tileEmojis = {
    0: '🍓', // 草莓
    1: '🍊', // 橙子
    2: '🫐', // 蓝莓
    3: '🍇', // 葡萄
    4: '🥝', // 猕猴桃
    5: '🍋', // 柠檬
  };

  // 特殊元素颜色
  static const Color lineBreakerColor = Color(0xFFFFD700);
  static const Color bombColor = Color(0xFFFF4757);
  static const Color colorBombColor = Color(0xFFA29BFE);

  // 障碍物颜色
  static const Color iceColor = Color(0xFFB2EBF2);
  static const Color rockColor = Color(0xFF78909C);
  static const Color chainColor = Color(0xFF795548);
  static const Color slimeColor = Color(0xFF69F0AE);

  // UI 颜色（清新渐变风）
  static const Color backgroundColor = Color(0xFF0F0C29);
  static const Color boardBackgroundColor = Color(0xFF1A1040);
  static const Color hudColor = Color(0xFF24243E);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color accentColor2 = Color(0xFFFFBE76);
}
