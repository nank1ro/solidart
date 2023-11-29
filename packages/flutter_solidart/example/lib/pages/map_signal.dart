// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

class MapSignalPage extends StatefulWidget {
  const MapSignalPage({super.key});

  @override
  State<MapSignalPage> createState() => _MapSignalPageState();
}

class _MapSignalPageState extends State<MapSignalPage> {
  final items = MapSignal({'a': 1, 'b': 2});

  @override
  void initState() {
    super.initState();
    items.observe((previousValue, value) {
      print("Items changed: $previousValue -> $value");
    });
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(Random().nextInt(_chars.length))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SetSignal')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SignalBuilder(
                signal: items,
                builder: (context, items, __) {
                  return ListView.separated(
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      final key = items.keys.elementAt(index);
                      final value = items[key];
                      return Text('{$key: $value}');
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return const SizedBox(height: 16);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        useLegacyColorScheme: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove),
            label: 'Remove',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.clear_all),
            label: 'Clear all',
          )
        ],
        onTap: (i) {
          switch (i) {
            case 0:
              items.addAll({getRandomString(2): Random().nextInt(100)});
            case 1:
              items.remove(items.keys.last);
            case 2:
              items.clear();
          }
        },
      ),
    );
  }
}
