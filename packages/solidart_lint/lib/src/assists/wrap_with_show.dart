import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class WrapWithShow extends DartAssist {
  WrapWithShow();

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      // Select from "new" to the opening bracket
      if (!target.intersects(node.constructorName.sourceRange)) {
        return;
      }

      final createdType = node.constructorName.type.type;
      if (createdType == null) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap with Show',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
            node.offset,
            'Show(\n'
            'when: null,\n'
            'fallback: null,\n'
            'builder: (context) {\n'
            'return ');
        builder.addSimpleInsertion(node.end, '; },)');
      });
    });
  }
}
