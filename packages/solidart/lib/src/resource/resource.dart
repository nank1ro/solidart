// ignore_for_file: public_member_api_docs

import 'package:solidart/src/resource/state.dart';
import 'package:solidart/src/signal.dart';

part '_resource.impl.dart';

abstract interface class Resource<T>
    implements ReadonlySignal<ResourceState<T>> {
  ResourceState<T> get state;
}
