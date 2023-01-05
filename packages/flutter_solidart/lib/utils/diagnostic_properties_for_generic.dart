import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DiagnosticPropertiesForGeneric<T> {
  DiagnosticPropertiesForGeneric({
    required this.value,
    required this.name,
    required this.properties,
  }) {
    evaluateType();
  }

  final T value;
  final String name;
  final DiagnosticPropertiesBuilder properties;

  void evaluateType() {
    if (T == String) {
      properties.add(
        StringProperty(
          name,
          value as String?,
        ),
      );
    }
    if (T == int) {
      properties.add(
        IntProperty(
          name,
          value as int?,
        ),
      );
    }
    if (T == double) {
      properties.add(
        DoubleProperty(
          name,
          value as double?,
        ),
      );
    }

    if (T == Enum) {
      properties.add(
        EnumProperty(
          name,
          value as Enum?,
        ),
      );
    }

    if (T == bool) {
      properties.add(
        DiagnosticsProperty<bool>(
          name,
          value as bool?,
        ),
      );
    }

    if (T == Iterable) {
      properties.add(
        IterableProperty(
          name,
          value as Iterable?,
        ),
      );
    }
    if (T == Color) {
      properties.add(
        ColorProperty(
          name,
          value as Color?,
        ),
      );
    }

    if (T == IconData) {
      properties.add(
        IconDataProperty(
          name,
          value as IconData?,
        ),
      );
    }
  }
}
