// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@protected
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
      return;
    }
    if (T == int) {
      properties.add(
        IntProperty(
          name,
          value as int?,
        ),
      );
      return;
    }
    if (T == double) {
      properties.add(
        DoubleProperty(
          name,
          value as double?,
        ),
      );
      return;
    }

    if (T == bool) {
      properties.add(
        DiagnosticsProperty<bool>(
          name,
          value as bool?,
        ),
      );
      return;
    }

    if (T == Color) {
      properties.add(
        ColorProperty(
          name,
          value as Color?,
        ),
      );
      return;
    }

    if (T == IconData) {
      properties.add(
        IconDataProperty(
          name,
          value as IconData?,
        ),
      );
      return;
    }

    return properties.add(
      DiagnosticsProperty<T>(
        name,
        value,
      ),
    );
  }
}
