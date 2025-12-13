import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'] as String, name: json['name'] as String, email: json['email'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
