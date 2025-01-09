import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

final firstNameProvider = Provider((context) => Signal("James"), lazy: false);
final lastNameProvider = Provider((context) => Signal("Smith"));

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
          firstNameProvider,

          // provide the lastName signal to descendants
          lastNameProvider,
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
    final firstName = firstNameProvider.get(context);
    final lastName = lastNameProvider.get(context);

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // render the first name value
          TextFormField(
            initialValue: firstName.value,
            onChanged: (value) {
              firstNameProvider.update(context, (currentValue) => value);
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: lastName.value,
            onChanged: (value) {
              lastNameProvider.update(context, (currentValue) => value);
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
    final firstName = firstNameProvider.observe(context).value;
    final lastName = lastNameProvider.observe(context).value;
    return ListTile(
      title: Text('First Name: $firstName'),
      subtitle: Text('LastName: $lastName'),
    );
  }
}
