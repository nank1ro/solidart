import 'dart:convert';

import 'package:auth_flow/domain/user.dart';
import 'package:disco/disco.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:localstorage/localstorage.dart';

class AuthNotifier {
  // Provider
  static final provider = Provider((context) => AuthNotifier());

  late final currentUser = UserSignal();
  late final isLoggedIn = Computed(() => currentUser.value != null);

  Future<void> login(User user) async {
    currentUser.value = user;
  }

  Future<void> logout() async {
    currentUser.value = null;
  }
}

class UserSignal extends Signal<User?> {
  UserSignal()
    : super(() {
        final userJsonString = localStorage.getItem('user');
        if (userJsonString == null) return null;
        try {
          final map = jsonDecode(userJsonString) as Map<String, dynamic>;
          return User.fromJson(map);
        } catch (_) {
          return null;
        }
      }());

  @override
  set value(User? newValue) {
    super.value = newValue;
    if (newValue == null) {
      localStorage.removeItem('user');
      return;
    }
    localStorage.setItem('user', jsonEncode(newValue));
  }
}
