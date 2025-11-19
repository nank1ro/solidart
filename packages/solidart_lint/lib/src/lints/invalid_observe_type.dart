import 'package:analyzer/error/error.dart' as analyzer_error;
import 'package:analyzer/error/listener.dart';
// import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart_lint/src/types.dart';

// class InvalidObserveType extends DartLintRule {
//   const InvalidObserveType() : super(code: _code);

//   static const _code = LintCode(
//     name: 'invalid_observe_type',
//     errorSeverity: analyzer_error.DiagnosticSeverity.ERROR,
//     problemMessage:
//         'The observe type is invalid, must not implement SignalBase',
//   );

//   @override
//   void run(
//     CustomLintResolver resolver,
//     DiagnosticReporter reporter,
//     CustomLintContext context,
//   ) {
//     context.registry.addMethodInvocation(
//       (node) async {
//         if (node.methodName.name == 'observe') {
//           if (node.target?.staticType == null) return;

//           final isContext =
//               buildContextType.isExactlyType(node.target!.staticType!);
//           if (!isContext) return;
//           if (node.staticType == null) return;
//           final typeArgument = node.typeArguments?.arguments.firstOrNull?.type;
//           if (typeArgument == null) {
//             reporter.atNode(node, _code);
//             return;
//           }
//           final isSignalBase =
//               signalBaseType.isAssignableFromType(node.staticType!);
//           if (isSignalBase) {
//             reporter.atNode(node, _code);
//           }
//         }
//       },
//     );
//   }
// }
