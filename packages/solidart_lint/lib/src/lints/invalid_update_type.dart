import 'package:analyzer/error/error.dart' as analyzer_error;
import 'package:collection/collection.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';

class InvalidUpdateType extends DartLintRule {
  const InvalidUpdateType() : super(code: _code);

  static const _code = LintCode(
    name: 'invalid_update_type',
    errorSeverity: analyzer_error.DiagnosticSeverity.ERROR,
    problemMessage: 'The update type is invalid, must not implement SignalBase',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
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
          final typeArgument = node.typeArguments?.arguments.firstOrNull?.type;
          if (typeArgument == null) {
            reporter.atNode(node, _code);
            return;
          }
          final isSignalBase =
              signalBaseType.isAssignableFromType(typeArgument);
          if (isSignalBase) {
            reporter.atNode(node, _code);
            return;
          }
        }
      },
    );
  }
}
