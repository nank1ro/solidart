import 'package:flutter/material.dart';
import 'package:solidart/src/core/resource.dart';
import 'package:solidart/src/widgets/signal_builder.dart';

typedef ResourceWidgetBuilder<R> = Widget Function(
  BuildContext context,
  Resource<R> resource,
);

class ResourceBuilder<T, R> extends StatefulWidget {
  const ResourceBuilder({
    super.key,
    required this.resource,
    required this.builder,
  });

  final CreateResource<T, R> resource;
  final ResourceWidgetBuilder<R> builder;

  @override
  State<ResourceBuilder<T, R>> createState() => _ResourceBuilderState<T, R>();
}

class _ResourceBuilderState<T, R> extends State<ResourceBuilder<T, R>> {
  @override
  void initState() {
    super.initState();
    widget.resource.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      signal: widget.resource.signal,
      builder: (context, resource, __) {
        return widget.builder(context, resource);
      },
    );
  }
}
