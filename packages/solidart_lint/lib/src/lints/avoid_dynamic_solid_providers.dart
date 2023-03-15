import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidDynamicSolidProviders extends DartLintRule {
  const AvoidDynamicSolidProviders() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_dynamic_solid_providers',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'SolidProviders should have the type specified explicitly',
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
      final name = type?.getDisplayString(withNullability: false);
      if (name == 'SolidProvider<dynamic>') {
        reporter.reportErrorForNode(_code, node);
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
    context.registry.addInstanceCreationExpression((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final argumentList =
          node.childEntities.whereType<ArgumentList>().firstOrNull;

      final namedExpression =
          argumentList?.childEntities.whereType<NamedExpression>().firstOrNull;

      final expressionFunctionBody = namedExpression?.expression.childEntities
          .whereType<ExpressionFunctionBody>()
          .firstOrNull;
      if (expressionFunctionBody == null) return;

      final dartType = expressionFunctionBody.expression.staticType;
      if (dartType == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Assign $dartType type to SolidProvider',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
          node.offset + 'SolidProvider'.length,
          '<$dartType>',
        );
      });
    });
  }
}
