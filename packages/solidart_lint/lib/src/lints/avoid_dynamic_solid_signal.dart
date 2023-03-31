import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidDynamicSolidSignal extends DartLintRule {
  const AvoidDynamicSolidSignal() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_dynamic_solid_signal',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'The solid signal cannot be dynamic',
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

          Expression? expression;
          if (fnExp.body is BlockFunctionBody) {
            final fnBody = fnExp.body as BlockFunctionBody;
            final returnStatement = fnBody.block.childEntities
                .whereType<ReturnStatement>()
                .firstOrNull;
            expression = returnStatement?.expression;
          } else if (fnExp.body is ExpressionFunctionBody) {
            final fnBody = fnExp.body as ExpressionFunctionBody;
            expression = fnBody.expression;
          }

          if (expression == null) return;

          final type = expression.staticType;
          if (type == null) return;
          final name = type.getDisplayString(withNullability: false);
          if (name == "Signal<dynamic>") {
            reporter.reportErrorForToken(_code, expression.beginToken);
          }

          if (name == "ReadSignal<dynamic>") {
            final childEntities =
                expression.childEntities.whereType<SimpleIdentifier>();
            for (final entity in childEntities) {
              if (entity.name == 'select') {
                reporter.reportErrorForNode(_code, entity);
              }
            }
          }
        }
      },
    );
  }

  @override
  List<Fix> getFixes() => [_SolidSignalTypeFix()];
}

class _SolidSignalTypeFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addMapLiteralEntry(
      (node) {
        if (node.value is FunctionExpression) {
          final fnExp = node.value as FunctionExpression;

          Expression? expression;
          if (fnExp.body is BlockFunctionBody) {
            final fnBody = fnExp.body as BlockFunctionBody;
            final returnStatement = fnBody.block.childEntities
                .whereType<ReturnStatement>()
                .firstOrNull;
            expression = returnStatement?.expression;
          } else if (fnExp.body is ExpressionFunctionBody) {
            final fnBody = fnExp.body as ExpressionFunctionBody;
            expression = fnBody.expression;
          }

          if (expression == null) return;
          if (expression is MethodInvocation) {
            final argList =
                expression.childEntities.whereType<ArgumentList>().firstOrNull;
            final fnExp2 =
                argList?.arguments.whereType<FunctionExpression>().firstOrNull;
            final innerExp =
                argList?.arguments.whereType<Expression>().firstOrNull;
            final returnType =
                fnExp2?.declaredElement?.returnType ?? innerExp?.staticType;

            if (returnType == null || returnType.isDartCoreNull) return;

            final changeBuilder = reporter.createChangeBuilder(
              message: "Specify the '$returnType' type",
              priority: 1,
            );

            changeBuilder.addDartFileEdit(
              (builder) {
                builder.addSimpleInsertion(
                  analysisError.offset + analysisError.length,
                  '<$returnType>',
                );
              },
            );
          }
        }
      },
    );
  }
}
