import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';

class InvalidSignalType extends DartLintRule {
  const InvalidSignalType() : super(code: _code);

  static const _code = LintCode(
    name: 'invalid_signal_type',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage:
        'The signal type you want to retrieve is invalid, must implement SignalBase',
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
          if (node.argumentList.arguments.isEmpty) return;
          final isContext =
              buildContextType.isExactlyType(node.target!.staticType!);
          if (!isContext) return;
          if (node.staticType == null) return;
          final isSignalBase =
              signalBaseType.isAssignableFromType(node.staticType!);
          if (!isSignalBase) {
            reporter.reportErrorForNode(_code, node);
          }
        }
      },
    );
  }
}
