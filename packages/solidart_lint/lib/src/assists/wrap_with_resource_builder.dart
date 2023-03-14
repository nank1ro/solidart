import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class WrapWithResourceBuilder extends DartAssist {
  WrapWithResourceBuilder();

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
        message: 'Wrap with ResourceBuilder',
        priority: 2,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
            node.offset,
            'ResourceBuilder(\n'
            'resource: null,\n'
            'builder: (context, resourceValue) {\n'
            'return ');
        builder.addSimpleInsertion(node.end, '; },)');
      });
    });
  }
}