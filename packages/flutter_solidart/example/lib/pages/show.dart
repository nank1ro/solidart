import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// Shows the usage of the [Show] widget
class ShowPage extends StatefulWidget {
  const ShowPage({super.key});

  @override
  State<ShowPage> createState() => _ShowPageState();
}

class _ShowPageState extends State<ShowPage> {
  final loggedIn = Signal(false);

  @override
  void dispose() {
    loggedIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Show'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: loggedIn.toggle,
            child: Show(
              when: loggedIn,
              builder: (_) => const Text('LOGIN'),
              fallback: (_) => const Text('LOGOUT'),
            ),
          )
        ],
      ),
      body: Center(
        child: Show(
          when: loggedIn,
          builder: (_) => const Text('Logged In'),
          fallback: (_) => const Text('Logged out'),
        ),
      ),
    );
  }
}
