import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:solidart_lint/src/assists/base/wrap_builder.dart';

class WrapWithSignalBuilder extends WrapBuilder {
  WrapWithSignalBuilder({required super.context})
    : super(
        builderName: 'SignalBuilder',
        extraNamedParams: const [],
        extraBuilderParams: const ['child'],
      );

  @override
  AssistKind get assistKind => const AssistKind(
    'solidart.wrap_with_signal_builder',
    30,
    'Wrap with SignalBuilder',
  );
}
