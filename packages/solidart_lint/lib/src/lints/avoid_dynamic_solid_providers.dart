import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// This object is a utility for checking whether a Dart variable is assignable
/// to a given class.
///
/// In this example, the class checked is `ProviderBase` from `package:riverpod`.
const _solidBaseChecker = TypeChecker.fromName(
  'Solid',
  packageName: 'flutter_solidart',
);

class SolidVisitor extends SimpleAstVisitor {
  @override
  visitClassDeclaration(ClassDeclaration node) {
    print('class $node');
    return node;
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    print('contructor declaration: $node');
    return node;
  }

  @override
  visitConstructorName(ConstructorName node) {
    print('visit contructor name $node');
    return node;
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    print("visitConstructorFieldInitializer $node");
    return node;
  }
}

class AvoidDynamicSolidProviders extends DartLintRule {
  const AvoidDynamicSolidProviders() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_dynamic_solid_providers',
    errorSeverity: ErrorSeverity.ERROR,
    problemMessage: 'SolidProviders should have the type specified explicitly',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addNamedType((node) {
      if (node.name.name != 'SolidProvider') return;
      print('found solid provider');
      print(node.type?.getDisplayString(withNullability: false));
      if (node.type?.getDisplayString(withNullability: false) ==
          'SolidProvider<dynamic>') {
        reporter.reportErrorForNode(_code, node);
      }
    });
    // context.registry.addClassDeclaration((node) {
    //   print(node.name);
    // });
    // context.registry.addTypeParameterList((node) {
    //   print("type param: $node");
    // });
    // context.registry.addMethodDeclaration((node) {
    //   if (node.name.value() != 'build') return;
    //
    //   print('inside build ${node.body.accept(SolidVisitor())}');
    // });
// Using this function, we search for [VariableDeclaration] reference the
    // analyzed Dart file.
    // context.registry.addVariableDeclaration((node) {
    //   final element = node.declaredElement;
    //   print("element: $element");
    //   if (element == null ||
    //       element.isFinal ||
    //       // We check that the variable is a Riverpod provider
    //       !_solidBaseChecker.isAssignableFromType(element.type)) {
    //     return;
    //   }
    //
    //   // This emits our lint warning at the location of the variable.
    //   reporter.reportErrorForElement(code, element);
    // });
  }
}
