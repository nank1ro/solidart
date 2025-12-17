import 'package:auth_flow/notifiers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Profile Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthNotifier.provider.of(context).logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SignalBuilder(
          builder: (_, _) {
            final user = AuthNotifier.provider.of(context).currentUser.value;

            if (user == null) {
              return const Center(child: Text('No user found'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ID: ${user.id}'),
                Text('User Name: ${user.name}'),
                Text('User Email: ${user.email}'),
              ],
            );
          },
        ),
      ),
    );
  }
}
