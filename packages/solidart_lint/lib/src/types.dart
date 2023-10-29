import 'package:custom_lint_builder/custom_lint_builder.dart';

final buildContextType = TypeChecker.fromName('BuildContext');
final signalBaseType =
    TypeChecker.fromName('SignalBase', packageName: 'solidart');
final solidType =
    TypeChecker.fromName('Solid', packageName: 'flutter_solidart');
final providerType =
    TypeChecker.fromName('Provider', packageName: 'flutter_solidart');
