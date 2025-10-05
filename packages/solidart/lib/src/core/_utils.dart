int _defaultGenerateTypeId = 0;

String createDebugLabel<T>(String? label) {
  if (label != null && label.isNotEmpty) {
    return label;
  }

  return '$T@${_defaultGenerateTypeId++}';
}
