import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final _firstNameId = ProviderId<Signal<String>>();
final _lastNameId = ProviderId<Signal<String>>();

// Uses identifiers to retrieve different signals of the same type
class MultipleSignalsPage extends StatelessWidget {
  const MultipleSignalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Signals'),
      ),
      body: ProviderScope(
        providers: [
          // provide the firstName signal to descendants
          _firstNameId.createProvider(
            init: () => Signal("James"),
            lazy: false,
          ),

          // provide the lastName signal to descendants
          _lastNameId.createProvider(
            init: () => Signal("Smith"),
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
    final firstName = _firstNameId.get(context);
    final lastName = _lastNameId.get(context);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the first name value
          TextFormField(
            initialValue: firstName.value,
            onChanged: (value) {
              _firstNameId.update(context, (_) => value);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: lastName.value,
            onChanged: (value) {
              _lastNameId.update(context, (_) => value);
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
    final firstName = _firstNameId.observe(context).value;
    final lastName = _lastNameId.observe(context).value;
    return ListTile(
      title: Text('First Name: $firstName'),
      subtitle: Text('LastName: $lastName'),
    );
  }
}
