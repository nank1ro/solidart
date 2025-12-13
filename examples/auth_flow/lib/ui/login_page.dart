import 'package:auth_flow/domain/user.dart';
import 'package:auth_flow/notifiers/auth_notifier.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                final controller = AuthNotifier.provider.of(context);
                controller.login(User(id: '1', name: 'John Doe', email: 'john.doe@example.com'));
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
