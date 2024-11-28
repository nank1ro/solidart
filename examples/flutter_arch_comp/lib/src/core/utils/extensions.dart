extension PlainString on List {
  String toPlainString() {
    return toString().replaceFirst('[', '').replaceFirst(']', '');
  }
}
