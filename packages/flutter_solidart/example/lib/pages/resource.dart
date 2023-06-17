import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:http/http.dart' as http;

class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key});

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  final userId = createSignal(1);
  late final Resource<String> user;

  @override
  void initState() {
    super.initState();
    user = createResource(fetcher: fetchUser, source: userId);
  }

  @override
  void dispose() {
    user.dispose();
    userId.dispose();
    super.dispose();
  }

  Future<String> fetchUser() async {
    // simulating a delay to mimic a slow HTTP request
    await Future.delayed(const Duration(seconds: 2));
    final response = await http.get(
      Uri.parse('https://swapi.dev/api/people/${userId.value}/'),
    );
    return response.body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              initialValue: "1",
              decoration: const InputDecoration(
                hintText: 'Enter numeric id',
              ),
              onChanged: (s) {
                final intValue = int.tryParse(s);
                if (intValue == null) return;

                userId.value = intValue;
              },
            ),
            const SizedBox(height: 16),
            ResourceBuilder(
              resource: user,
              builder: (_, userState) {
                return userState.on(
                  ready: (data) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(data),
                          subtitle:
                              Text('refreshing: ${userState.isRefreshing}'),
                        ),
                        userState.isRefreshing
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: user.refetch,
                                child: const Text('Refresh'),
                              ),
                      ],
                    );
                  },
                  error: (e, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.toString()),
                        userState.isRefreshing
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: user.refetch,
                                child: const Text('Refresh'),
                              ),
                      ],
                    );
                  },
                  loading: () {
                    return const RepaintBoundary(
                      child: CircularProgressIndicator(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
