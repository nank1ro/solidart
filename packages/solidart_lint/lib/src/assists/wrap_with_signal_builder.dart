import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:solidart_lint/src/imports.dart';
import 'package:solidart_lint/src/types.dart';

class WrapWithSignalBuilder extends ResolvedCorrectionProducer {
  WrapWithSignalBuilder({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => const AssistKind(
    'solidart.wrap_with_signal_builder',
    27,
    'Wrap with SignalBuilder',
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is! InstanceCreationExpression) return;
    final createdType = node.constructorName.type.type;
    if (createdType == null || !widgetType.isAssignableFromType(createdType)) {
      return;
    }
    await builder.addDartFileEdit(file, (builder) {
      final signalBuilder = builder.importSignalBuilder();
      builder.addSimpleInsertion(
        node.offset,
        '$signalBuilder(\n'
        '  builder: (context, child) {\n'
        '    return ',
      );
      builder.addSimpleInsertion(node.end, ';\n  },\n)');
    });
  }
}
