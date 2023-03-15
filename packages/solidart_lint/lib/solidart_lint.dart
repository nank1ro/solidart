/// Support for doing something awesome.
///
/// More dartdocs go here.
library solidart_lint;

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/assists/wrap_with_resource_builder.dart';
import 'package:solidart_lint/src/assists/wrap_with_show.dart';
import 'package:solidart_lint/src/assists/wrap_with_signal_builder.dart';
import 'package:solidart_lint/src/assists/wrap_with_solid.dart';
import 'package:solidart_lint/src/lints/avoid_dynamic_solid_providers.dart';
import 'package:solidart_lint/src/lints/specify_context_get_type.dart';

PluginBase createPlugin() => _SolidartPlugin();

class _SolidartPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidDynamicSolidProviders(),
        SpecifyContextGetType(),
      ];

  @override
  List<Assist> getAssists() => [
        WrapWithSolid(),
        WrapWithSignalBuilder(),
        WrapWithResourceBuilder(),
        WrapWithShow(),
      ];
}
