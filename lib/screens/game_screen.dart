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
      body: Column(
        children: [
          // Flame 游戏区域
          Expanded(
            child: GameWidget(game: _game),
          ),

          // 底部道具栏
          _buildPowerBar(),
        ],
      ),
    );
  }

  Widget _buildPowerBar() {
    return Container(
      color: GameConstants.hudColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PowerButton(
            emoji: '🔨',
            label: '锤子',
            count: _hammerCount,
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
  final VoidCallback? onTap;

  const _PowerButton({
    required this.emoji,
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0 && onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: enabled
                ? GameConstants.accentColor.withOpacity(0.8)
                : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                '×$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
