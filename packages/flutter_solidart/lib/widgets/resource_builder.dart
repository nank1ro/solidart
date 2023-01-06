import 'package:flutter/material.dart';
import 'package:flutter_solidart/widgets/signal_builder.dart';
import 'package:solidart/solidart.dart';

typedef ResourceWidgetBuilder<R> = Widget Function(
  BuildContext context,
  ResourceValue<R> resource,
);

class ResourceBuilder<T, R> extends StatefulWidget {
  const ResourceBuilder({
    super.key,
    required this.resource,
    required this.builder,
  });

  final Resource<T, R> resource;
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
    return SignalBuilder<ResourceValue<R>>(
      signal: widget.resource,
      builder: (context, value, __) {
        return widget.builder(context, value);
      },
    );
  }
}
