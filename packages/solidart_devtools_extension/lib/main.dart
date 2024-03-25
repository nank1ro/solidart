import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

void main() {
  runApp(const FooDevToolsExtension());
}

class FooDevToolsExtension extends StatelessWidget {
  const FooDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: Signals(),
    );
  }
}

/// String extensions
extension StringExt on String {
  /// Capitalizes the first word in the string, e.g.:
  /// `hello world` becomes `Hello world`.
  String capitalizeFirst() {
    if (length == 0) return '';
    if (length == 1) return toUpperCase();
    return substring(0, 1).toUpperCase() + substring(1);
  }
}

class Signals extends StatefulWidget {
  const Signals({super.key});

  @override
  State<Signals> createState() => _SignalsState();
}

enum SignalType {
  readSignal,
  signal,
  computed,
  resource,
  listSignal,
  mapSignal,
  setSignal;

  static SignalType byName(String name) {
    return switch (name) {
      'ReadSignal' => SignalType.readSignal,
      'Signal' => SignalType.signal,
      'Computed' => SignalType.computed,
      'Resource' => SignalType.resource,
      'ListSignal' => SignalType.listSignal,
      'MapSignal' => SignalType.mapSignal,
      'SetSignal' => SignalType.setSignal,
      _ => SignalType.signal,
    };
  }
}

class SignalData {
  const SignalData({
    required this.value,
    required this.hasPreviousValue,
    required this.previousValue,
    required this.type,
    required this.disposed,
    required this.autoDispose,
    required this.listenerCount,
    required this.valueType,
    required this.previousValueType,
    required this.lastUpdate,
  });

  final Object? value;
  final bool hasPreviousValue;
  final Object? previousValue;
  final SignalType type;
  final bool disposed;
  final bool autoDispose;
  final int listenerCount;
  final String valueType;
  final String? previousValueType;
  final DateTime lastUpdate;

  bool matchesSearch(String search) {
    return value.toString().toLowerCase().contains(search) ||
        previousValue.toString().toLowerCase().contains(search) ||
        valueType.toLowerCase().contains(search) ||
        (previousValueType != null &&
            previousValueType!.toLowerCase().contains(search));
  }
}

class _SignalsState extends State<Signals> {
  late final StreamSubscription<Object>? sub;
  final selectedSignalName = Signal<String?>(null);
  final searchController = SearchController();
  final searchText = Signal<String>('');
  final filterType = Signal<SignalType?>(null);
  final showDisposed = Signal<bool>(true);
  final signals = MapSignal<String, SignalData>({});

  late final filteredSignals = Computed(() {
    final lowercasedSearch = searchText().toLowerCase();
    final type = filterType();
    final viewDisposed = showDisposed();
    return signals()
        .entries
        .where((entry) =>
            entry.key.toString().toLowerCase().contains(lowercasedSearch) ||
            entry.value.matchesSearch(lowercasedSearch))
        .where((entry) => type == null || entry.value.type == type)
        .where((entry) => viewDisposed || !entry.value.disposed)
        .toList();
  });

  @override
  void initState() {
    super.initState();
    sub = serviceManager.service?.onExtensionEvent
        .where((e) => e.extensionKind?.startsWith('solidart.signal') ?? false)
        .listen((event) {
      final data = event.extensionData?.data;
      if (data == null) return;
      switch (event.extensionKind) {
        case 'solidart.signal.created':
        case 'solidart.signal.updated':
        case 'solidart.signal.disposed':
          signals[data['name']] = SignalData(
            value: jsonDecode(data['value'] ?? 'null'),
            hasPreviousValue: data['hasPreviousValue'],
            previousValue: jsonDecode(data['previousValue'] ?? 'null'),
            type: SignalType.byName(data['type']),
            disposed: data['disposed'],
            autoDispose: data['autoDispose'],
            listenerCount: data['listenerCount'],
            valueType: data['valueType'],
            previousValueType: data['previousValueType'],
            lastUpdate: DateTime.parse(data['lastUpdate']!),
          );
      }
    });
    searchController.addListener(() => searchText.set(searchController.text));
  }

