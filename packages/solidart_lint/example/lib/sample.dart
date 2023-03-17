import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Future<int> getNumber() => Future.value(1);

  late final resource = createResource(fetcher: getNumber);

  @override
  Widget build(BuildContext context) {
    return ResourceBuilder(
      resource: resource,
      builder: (context, resourceValue) {
        return resourceValue.on(
          ready: (value, isRefreshing) {
            return Container();
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text('$error'),
        );
      },
    );
  }
}
