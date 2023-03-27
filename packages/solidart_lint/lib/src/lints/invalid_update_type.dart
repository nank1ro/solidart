import 'package:analyzer/error/error.dart';
import 'package:collection/collection.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';

class InvalidUpdateType extends DartLintRule {
  const InvalidUpdateType() : super(code: _code);

  static const _code = LintCode(
    name: 'invalid_update_type',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'The update type is invalid, must not implement SignalBase',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation(
      (node) async {
        if (node.methodName.name == 'update') {
          if (node.target?.staticType == null) return;
          if (node.argumentList.arguments.isEmpty) return;
          final isContext =
              buildContextType.isExactlyType(node.target!.staticType!);
          if (!isContext) return;
          final typeArgument = node.typeArgumentTypes?.firstOrNull;
          if (typeArgument == null) return;
          final isSignalBase =
              signalBaseType.isAssignableFromType(typeArgument);
          if (isSignalBase) {
            reporter.reportErrorForNode(_code, node);
          }
        }
      },
    );
  }
}
