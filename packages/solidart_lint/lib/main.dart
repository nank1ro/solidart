/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'dart:async';
import 'dart:io';

import 'package:solidart_lint/src/assists/wrap_with_show.dart';
import 'package:solidart_lint/src/assists/wrap_with_signal_builder.dart';
import 'package:solidart_lint/src/assists/wrap_with_provider_scope.dart';
import 'package:solidart_lint/src/lints/avoid_dynamic_provider.dart';
import 'package:solidart_lint/src/lints/invalid_update_type.dart';
import 'package:solidart_lint/src/lints/missing_solid_get_type.dart';

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

void log(Object obj) {
  File('/Users/ale/github/solidart/log.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('$obj\n', mode: FileMode.append);
}

final plugin = _SolidartPlugin();

class _SolidartPlugin extends Plugin {
  @override
  String get name => 'solidart_lint';

  @override
  FutureOr<void> register(PluginRegistry registry) {
    // lints
    // registry.registerWarningRule(AvoidDynamicProvider.new);
    // registry.registerWarningRule(MissingSolidGetType.new);
    // registry.registerWarningRule(InvalidUpdateType.new);
    // assists
    registry.registerAssist(WrapWithProviderScope.new);
    // registry.registerAssist(WrapWithSignalBuilder.new);
    // registry.registerAssist(WrapWithShow.new);
  }
}
