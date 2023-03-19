import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class WrapWithSolid extends DartAssist {
  WrapWithSolid();

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!target.intersects(node.constructorName.sourceRange)) {
        return;
      }

      final createdType = node.constructorName.type.type;
      if (createdType == null) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap with Solid',
        priority: 4,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
            node.offset,
            'Solid(\n'
            'child: ');
        builder.addSimpleInsertion(node.end, ',)');
      });
    });
  }
}
