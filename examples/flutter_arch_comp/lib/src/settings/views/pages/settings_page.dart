import 'package:flutter/material.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

import '../../../pokemon/controllers/pokemon_controller.dart';
import '../../controllers/settings_controller.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';

  @override
  Widget build(BuildContext context) {
    final controller = context.get<SettingsController>();
    final pokemonController = context.get<PokemonController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        // Glue the SettingsController to the theme selection DropdownButton.
        //
        // When a user selects a theme from the dropdown list, the
        // SettingsController is updated, which rebuilds the MaterialApp.
        child: Column(
          children: [
            SignalBuilder(
              builder: (context, child) {
                final themeMode = controller.themeMode();
                return DropdownButton<ThemeMode>(
                  // Read the selected themeMode from the controller
                  value: themeMode,
                  // Call the updateThemeMode method any time the user selects a theme.
                  onChanged: controller.updateThemeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark Theme'),
                    )
                  ],
                );
              },
            ),
            ElevatedButton(
                onPressed: pokemonController.resetLocal,
                child: const Text('RESET')),
          ],
        ),
      ),
    );
  }
}
