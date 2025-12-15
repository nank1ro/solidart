import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory User.fromMap(Map<String, dynamic> map) =>
      User(id: map['id'] as String, name: map['name'] as String, email: map['email'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'email': email};
}
