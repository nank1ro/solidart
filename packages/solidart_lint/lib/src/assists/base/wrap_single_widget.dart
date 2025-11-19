import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';

/// A correction processor that can make one of the possible changes computed by
/// the [FlutterWrap] producer.
abstract class WrapSingleWidget extends ResolvedCorrectionProducer {
  WrapSingleWidget({
    required super.context,
    required this.widgetName,
    required this.packageImport,
    this.extraNamedParams = const [],
  });

  final String packageImport;
  final String widgetName;
  final List<String> extraNamedParams;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final widgetExpr = node.findWidgetExpression;
    if (widgetExpr == null) return;
    var widgetSrc = utils.getNodeText(widgetExpr);

    final widgetElement = await sessionHelper.getClass(
      packageImport,
      widgetName,
    );

    if (widgetElement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      builder.addReplacement(range.node(widgetExpr), (builder) {
        builder.writeReference(widgetElement);
        builder.write('(');
        // When there's no linked edit for the widget name, leave the selection
        // inside the opening paren which is useful if you want to add
        // additional named arguments to the newly-created widget.
        builder.selectHere();
        if (widgetSrc.contains(eol) || extraNamedParams.isNotEmpty) {
          var indentOld = utils.getLinePrefix(widgetExpr.offset);
          var indentNew = '$indentOld${utils.oneIndent}';

          for (final namedParam in extraNamedParams) {
            builder.writeln();
            builder.write(indentNew);
            builder.write(namedParam);
          }

          builder.writeln();
          builder.write(indentNew);
          widgetSrc = utils.replaceSourceIndent(
            widgetSrc,
            indentOld,
            indentNew,
          );
          widgetSrc += ',$eol$indentOld';
        }
        builder.write('child');
        builder.write(': ');
        builder.write(widgetSrc);
        builder.write(')');
      });
    });
  }
}
