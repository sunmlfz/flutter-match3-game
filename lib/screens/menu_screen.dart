import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'level_select_screen.dart';

/// 主菜单页面
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // 游戏 Logo
            _buildLogo(),

            const SizedBox(height: 80),

            // 开始游戏按钮
            _buildMenuButton(
              context,
              label: '🎮 开始游戏',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // 关于按钮
            _buildMenuButton(
              context,
              label: '📖 游戏说明',
              onTap: () => _showHowToPlay(context),
              secondary: true,
            ),

            const Spacer(),

            // 底部版权
            Text(
              '消消乐 v1.0 | Flutter + Flame',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // 彩色格子 Logo
        SizedBox(
          width: 120,
          height: 120,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 9,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: GameConstants.tileColors[i % 6],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '消消乐',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Match-3 Puzzle',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    bool secondary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: secondary
                ? GameConstants.hudColor
                : GameConstants.accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 4,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GameConstants.boardBackgroundColor,
        title: const Text('📖 游戏说明', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            '🎯 基本规则\n'
            '• 点击选中元素，再点击相邻元素交换\n'
            '• 形成3个以上相同颜色连线即可消除\n'
            '• 消除后元素自动下落，产生连锁更高分\n\n'
            '✨ 特殊元素\n'
            '• 4连 → 直线消除（横或纵）\n'
            '• T/L形 → 3×3范围爆炸\n'
            '• 5连 → 全屏同色消除\n\n'
            '🧱 障碍物\n'
            '• 冰块：相邻消除可破坏\n'
            '• 石块：需特殊元素破坏\n'
            '• 锁链：解锁后才能移动\n\n'
            '⭐ 评分\n'
            '• 消除越多、连击越多，分越高\n'
            '• 剩余步数也会转化为分数',
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('明白了', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
