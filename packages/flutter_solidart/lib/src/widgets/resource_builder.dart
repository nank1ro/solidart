import 'package:flutter/material.dart';
import 'package:flutter_solidart/src/widgets/signal_builder.dart';
import 'package:solidart/solidart.dart';

/// Builder function for a [Resource].
typedef ResourceWidgetBuilder<T> = Widget Function(
  BuildContext context,
  ResourceState<T> resourceState,
);

/// {@template resourcebuilder}
/// The `ResourceBuilder` widget makes the consumption of a `Resource`
/// extremely simple.
/// It takes a `resource` and a `builder` fired any time the resource state
/// changes.
///
/// Let's see it in action:
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:flutter_solidart/flutter_solidart.dart';
/// import 'package:http/http.dart' as http;
///
/// class ResourcePage extends StatefulWidget {
///   const ResourcePage({super.key});
///
///   @override
///   State<ResourcePage> createState() => _ResourcePageState();
/// }
///
/// class _ResourcePageState extends State<ResourcePage> {
///   // source
///   final userId = createSignal(1);
///   // resource
///   late final Resource<String> user;
///
///   @override
///   void initState() {
///     super.initState();
///     // creating the resource
///     user = createResource(fetcher: fetchUser, source: userId);
///   }
///
///   @override
///   void dispose() {
///     // disposing the source and resource
///     userId.dispose();
///     user.dispose();
///     super.dispose();
///   }
///
///   // fetcher
///   Future<String> fetchUser() async {
///     print('Fetch user: ${userId.value}');
///     final response = await http.get(
///       Uri.parse('https://swapi.dev/api/people/${userId.value}/'),
///     );
///     return response.body;
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: const Text('Resource'),
///       ),
///       body: Padding(
///         padding: const EdgeInsets.all(16.0),
///         child: Column(
///           children: [
///             TextFormField(
///               initialValue: "1",
///               decoration: const InputDecoration(
///                 hintText: 'Enter numeric id',
///               ),
///               onChanged: (s) {
///                 final intValue = int.tryParse(s);
///                 if (intValue == null) return;
///
///                 userId.value = intValue;
///               },
///             ),
///             const SizedBox(height: 16),
///             ResourceBuilder(
///               resource: user,
///               builder: (_, userValue) {
///                 return userValue.on(
///                   ready: (data, refreshing) {
///                     return Column(
///                       mainAxisSize: MainAxisSize.min,
///                       children: [
///                         ListTile(
///                           title: Text(data),
///                           subtitle: Text('refreshing: $refreshing'),
///                         ),
///                         ElevatedButton(
///                           onPressed: user.refetch,
///                           child: const Text('Refresh'),
///                         ),
///                       ],
///                     );
///                   },
///                   error: (e, _) => Text(e.toString()),
///                   loading: () {
///                     return const RepaintBoundary(
///                       child: CircularProgressIndicator(),
///                     );
///                   },
///                 );
///               },
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// You should not call `resolve()` if you're using ResourceBuilder, because
/// it's already performed by it
/// {@endtemplate}
class ResourceBuilder<T> extends StatefulWidget {
  /// {@macro resourcebuilder}
  const ResourceBuilder({
    super.key,
    required this.resource,
    required this.builder,
  });

  /// The [resource] that needs to be rendered.
  final Resource<T> resource;

  /// The builder of the resource, called every time the resource state changes.
  final ResourceWidgetBuilder<T> builder;

  @override
  State<ResourceBuilder<T>> createState() => _ResourceBuilderState<T>();
}

class _ResourceBuilderState<T> extends State<ResourceBuilder<T>> {
  late Resource<T> effectiveResource;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  // coverage:ignore-start
  @override
  void didUpdateWidget(covariant ResourceBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource != widget.resource) {
      initialize();
    }
  }
  // coverage:ignore-end

  void initialize() {
    effectiveResource = widget.resource;
    // Resolve the resource if it's not resolved yet
    if (widget.resource.state is ResourceUnresolved<T>) {
      widget.resource.resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder<ResourceState<T>>(
      signal: effectiveResource,
      builder: (context, value, __) {
        return widget.builder(context, value);
      },
    );
  }
}
