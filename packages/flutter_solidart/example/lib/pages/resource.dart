import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:http/http.dart' as http;

class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key});

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  final userId = Signal(1, name: 'userId');

  late final user = Resource(fetchUser, source: userId, name: 'user');

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
            SignalBuilder(
              builder: (context, child) {
                final userState = user.state;
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
                                onPressed: user.refresh,
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
                                onPressed: user.refresh,
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
