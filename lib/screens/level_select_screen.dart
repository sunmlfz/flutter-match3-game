import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/level_config.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

/// 关卡选择页面
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Map<int, int> _levelStars = {};
  Map<int, int> _levelHighScores = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final stars = <int, int>{};
    final scores = <int, int>{};
    for (int i = 1; i <= GameConstants.totalLevels; i++) {
      stars[i] = prefs.getInt('level_${i}_stars') ?? 0;
      scores[i] = prefs.getInt('level_${i}_score') ?? 0;
    }
    setState(() {
      _levelStars = stars;
      _levelHighScores = scores;
    });
  }

  bool _isUnlocked(int level) {
    if (level == 1) return true;
    return (_levelStars[level - 1] ?? 0) > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: GameConstants.hudColor,
        title: const Text('选择关卡', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: GameConstants.totalLevels,
          itemBuilder: (_, index) {
            final level = index + 1;
            final config = Levels.get(level);
            final stars = _levelStars[level] ?? 0;
            final score = _levelHighScores[level] ?? 0;
            final unlocked = _isUnlocked(level);

            return _LevelCard(
              config: config,
              stars: stars,
              highScore: score,
              unlocked: unlocked,
              onTap: unlocked
                  ? () => _startLevel(context, level)
                  : null,
            );
          },
        ),
      ),
    );
  }

  void _startLevel(BuildContext context, int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: level,
          onLevelComplete: (score, stars) async {
            final prefs = await SharedPreferences.getInstance();
            final prevStars = prefs.getInt('level_${level}_stars') ?? 0;
            final prevScore = prefs.getInt('level_${level}_score') ?? 0;
            if (stars > prevStars) prefs.setInt('level_${level}_stars', stars);
            if (score > prevScore) prefs.setInt('level_${level}_score', score);
            if (!context.mounted) return;
            Navigator.pop(context);
            _loadProgress();
          },
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LevelConfig config;
  final int stars;
  final int highScore;
  final bool unlocked;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.config,
    required this.stars,
    required this.highScore,
    required this.unlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: unlocked ? GameConstants.hudColor : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stars > 0
                ? Colors.amber.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 关卡号
            Text(
              '${config.level}',
              style: TextStyle(
                color: unlocked ? Colors.white : Colors.grey,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            // 关卡名
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                config.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: unlocked ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 6),

            // 星级
            Text(
              unlocked
                  ? ('⭐' * stars + '☆' * (3 - stars))
                  : '🔒',
              style: const TextStyle(fontSize: 14),
            ),

            // 最高分
            if (highScore > 0)
              Text(
                '$highScore',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
