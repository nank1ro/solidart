import 'package:flutter/material.dart';
import 'package:solidart/solidart.dart';

/// Shows the usage of the [Show] widget
class ShowPage extends StatefulWidget {
  const ShowPage({super.key});

  @override
  State<ShowPage> createState() => _ShowPageState();
}

class _ShowPageState extends State<ShowPage> {
  late final Signal<bool> loggedIn;

  @override
  void initState() {
    super.initState();

    loggedIn = createSignal(false);
  }

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
              onPressed: () {
                loggedIn.value = !loggedIn.value;
              },
              child: Show(
                when: loggedIn,
                builder: (_) => const Text('LOGIN'),
                fallback: (_) => const Text('LOGOUT'),
              ))
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
