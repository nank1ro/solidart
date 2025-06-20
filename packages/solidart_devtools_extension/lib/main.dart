import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:devtools_app_shared/ui.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

enum FilterType {
  name,
  lastUpdate,
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
  final sortBy = Signal<FilterType>(FilterType.name);
  final showDisposed = Signal<bool>(true);
  final signals = MapSignal<String, SignalData>({});

  late final filteredSignals = Computed(() {
    final lowercasedSearch = searchText.value.toLowerCase();
    final type = filterType.value;
    final viewDisposed = showDisposed.value;
    return signals.value.entries
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
    initialize();
  }

  Future<void> initialize() async {
    final vmService = await serviceManager.onServiceAvailable;
    print('serviceManager: ${serviceManager.service}');
    sub = vmService.onExtensionEvent.where((e) {
      print('got event: ${e.extensionKind}');
      return e.extensionKind?.startsWith('ext.solidart.signal') ?? false;
    }).listen((event) {
      print('got event: ${event.extensionKind}');
      final data = event.extensionData?.data;
      if (data == null) return;
      switch (event.extensionKind) {
        case 'ext.solidart.signal.created':
        case 'ext.solidart.signal.updated':
        case 'ext.solidart.signal.disposed':
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
    searchController
        .addListener(() => searchText.value = searchController.text);
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

    final lightTheme = ShadThemeData(
      brightness: Brightness.light,
      colorScheme: ShadSlateColorScheme.light(),
    );
    final darkTheme = ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: ShadSlateColorScheme.dark(),
    );

    return ShadApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: theme.brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            final shadTheme = ShadTheme.of(context);
            return ShadResizablePanelGroup(
              showHandle: true,
              children: [
                ShadResizablePanel(
                  id: 'sidebar',
                  minSize: 0.3,
                  defaultSize: .5,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      spacing: 2,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShadInput(
                          placeholder: Text('Search signals'),
                          controller: searchController,
                          trailing: Show(
                            when: () => searchText.value.isNotEmpty,
                            builder: (context) {
                              return ShadIconButton(
                                onPressed: searchController.clear,
                                width: 20,
                                height: 20,
                                padding: EdgeInsets.zero,
                                decoration: const ShadDecoration(
                                  secondaryBorder: ShadBorder.none,
                                  secondaryFocusedBorder: ShadBorder.none,
                                ),
                                icon: const Icon(Icons.clear, size: 14),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: SignalBuilder(builder: (context, _) {
                                return ShadSelect<SignalType>(
                                  selectedOptionBuilder: (context, v) {
                                    return Text(v.name.capitalizeFirst());
                                  },
                                  allowDeselection: true,
                                  placeholder: const Text('Type'),
                                  initialValue: filterType.value,
                                  options: SignalType.values
                                      .map((e) => ShadOption(
                                            value: e,
                                            child:
                                                Text(e.name.capitalizeFirst()),
                                          ))
                                      .toList(),
                                  onChanged: (v) => filterType.value = v,
                                );
                              }),
                            ),
                            SizedBox(
                              height: 20,
                              child: const ShadSeparator.vertical(),
                            ),
                            Flexible(
                              child: SignalBuilder(builder: (context, _) {
                                return ShadSelect(
                                  selectedOptionBuilder: (context, v) {
                                    return Text(v.name.capitalizeFirst());
                                  },
                                  placeholder: const Text('Sort by'),
                                  initialValue: sortBy.value,
                                  options: FilterType.values
                                      .map((e) => ShadOption(
                                            value: e,
                                            child:
                                                Text(e.name.capitalizeFirst()),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    sortBy.value = v;
                                  },
                                );
                              }),
                            ),
                            SizedBox(
                              height: 20,
                              child: const ShadSeparator.vertical(),
                            ),
                            Flexible(
                              child: SignalBuilder(
                                builder: (context, _) {
                                  return ShadCheckbox(
                                    value: showDisposed.value,
                                    label: const Text('Show disposed'),
                                    padding: EdgeInsets.only(left: 4),
                                    onChanged: (v) => showDisposed.value = v,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SignalBuilder(
                          builder: (context, _) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${filteredSignals.value.length} visible of ${signals.value.length}',
                                style: shadTheme.textTheme.muted,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SignalBuilder(builder: (context, _) {
                            final sortedBy = sortBy.value;
                            return ListView.separated(
                              itemCount: filteredSignals.value.length,
                              itemBuilder: (BuildContext context, int index) {
                                final sortedSignals = filteredSignals.value
                                  ..sort((a, b) {
                                    if (sortedBy == FilterType.name) {
                                      return a.key.compareTo(b.key);
                                    } else if (sortedBy ==
                                        FilterType.lastUpdate) {
                                      return b.value.lastUpdate
                                          .compareTo(a.value.lastUpdate);
                                    }
                                    return 0;
                                  });
                                final entry = sortedSignals.elementAt(index);
                                final name = entry.key;
                                final signal = entry.value;
                                return SignalBuilder(
                                  builder: (context, _) {
                                    final selected =
                                        selectedSignalName.value == name;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: Stack(
                                        children: [
                                          ShadGestureDetector(
                                            cursor: SystemMouseCursors.click,
                                            onTap: () {
                                              selectedSignalName.value = name;
                                            },
                                            child: ShadCard(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                      horizontal: 24),
                                              title: Text(name),
                                              backgroundColor: selected
                                                  ? shadTheme.colorScheme.accent
                                                  : null,
                                              trailing: selected
                                                  ? const Icon(
                                                      LucideIcons.chevronRight)
                                                  : null,
                                              description: Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: [
                                                  ShadBadge(
                                                    child: Text(
                                                      signal.type.name
                                                          .capitalizeFirst(),
                                                    ),
                                                    onPressed: () {
                                                      selectedSignalName.value =
                                                          name;
                                                    },
                                                  ),
                                                  ShadBadge(
                                                    child:
                                                        Text(signal.valueType),
                                                    onPressed: () {
                                                      selectedSignalName.value =
                                                          name;
                                                    },
                                                  ),
                                                  ShadBadge(
                                                    child: Text(
                                                      DateFormat(
                                                              'yyyy-MM-dd hh:mm:ss',
                                                              Localizations
                                                                      .localeOf(
                                                                          context)
                                                                  .toLanguageTag())
                                                          .format(signal
                                                              .lastUpdate),
                                                    ),
                                                    onPressed: () {
                                                      selectedSignalName.value =
                                                          name;
                                                    },
                                                  ),
                                                ],
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
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topRight: Radius.circular(8),
                                                  bottomRight:
                                                      Radius.circular(8),
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                ShadResizablePanel(
                    id: 'detail',
                    defaultSize: .5,
                    minSize: 0.3,
                    child: SignalBuilder(
                      builder: (context, _) {
                        if (selectedSignalName.value == null) {
                          return const SizedBox();
                        }
                        final signal = filteredSignals.value
                            .firstWhereOrNull((element) =>
                                element.key == selectedSignalName.value)
                            ?.value;
                        if (signal == null) return const SizedBox();
                        return KeyedSubtree(
                          key: ValueKey(selectedSignalName.value),
                          child: LayoutBuilder(builder: (context, constraints) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 24),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight - 48,
                                ),
                                child: Column(
                                  children: [
                                    ParameterView(
                                        name: 'name',
                                        value: selectedSignalName.value),
                                    ParameterView(
                                        name: 'type',
                                        value:
                                            signal.type.name.capitalizeFirst()),
                                    ParameterView(
                                        name: 'value', value: signal.value),
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
                    )),
              ],
            );
          },
        ),
      ),
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
    return ShadTheme(
      data: ShadTheme.of(context).copyWith(
        textTheme: ShadTextTheme(family: kDefaultFontFamilyMono),
      ),
      child: Builder(builder: (context) {
        return Column(
          children: [
            DefaultTextStyle(
              style: theme.textTheme.bodyMedium!
                  .copyWith(fontWeight: FontWeight.bold),
              child: InkWell(
                onTap: isExpandible
                    ? () => setState(() => expanded = !expanded)
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Visibility.maintain(
                          visible: isExpandible,
                          child: RotatedBox(
                            quarterTurns: expanded ? 1 : 0,
                            child: const Icon(LucideIcons.chevronRight),
                          ),
                        ),
                        Text('${widget.name}: ',
                            style: ShadTheme.of(context).textTheme.p),
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
      }),
    );
  }

  bool get isExpandible {
    if (widget.value is List && (widget.value as List).isNotEmpty) return true;
    if (widget.value is Map && (widget.value as Map).isNotEmpty) return true;
    return false;
  }

  Widget getView() {
    final isDark = Theme.of(context).isDarkTheme;
    final textTheme = ShadTheme.of(context).textTheme;

    if (widget.value == null) {
      return SelectableText(
        'null',
        style: textTheme.p.copyWith(color: Color(0xFFFF79C6)),
      );
    }
    if (widget.value is num) {
      return SelectableText(
        widget.value.toString(),
        style: textTheme.p.copyWith(color: Colors.blue),
      );
    }
    if (widget.value is bool) {
      return SelectableText(
        widget.value.toString(),
        style: textTheme.p.copyWith(color: Color(0xFFBC93F9)),
      );
    }
    if (widget.value is DateTime) {
      final date = widget.value as DateTime;
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
      return SelectableText(
        dateString,
        style: textTheme.p.copyWith(
          color: isDark ? Colors.yellow : Colors.orange,
        ),
      );
    }
    if (widget.value is List) {
      final list = widget.value as List;
      if (list.isEmpty) {
        return Text(
          '${widget.value.runtimeType}(0)',
          style: ShadTheme.of(context).textTheme.muted,
        );
      } else {
        return Text(
          '${widget.value.runtimeType}(${list.length})',
          style: ShadTheme.of(context).textTheme.muted,
        );
      }
    }

    if (widget.value is Map) {
      final list = widget.value as Map;
      if (list.isEmpty) {
        return Text(
          '${widget.value.runtimeType}(0)',
          style: ShadTheme.of(context).textTheme.muted,
        );
      } else {
        return Text(
          '${widget.value.runtimeType}(${list.length})',
          style: ShadTheme.of(context).textTheme.muted,
        );
      }
    }

    return SelectableText(
      '"${widget.value.toString()}"',
      style: textTheme.p.copyWith(
        color: isDark ? const Color(0xFFF1FA8C) : Colors.green,
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
