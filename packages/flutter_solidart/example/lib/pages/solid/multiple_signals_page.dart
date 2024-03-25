import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

// Uses identifiers to retrieve different signals of the same type
class MultipleSignalsPage extends StatelessWidget {
  const MultipleSignalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Signals'),
      ),
      body: Solid(
        providers: [
          // provide the firstName signal to descendants
          Provider<Signal<String>>(
            create: () => Signal("James"),
            id: #firstName,
          ),

          // provide the lastName signal to descendants
          Provider<Signal<String>>(
            create: () => Signal("Smith"),
            id: #lastName,
          ),
        ],
        child: const SomeChild(),
      ),
    );
  }
}

class SomeChild extends StatelessWidget {
  const SomeChild({super.key});

  @override
  Widget build(BuildContext context) {
    final firstName = context.get<Signal<String>>(#firstName);
    final lastName = context.get<Signal<String>>(#lastName);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the first name value
          TextFormField(
            initialValue: firstName.value,
            onChanged: (value) {
              context.update<String>((_) => value, #firstName);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: lastName.value,
            onChanged: (value) {
              context.update<String>((_) => value, #lastName);
            },
          ),
          const SizedBox(height: 8),
          const FullName()
        ],
      ),
    );
  }
}

class FullName extends StatelessWidget {
  const FullName({super.key});

  @override
  Widget build(BuildContext context) {
    final firstName = context.observeSignal<String>(#firstName);
    final lastName = context.observeSignal<String>(#lastName);
    return ListTile(
      title: Text('First Name: $firstName'),
      subtitle: Text('LastName: $lastName'),
    );
  }
}
