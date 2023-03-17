import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidDynamicSolidSignal extends DartLintRule {
  const AvoidDynamicSolidSignal() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_dynamic_solid_signal',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'Solid signals cannot be dynamic',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMapLiteralEntry(
      (node) {
        if (node.value is FunctionExpression) {
          final fnExp = node.value as FunctionExpression;

          if (fnExp.body is ExpressionFunctionBody) {
            final fnBody = fnExp.body as ExpressionFunctionBody;
            final exp = fnBody.expression;
            final type = exp.staticType;
            if (type == null) return;
            final name = type.getDisplayString(withNullability: false);
            if (name == "Signal<dynamic>") {
              reporter.reportErrorForToken(_code, exp.beginToken);
            }

            if (name == "ReadableSignal<dynamic>") {
              final childEntities =
                  exp.childEntities.whereType<SimpleIdentifier>();
              for (final entity in childEntities) {
                if (entity.name == 'select') {
                  reporter.reportErrorForNode(_code, entity);
                }
              }
            }
          }
        }
      },
    );
  }
}
