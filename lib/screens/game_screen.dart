import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/match3_game.dart';
import '../utils/constants.dart';

/// 游戏页面（包含 FlameGame + Flutter 道具栏）
class GameScreen extends StatefulWidget {
  final int level;
  final void Function(int score, int stars)? onLevelComplete;

  const GameScreen({
    super.key,
    required this.level,
    this.onLevelComplete,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Match3Game _game;
  int _hammerCount = 2;
  int _bombCount = 1;
  int _reshuffleCount = 1;

  @override
  void initState() {
    super.initState();
    _game = Match3Game(
      level: widget.level,
      onLevelComplete: (score, stars) {
        widget.onLevelComplete?.call(score, stars);
      },
      onGameOver: () {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              backgroundColor: GameConstants.boardBackgroundColor,
              title: const Text('😢 游戏结束', style: TextStyle(color: Colors.white)),
              content: const Text('步数用完了，重新挑战？',
                  style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('返回', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _game = Match3Game(
                        level: widget.level,
                        onLevelComplete: widget.onLevelComplete,
                        onGameOver: null,
                      );
                      _hammerCount = 2;
                      _bombCount = 1;
                      _reshuffleCount = 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: GameConstants.accentColor),
                  child: const Text('重试', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
          ),
        ),
        child: Column(
          children: [
            Expanded(child: GameWidget(game: _game)),
            _buildPowerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24243E), Color(0xFF302B63)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PowerButton(
            emoji: '🔨',
            label: '锤子',
            count: _hammerCount,
            gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
            onTap: _hammerCount > 0
                ? () {
                    setState(() => _hammerCount--);
                    _game.boardComponent.activatePower('hammer');
                  }
                : null,
          ),
          _PowerButton(
            emoji: '💣',
            label: '炸弹',
            count: _bombCount,
            gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)]),
            onTap: _bombCount > 0
                ? () {
                    setState(() => _bombCount--);
                    _game.boardComponent.activatePower('bomb');
                  }
                : null,
          ),
          _PowerButton(
            emoji: '🔄',
            label: '重排',
            count: _reshuffleCount,
            gradient: const LinearGradient(
                colors: [Color(0xFF00B894), Color(0xFF00CEC9)]),
            onTap: _reshuffleCount > 0
                ? () {
                    setState(() => _reshuffleCount--);
                    _game.boardComponent.activatePower('reshuffle');
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _PowerButton({
    required this.emoji,
    required this.label,
    required this.count,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0 && onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: enabled ? gradient : const LinearGradient(
                colors: [Color(0xFF555555), Color(0xFF444444)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
              Text('×$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
