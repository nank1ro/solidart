// ignore_for_file: avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

class ListSignalPage extends StatefulWidget {
  const ListSignalPage({super.key});

  @override
  State<ListSignalPage> createState() => _ListSignalPageState();
}

class _ListSignalPageState extends State<ListSignalPage> {
  final items = ListSignal([1, 2]);

  @override
  void initState() {
    super.initState();
    items.observe((previousValue, value) {
      print("Items changed: $previousValue -> $value");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ListSignal')),
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
                      return Text(items[index].toString());
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
            icon: Icon(Icons.sort),
            label: 'Sort',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.clear_all),
            label: 'Clear all',
          )
        ],
        onTap: (i) {
          switch (i) {
            case 0:
              items.add(Random().nextInt(100));
            case 1:
              items.removeLast();
            case 2:
              items.sort();
            case 3:
              items.clear();
          }
        },
      ),
    );
  }
}
