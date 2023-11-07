import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:pub/bloc/pub_search/bloc.dart';

class PubSearchBlocProvider extends StatelessWidget {
  const PubSearchBlocProvider({
    super.key,
    this.child,
    this.builder,
  });

  final Widget? child;
  final WidgetBuilder? builder;

  @override
  Widget build(BuildContext context) {
    return Solid(
      providers: [
        Provider<PubSearchBloc>(
          create: () => PubSearchBloc(),
          dispose: (bloc) => bloc.dispose(),
        ),
      ],
      builder: builder,
      child: child,
    );
  }
}
