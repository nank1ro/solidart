// ignore_for_file: public_member_api_docs

int _nextId = 0;

@pragma('vm:prefer-inline')
@pragma('wasm:prefer-inline')
@pragma('dart2js:prefer-inline')
String nameFor(String name) => '$name@${_nextId++}';
