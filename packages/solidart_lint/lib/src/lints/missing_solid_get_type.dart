import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';
import 'package:custom_lint_core/custom_lint_core.dart' as lint_codes;

class MissingSolidGetType extends DartLintRule {
  const MissingSolidGetType() : super(code: _code);

  static const _code = lint_codes.LintCode(
    name: 'missing_solid_get_type',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'Specify the provider or signal type you want to get',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation(
      (node) async {
        if (node.methodName.name == 'get') {
          if (node.target?.staticType == null) return;
          if (node.argumentList.arguments.isNotEmpty) return;
          final isContext =
              buildContextType.isExactlyType(node.target!.staticType!);
          if (!isContext) return;
          if (node.staticType is DynamicType) {
            reporter.reportErrorForNode(_code, node);
          }
        }
      },
    );
  }
}
