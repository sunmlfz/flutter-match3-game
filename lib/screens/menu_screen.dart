import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'level_select_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              _buildLogo(),
              const SizedBox(height: 56),
              _buildButton(context,
                  label: '🎮  开始游戏',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  ),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LevelSelectScreen()))),
              const SizedBox(height: 14),
              _buildButton(context,
                  label: '📖  游戏说明',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                  onTap: () => _showHowToPlay(context)),
              const Spacer(),
              Text('消消乐 v1.0 · Flutter + Flame',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    const fruits = ['🍓', '🍊', '🫐', '🍇', '🥝', '🍋', '🍊', '🍓', '🫐'];
    return Column(
      children: [
        // 3×3 水果格子
        SizedBox(
          width: 130,
          height: 130,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: 9,
            itemBuilder: (_, i) {
              final colors = [
                const Color(0xFFFF6B6B),
                const Color(0xFFFF9F43),
                const Color(0xFF54A0FF),
                const Color(0xFF5F27CD),
                const Color(0xFF1DD1A1),
                const Color(0xFFFECA57),
                const Color(0xFFFF9F43),
                const Color(0xFFFF6B6B),
                const Color(0xFF54A0FF),
              ];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_lighten(colors[i], 0.15), colors[i]],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: colors[i].withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Center(
                    child: Text(fruits[i],
                        style: const TextStyle(fontSize: 26))),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFFBE76)],
          ).createShader(bounds),
          child: const Text('消消乐',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6)),
        ),
        const SizedBox(height: 6),
        Text('Match-3 Fruit Puzzle',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 14)),
      ],
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildButton(BuildContext context,
      {required String label,
      required LinearGradient gradient,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF24243E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('📖 游戏说明',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            '🎯 基本规则\n'
            '• 点击选中水果，再点击相邻水果交换\n'
            '• 3个以上相同水果连线即可消除\n'
            '• 消除后自动下落，连锁更高分！\n\n'
            '✨ 特殊元素\n'
            '• ⚡↔ 4连横 → 横向全行消除\n'
            '• ⚡↕ 4连纵 → 纵向全列消除\n'
            '• 💥 T/L形 → 3×3范围爆炸\n'
            '• 🌈 5连 → 全屏同色消除\n\n'
            '🧱 障碍物\n'
            '• ❄️ 冰块：相邻消除可破坏\n'
            '• 🪨 石块：特殊元素才能破坏\n'
            '• ⛓️ 锁链：解锁后才能移动\n\n'
            '🔨 道具\n'
            '• 锤子：直接消除单个\n'
            '• 炸弹：3×3范围消除\n'
            '• 重排：打乱重来',
            style: TextStyle(color: Colors.white70, height: 1.7, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('明白了！',
                style: TextStyle(
                    color: Color(0xFFFFBE76), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
