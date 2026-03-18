import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 强制竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const Match3App());
}

class Match3App extends StatelessWidget {
  const Match3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '消消乐',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94560),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}
