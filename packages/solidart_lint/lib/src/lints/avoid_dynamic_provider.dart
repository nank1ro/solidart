import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' as analyzer_error;
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';

class AvoidDynamicProvider extends DartLintRule {
  const AvoidDynamicProvider() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_dynamic_provider',
    errorSeverity: analyzer_error.DiagnosticSeverity.ERROR,
    problemMessage: 'The Provider cannot be dynamic',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (node.correspondingParameter != null) return;

      final type = node.staticType;
      if (type == null) return;
      final name = type.getDisplayString();
      if (providerType.isExactlyType(type) && name == 'Provider<dynamic>') {
        reporter.atToken(node.beginToken, _code);
        return;
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ProviderTypeFix()];
}

class _ProviderTypeFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
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
          message: 'Convert Provider to Provider<$dartType>',
          priority: 1,
        );
        final constructorName =
            node.childEntities.whereType<ConstructorName>().firstOrNull;
        final name = constructorName?.toString();
        if (name != 'Provider') return;

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
