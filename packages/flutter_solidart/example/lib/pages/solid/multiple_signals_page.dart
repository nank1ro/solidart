import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

// Using an Enum as a key for SolidSignals, you can use any type of key
enum SignalId {
  firstName,
  lastName,
}

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
          SolidSignal<Signal<String>>(
            create: () => createSignal("James"),
            id: SignalId.firstName,
          ),

          // provide the lastName signal to descendants
          SolidSignal<Signal<String>>(
            create: () => createSignal("Smith"),
            id: SignalId.lastName,
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
    final firstName = context.get<Signal<String>>(SignalId.firstName);
    final lastName = context.get<Signal<String>>(SignalId.lastName);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the first name value
          TextFormField(
            initialValue: firstName.value,
            onChanged: (value) {
              context.update<String>((_) => value, SignalId.firstName);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: lastName.value,
            onChanged: (value) {
              context.update<String>((_) => value, SignalId.lastName);
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
    final firstName = context.observe<String>(SignalId.firstName);
    final lastName = context.observe<String>(SignalId.lastName);
    return ListTile(
      title: Text('First Name: $firstName'),
      subtitle: Text('LastName: $lastName'),
    );
  }
}
