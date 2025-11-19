import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:solidart_lint/src/assists/base/wrap_single_widget.dart';

class WrapWithProviderScope extends WrapSingleWidget {
  WrapWithProviderScope({required super.context})
    : super(
        widgetName: 'ProviderScope',
        extraNamedParams: const ['providers: []'],
      );

  @override
  AssistKind get assistKind => const AssistKind(
    'solidart.wrap_with_provider_scope',
    29,
    'Wrap with ProviderScope',
  );
}
