import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class WrapWithSignalBuilder extends DartAssist {
  WrapWithSignalBuilder();

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
        message: 'Wrap with SignalBuilder',
        priority: 3,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
            node.offset,
            'SignalBuilder(\n'
            'signal: null,\n'
            'builder: (context, value, child) {\n'
            'return ');
        builder.addSimpleInsertion(node.end, '; },)');
      });
    });
  }
}
