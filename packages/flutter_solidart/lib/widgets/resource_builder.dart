import 'package:flutter/material.dart';
import 'package:flutter_solidart/widgets/signal_builder.dart';
import 'package:solidart/solidart.dart';

typedef ResourceWidgetBuilder<FetcherValueType> = Widget Function(
  BuildContext context,
  ResourceValue<FetcherValueType> resource,
);

class ResourceBuilder<FetcherValueType, SignalValueType>
    extends StatefulWidget {
  const ResourceBuilder({
    super.key,
    required this.resource,
    required this.builder,
  });

  final Resource<FetcherValueType, SignalValueType> resource;
  final ResourceWidgetBuilder<FetcherValueType> builder;

  @override
  State<ResourceBuilder<FetcherValueType, SignalValueType>> createState() =>
      _ResourceBuilderState<FetcherValueType, SignalValueType>();
}

class _ResourceBuilderState<FetcherValueType, SignalValueType>
    extends State<ResourceBuilder<FetcherValueType, SignalValueType>> {
  @override
  void initState() {
    super.initState();
    widget.resource.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder<ResourceValue<FetcherValueType>>(
      signal: widget.resource,
      builder: (context, value, __) {
        return widget.builder(context, value);
      },
    );
  }
}
