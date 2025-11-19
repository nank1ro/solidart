import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:solidart_lint/src/imports.dart';
import 'package:solidart_lint/src/types.dart';

class WrapWithShow extends ResolvedCorrectionProducer {
  WrapWithShow({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind =>
      const AssistKind('solidart.wrap_with_show', 27, 'Wrap with Show');

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! InstanceCreationExpression) return;
    final createdType = node.constructorName.type.type;
    if (createdType == null || !widgetType.isAssignableFromType(createdType)) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      final show = builder.importShow();
      builder.addSimpleInsertion(
        node.offset,
        '$show(\n'
        '  when: null,\n'
        '  fallback: null,\n'
        '  builder: (context) {\n'
        '    return ',
      );
      builder.addSimpleInsertion(node.end, ';\n  },\n)');
    });
  }
}
