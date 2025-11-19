import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

abstract class WrapBuilder extends ResolvedCorrectionProducer {
  final List<String> extraBuilderParams;
  final List<String> extraNamedParams;
  final String builderName;
  final String packageImport;

  WrapBuilder({
    required super.context,
    required this.builderName,
    required this.packageImport,
    this.extraNamedParams = const [],
    this.extraBuilderParams = const [],
  });

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  bool canWrapOn(TypeImpl typeOrThrow) {
    return !typeOrThrow.isExactWidgetTypeBuilder;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final widgetExpr = node.findWidgetExpression;
    if (widgetExpr == null) return;
    if (!canWrapOn(widgetExpr.typeOrThrow)) return;
    var widgetSrc = utils.getNodeText(widgetExpr);

    final builderElement = await sessionHelper.getClass(
      packageImport,
      builderName,
    );

    if (builderElement == null) return;

    final params = ['context', ...extraBuilderParams];

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(widgetExpr), (builder) {
        builder.writeReference(builderElement);

        builder.writeln('(');

        final indentOld = utils.getLinePrefix(widgetExpr.offset);
        final indentNew1 = indentOld + utils.oneIndent;
        final indentNew2 = indentOld + utils.twoIndents;

        for (final namedParam in extraNamedParams) {
          builder.write(indentNew1);
          builder.write('$namedParam: ');
          builder.addSimpleLinkedEdit('variable', namedParam);
          builder.writeln(',');
        }

        builder.write(indentNew1);
        builder.writeln('builder: (${params.join(', ')}) {');

        widgetSrc = utils.replaceSourceIndent(widgetSrc, indentOld, indentNew2);
        builder.write(indentNew2);
        builder.write('return $widgetSrc');
        builder.writeln(';');

        builder.write(indentNew1);
        var addTrailingCommas = getCodeStyleOptions(
          unitResult.file,
        ).addTrailingCommas;
        builder.writeln('}${addTrailingCommas ? "," : ""}');

        builder.write(indentOld);
        builder.write(')');
      });
    });
  }
}
