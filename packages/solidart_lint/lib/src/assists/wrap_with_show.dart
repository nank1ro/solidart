import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:solidart_lint/src/assists/base/wrap_builder.dart';

class WrapWithShow extends WrapBuilder {
  WrapWithShow({required super.context})
    : super(
        builderName: 'Show',
        extraNamedParams: const ['when', 'fallback'],
        extraBuilderParams: const [],
      );

  @override
  AssistKind get assistKind =>
      const AssistKind('solidart.wrap_with_show', 28, 'Wrap with Show');
}
