/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'dart:async';

import 'package:solidart_lint/src/assists/wrap_with_show.dart';
import 'package:solidart_lint/src/assists/wrap_with_signal_builder.dart';
import 'package:solidart_lint/src/assists/wrap_with_provider_scope.dart';

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

final plugin = _SolidartPlugin();

class _SolidartPlugin extends Plugin {
  @override
  String get name => 'solidart_lint';

  @override
  FutureOr<void> register(PluginRegistry registry) {
    registry.registerAssist(WrapWithProviderScope.new);
    registry.registerAssist(WrapWithSignalBuilder.new);
    registry.registerAssist(WrapWithShow.new);
  }
}
