/// Generates a unique id based on the timestamp of when this method has been invoked.
String uuid() {
  return DateTime.now().microsecondsSinceEpoch.toString();
}
