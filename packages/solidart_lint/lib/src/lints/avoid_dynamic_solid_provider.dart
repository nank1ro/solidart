import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';

class AvoidDynamicSolidProvider extends DartLintRule {
  const AvoidDynamicSolidProvider() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_dynamic_solid_provider',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'SolidProviders cannot be dynamic',
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
      if (solidProviderType.isExactlyType(type) &&
          name == 'SolidProvider<dynamic>') {
        reporter.reportErrorForToken(_code, node.beginToken);
        return;
      }
    });
  }

  @override
  List<Fix> getFixes() => [_SpecifySolidProviderType()];
}

class _SpecifySolidProviderType extends DartFix {
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

        final expressionFunctionBody = namedExpression?.expression.childEntities
            .whereType<ExpressionFunctionBody>()
            .firstOrNull;
        if (expressionFunctionBody == null) return;

        final dartType = expressionFunctionBody.expression.staticType;
        if (dartType == null) return;

        final changeBuilder = reporter.createChangeBuilder(
          message: 'Convert SolidProvider to SolidProvider<$dartType>',
          priority: 1,
        );

        changeBuilder.addDartFileEdit(
          (builder) {
            builder.addSimpleInsertion(
              node.offset + 'SolidProvider'.length,
              '<$dartType>',
            );
          },
        );
      },
    );
  }
}
