import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:solidart/solidart.dart';

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
    context.registry.addInstanceCreationExpression((node) {
      // If there is a parameterElement it means we are not declaring a variable
      if (node.staticParameterElement != null) return;

      // Check that the object created is indeed a ProviderContainer
      final type = node.staticType;
      // print("type: $type");
      final name = type?.getDisplayString(withNullability: false);
      // print("name: $name");
      if (name == null) return;
      if (name == 'SolidProvider<dynamic>') {
        reporter.reportErrorForNode(_code, node);
        return;
      }

      // if (type == null || !providerContainerType.isExactlyType(type)) {
      //   return;
      // }
    });
    // context.registry.addNamedType((node) {
    //   if (node.name.name != 'SolidProvider') return;
    //   print('found solid provider');
    //   print(node.type?.getDisplayString(withNullability: false));
    //   if (node.type?.getDisplayString(withNullability: false) ==
    //       'SolidProvider<dynamic>') {
    //     print(node.st);
    //     print(node is VariableDeclaration);
    //     print(node is VariableDeclarationStatement);
    //     print(node.childEntities);
    //     reporter.reportErrorForNode(_code, node);
    //   }
    // });
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

  @override
  List<Fix> getFixes() {
    return [_MakeProviderFinalFix()];
  }
}

/// We define a quick fix for an issue.
///
/// Our quick fix wants to analyze Dart files, so we subclass [DartFix].
/// Fox quick-fixes on non-Dart files, see [Fix].
class _MakeProviderFinalFix extends DartFix {
  /// Similarly to [LintRule.run], [Fix.run] is the core logic of a fix.
  /// It will take care or proposing edits within a file.
  @override
  void run(
    CustomLintResolver resolver,
    // Similar to ErrorReporter, ChangeReporter is an object used for submitting
    // edits within a Dart file.
    ChangeReporter reporter,
    CustomLintContext context,
    // This is the warning that was emitted by our [LintRule] and which we are
    // trying to fix.
    AnalysisError analysisError,
    // This is the other warnings in the same file defined by our [LintRule].
    // Useful in case we want to offer a "fix all" option.
    List<AnalysisError> others,
  ) {
    // Using similar logic as in "PreferFinalProviders", we inspect the Dart file
    // to search for variable declarations.
    context.registry.addInstanceCreationExpression((node) {
      // We verify that the variable declaration is where our warning is located
      print('fix node: $node');

      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      print('entering fix node');

      print(node.childEntities);
      final create = node.childEntities.firstWhereOrNull((element) {
        return element is ArgumentList;
      });
      if (create == null) return;
      final createP = create as ArgumentList;
      print("create: ${createP.childEntities}");
      final create2 = createP.childEntities.firstWhereOrNull((element) {
        print(element.runtimeType);
        print(element);
        return element is NamedExpression;
      });
      if (create2 == null) return;
      final create3 = create2 as NamedExpression;
      print("create3: ${create3.expression.staticType}");

      final create4 =
          create3.expression.childEntities.firstWhereOrNull((element) {
        print(element.runtimeType);
        print(element);
        return element is ExpressionFunctionBody;
      });
      if (create4 == null) return;
      final create5 = create4 as ExpressionFunctionBody;
      final dartType = create5.expression.staticType;
      if (dartType == null) return;
      print("type: $dartType");
      // We define one edit, giving it a message which will show-up in the IDE.
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Assign $dartType type to SolidProvider',
        // This represents how high-low should this qick-fix show-up in the list
        // of quick-fixes.
        priority: 1,
      );

      // Our edit will consist of editing a Dart file, so we invoke "addDartFileEdit".
      // The changeBuilder variable also has utilities for other types of files.
      changeBuilder.addDartFileEdit((builder) {
        // Replace "Type x = ..." into "final Type x = ..."

        // Once again we emit an edit to our file.
        // But this time, we add new content without replacing existing content.
        builder.addSimpleInsertion(
            node.offset + 'SolidProvider'.length, '<$dartType>');
      });
    });
  }
}
