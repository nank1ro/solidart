import 'dart:convert';

import 'package:disco/disco.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferenceProvider = Provider.withArgument((_, SharedPreferences prefs) => prefs);

class AuthNotifier {
  AuthNotifier(this.prefs) {
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final data = jsonDecode(userJson) as Map<String, dynamic>;
      currentUser.value = (
        id: data['id'] as String,
        name: data['name'] as String,
        email: data['email'] as String,
      );
    }
  }

  final SharedPreferences prefs;

  // Provider
  static final provider = Provider((context) => AuthNotifier(sharedPreferenceProvider.of(context)));

  late final currentUser = Signal<User?>(null);
  late final isLoggedIn = Computed(() => currentUser.value != null);

  Future<void> login(User user) async {
    final userJson = jsonEncode({'id': user.id, 'name': user.name, 'email': user.email});
    await prefs.setString('user', userJson);
    currentUser.value = user;
  }

  Future<void> logout() async {
    await prefs.remove('user');
    currentUser.value = null;
  }
}

typedef User = ({String id, String name, String email});

/// We can also use Resource, but required to trigger the refresh or manual update
/// late final user = Resource(_getUser)
/// user.state = ResourceReady(value)
