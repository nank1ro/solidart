import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/app.dart';

void main() async {
  runApp(const ProviderScope(child: MyApp()));
}
