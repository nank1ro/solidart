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
            'builder: (context, resourceState) {\n'
            'return resourceState.on(\n'
            'ready: (value, isRefreshing) {\n'
            'return ');
        builder.addSimpleInsertion(
            node.end,
            ';},'
            'loading: () => const CircularProgressIndicator(),\n'
            "error: (error, stackTrace) => Text('\$error'),\n"
            ');},)');
      });
    });
  }
}
