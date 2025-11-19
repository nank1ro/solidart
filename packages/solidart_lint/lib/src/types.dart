import 'package:solidart_lint/src/type_checker.dart';

final buildContextType = TypeChecker.fromName('BuildContext');
final signalBaseType =
    TypeChecker.fromName('SignalBase', packageName: 'solidart');
final solidType =
    TypeChecker.fromName('Solid', packageName: 'flutter_solidart');
final providerType =
    TypeChecker.fromName('Provider', packageName: 'flutter_solidart');

const widgetType = TypeChecker.fromName('Widget', packageName: 'flutter');
