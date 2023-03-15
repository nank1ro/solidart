import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class SpecifyContextGetType extends DartLintRule {
  const SpecifyContextGetType() : super(code: _code);

  static const _code = LintCode(
    name: 'specify_context_get_type',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'Specify the provider or signal type you want to get',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'get') {
        if (node.staticType?.isDynamic ?? false) {
          reporter.reportErrorForNode(_code, node);
        }
      }
    });
  }
}
