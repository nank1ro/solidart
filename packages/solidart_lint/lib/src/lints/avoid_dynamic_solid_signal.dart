import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';

class AvoidDynamicSolidSignal extends DartLintRule {
  const AvoidDynamicSolidSignal() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_dynamic_solid_signal',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'The SolidSignal cannot be dynamic',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.staticParameterElement != null) return;

      final type = node.staticType;
      if (type == null) return;
      final name = type.getDisplayString(withNullability: false);
      if (solidSignalType.isExactlyType(type) &&
          name == 'SolidSignal<dynamic>') {
        reporter.reportErrorForToken(_code, node.beginToken);
        return;
      }
    });
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
    context.registry.addInstanceCreationExpression(
      (node) {
        if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

        final argumentList =
            node.childEntities.whereType<ArgumentList>().firstOrNull;

        final namedExpression = argumentList?.childEntities
            .whereType<NamedExpression>()
            .firstOrNull;
        if (namedExpression == null) return;

        Expression? expression;

        for (final child in namedExpression.expression.childEntities) {
          if (child is ExpressionFunctionBody) {
            expression = child.expression;
            break;
          } else if (child is BlockFunctionBody) {
            final returnStatement = child.block.childEntities
                .whereType<ReturnStatement>()
                .firstOrNull;
            expression = returnStatement?.expression;
            break;
          }
        }

        final dartType = expression?.staticType;
        if (dartType == null) return;

        final changeBuilder = reporter.createChangeBuilder(
          message: 'Convert SolidSignal to SolidSignal<$dartType>',
          priority: 1,
        );
        final constructorName =
            node.childEntities.whereType<ConstructorName>().firstOrNull;
        final name = constructorName?.toString();
        if (name != 'SolidSignal') return;

        changeBuilder.addDartFileEdit(
          (builder) {
            builder.addSimpleInsertion(
              constructorName!.offset + constructorName.length,
              '<$dartType>',
            );
          },
        );
      },
    );
  }
}
