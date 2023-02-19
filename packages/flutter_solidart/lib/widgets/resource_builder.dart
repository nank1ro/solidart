import 'package:flutter/material.dart';
import 'package:flutter_solidart/widgets/signal_builder.dart';
import 'package:solidart/solidart.dart';

typedef ResourceWidgetBuilder<ResultType> = Widget Function(
  BuildContext context,
  ResourceValue<ResultType> resource,
);

class ResourceBuilder<ResultType> extends StatefulWidget {
  const ResourceBuilder({
    super.key,
    required this.resource,
    required this.builder,
  });

  final Resource<ResultType> resource;
  final ResourceWidgetBuilder<ResultType> builder;

  @override
  State<ResourceBuilder<ResultType>> createState() =>
      _ResourceBuilderState<ResultType>();
}

class _ResourceBuilderState<ResultType>
    extends State<ResourceBuilder<ResultType>> {
  @override
  void initState() {
    super.initState();
    widget.resource.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder<ResourceValue<ResultType>>(
      signal: widget.resource,
      builder: (context, value, __) {
        return widget.builder(context, value);
      },
    );
  }
}
