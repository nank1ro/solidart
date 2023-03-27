import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';

class InvalidObserveType extends DartLintRule {
  const InvalidObserveType() : super(code: _code);

  static const _code = LintCode(
    name: 'invalid_observe_type',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage:
        'The observe type you want to retrieve is invalid, must not implement SignalBase',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation(
      (node) async {
        if (node.methodName.name == 'observe') {
          if (node.target?.staticType == null) return;
          if (node.argumentList.arguments.isEmpty) return;
          final isContext =
              buildContextType.isExactlyType(node.target!.staticType!);
          if (!isContext) return;
          if (node.staticType == null) return;
          final isSignalBase =
              signalBaseType.isAssignableFromType(node.staticType!);
          if (isSignalBase) {
            reporter.reportErrorForNode(_code, node);
          }
        }
      },
    );
  }
}
