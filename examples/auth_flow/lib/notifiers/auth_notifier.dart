import 'package:disco/disco.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferenceProvider = Provider.withArgument((_, SharedPreferences prefs) => prefs);

class AuthNotifier {
  AuthNotifier(this.prefs) {
    final user = prefs.getString('user');
    if (user != null) {
      currentUser.value = (id: '1', name: 'John Doe', email: 'john.doe@example.com');
    }
  }

  final SharedPreferences prefs;

  // Provider
  static final provider = Provider((context) => AuthNotifier(sharedPreferenceProvider.of(context)));

  late final currentUser = Signal<User?>(null);
  late final isLoggedIn = Computed(() => currentUser.value != null);

  void login(User user) async {
    await prefs.setString('user', user.id);
    currentUser.value = user;
  }

  void logout() async {
    await prefs.remove('user');
    currentUser.value = null;
  }
}

typedef User = ({String id, String name, String email});

/// We can also use Resource, but required to trigger the refresh or manual update
/// late final user = Resource(_getUser)
/// user.state = ResourceReady(value)
