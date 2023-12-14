import 'package:flutter/material.dart';
import 'package:pub/pages/search/page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF0175c2),
          secondary: const Color(0xFFe7f8ff),
          tertiary: const Color(0xFF0175c2),
          error: Colors.red,
          errorContainer: Colors.red.shade300,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFe0e0e0),
        ),
      ),
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const SearchPage(),
        '/login': (context) => const SearchPage(),
      },
    );
  }
}
