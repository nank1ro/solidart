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
    : super(
        localStorage.getItem('user') != null
            ? User.fromJson(jsonDecode(localStorage.getItem('user')!))
            : null,
      );

  @override
  set value(User? newValue) {
    super.value = newValue;
    if (newValue == null) return localStorage.removeItem('user');
    localStorage.setItem('user', jsonEncode(newValue));
  }
}