  @override
  void dispose() {
    sub?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchBar(
                    hintText: 'Search signals',
                    controller: searchController,
                    trailing: [
                      Show(
                        when: () => searchText().isNotEmpty,
                        builder: (context) {
                          return IconButton(
                            onPressed: searchController.clear,
                            icon: const Icon(Icons.clear),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SignalBuilder(builder: (context, _) {
                        return DropdownButton(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          value: filterType(),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          hint: const Text('Type'),
                          icon: filterType() == null
                              ? null
                              : IconButton(
                                  onPressed: () => filterType.set(null),
                                  icon: const Icon(Icons.clear),
                                ),
                          items: SignalType.values
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name.capitalizeFirst()),
                                  ))
                              .toList(),
                          onChanged: filterType.set,
                        );
                      }),
                      const SizedBox(width: 4),
                      SignalBuilder(
                        builder: (context, _) {
                          return FilterChip(
                            selected: showDisposed(),
                            label: const Text('Disposed'),
                            onSelected: showDisposed.set,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SignalBuilder(
                    builder: (context, _) {
                      return Text(
                          '${filteredSignals().length} visible of ${signals().length}');
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SignalBuilder(builder: (context, _) {
                      return ListView.separated(
                        itemCount: filteredSignals().length,
                        itemBuilder: (BuildContext context, int index) {
                          final entry = filteredSignals().elementAt(index);
                          final name = entry.key;
                          final signal = entry.value;
                          return SignalBuilder(
                            builder: (context, _) {
                              final selected = selectedSignalName() == name;
                              return Stack(
                                children: [
                                  ListTile(
                                    selectedTileColor:
                                        theme.colorScheme.onSecondary,
                                    selectedColor:
                                        theme.colorScheme.onSurfaceVariant,
                                    tileColor: theme.colorScheme.surfaceVariant,
                                    title: Text(name),
                                    titleAlignment:
                                        ListTileTitleAlignment.center,
                                    trailing: selected
                                        ? const Icon(Icons.east_rounded)
                                        : null,
                                    selected: selected,
                                    subtitle: Row(
                                      children: [
                                        Chip(
                                          label: Text(
                                            signal.type.name.capitalizeFirst(),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Chip(
                                          label: Text(signal.valueType),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      selectedSignalName.value = name;
                                    },
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 10,
                                      decoration: BoxDecoration(
                                        color: signal.disposed
                                            ? Colors.red
                                            : Colors.green,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SignalBuilder(
            builder: (context, _) {
              if (selectedSignalName() == null) return const SizedBox();
              final signal = filteredSignals()
                  .firstWhereOrNull(
                      (element) => element.key == selectedSignalName())
                  ?.value;
              if (signal == null) return const SizedBox();
              return Card(
                key: ValueKey(selectedSignalName()),
                child: LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Column(
                        children: [
                          ParameterView(
                              name: 'name', value: selectedSignalName()),
                          ParameterView(
                              name: 'type',
                              value: signal.type.name.capitalizeFirst()),
                          ParameterView(name: 'value', value: signal.value),
                          ParameterView(
                            name: 'previousValue',
                            value: signal.previousValue,
                          ),
                          ParameterView(
                            name: 'hasPreviousValue',
                            value: signal.hasPreviousValue,
                          ),
                          ParameterView(
                            name: 'disposed',
                            value: signal.disposed,
                          ),
                          ParameterView(
                            name: 'autoDispose',
                            value: signal.autoDispose,
                          ),
                          ParameterView(
                            name: 'listenerCount',
                            value: signal.listenerCount,
                          ),
                          ParameterView(
                            name: 'lastUpdate',
                            value: signal.lastUpdate,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ParameterView extends StatefulWidget {
  const ParameterView({
    super.key,
    required this.name,
    this.value,
  });

  final String name;
  final Object? value;

  @override
  State<ParameterView> createState() => _ParameterViewState();
}

class _ParameterViewState extends State<ParameterView> {
  bool expanded = false;

  @override
  void didUpdateWidget(covariant ParameterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isExpandible) expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        DefaultTextStyle(
          style:
              theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
          child: InkWell(
            onTap: isExpandible
                ? () => setState(() => expanded = !expanded)
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Visibility.maintain(
                      visible: isExpandible,
                      child: RotatedBox(
                        quarterTurns: expanded ? 1 : 0,
                        child: const Icon(Icons.arrow_right_rounded),
                      ),
                    ),
                    Text('${widget.name}: '),
                  ],
                ),
                const SizedBox(width: 4),
                Expanded(child: getView()),
              ],
            ),
          ),
        ),
        getExpandedView(),
      ],
    );
  }

  bool get isExpandible {
    if (widget.value is List && (widget.value as List).isNotEmpty) return true;
    if (widget.value is Map && (widget.value as Map).isNotEmpty) return true;
    return false;
  }

  Widget getView() {
    if (widget.value == null) {
      return const SelectableText(
        'null',
        style: TextStyle(color: Color(0xFFFF79C6)),
      );
    }
    if (widget.value is num) {
      return SelectableText(
        widget.value.toString(),
        style: const TextStyle(color: Colors.blue),
      );
    }
    if (widget.value is bool) {
      return SelectableText(
        widget.value.toString(),
        style: const TextStyle(color: Color(0xFFBC93F9)),
      );
    }
    if (widget.value is DateTime) {
      final date = widget.value as DateTime;
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
      return SelectableText(
        dateString,
        style: const TextStyle(color: Color(0xFFF1FA8C)),
      );
    }
    if (widget.value is List) {
      final list = widget.value as List;
      if (list.isEmpty) {
        return Text(
          '${widget.value.runtimeType}(0)',
          style: TextStyle(color: Colors.grey[600]),
        );
      } else {
        return Text(
          '${widget.value.runtimeType}(${list.length})',
          style: TextStyle(color: Colors.grey[600]),
        );
      }
    }

    if (widget.value is Map) {
      final list = widget.value as Map;
      if (list.isEmpty) {
        return Text(
          '${widget.value.runtimeType}(0)',
          style: TextStyle(color: Colors.grey[600]),
        );
      } else {
        return Text(
          '${widget.value.runtimeType}(${list.length})',
          style: TextStyle(color: Colors.grey[600]),
        );
      }
    }

    return SelectableText(
      '"${widget.value.toString()}"',
      style: TextStyle(
        color: Theme.of(context).isDarkTheme
            ? const Color(0xFFF1FA8C)
            : Colors.green,
      ),
    );
  }

  Widget getExpandedView() {
    if (!expanded) return const SizedBox();
    if (widget.value is List) {
      final list = widget.value as List;
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          children: [
            for (var i = 0; i < list.length; i++)
              ParameterView(name: '$i', value: list[i]),
          ],
        ),
      );
    }
    if (widget.value is Map) {
      final map = widget.value as Map;
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          children: map.entries
              .map((e) => ParameterView(name: e.key, value: e.value))
              .toList(),
        ),
      );
    }
    throw Exception(
        'Unsupported expanded view for type: ${widget.value.runtimeType}');
  }
}
