import 'package:flutter/material.dart';

extension PlainString on List {
  String toPlainString() {
    return toString().replaceFirst('[', '').replaceFirst(']', '');
  }
}

extension ErrorSnackbar on BuildContext {
  void showErrorSnackbar(String msg) {
    final snackBar = SnackBar(content: Text('Oops something went wrong: $msg'));
    ScaffoldMessenger.of(this).showSnackBar(snackBar);
    // ref.read(pokemonControllerProvider).consumeError();
  }
}
