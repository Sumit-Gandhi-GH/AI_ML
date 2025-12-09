import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Settings
            _SectionHeader(title: 'APPEARANCE'),
            Card(
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System Default'),
                    secondary: const Icon(Icons.brightness_auto),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light Mode'),
                    secondary: const Icon(Icons.light_mode),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark Mode'),
                    secondary: const Icon(Icons.dark_mode),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _SectionHeader(title: 'ACCOUNT'),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(authProvider.currentUser?.displayName?[0] ?? 'U'),
                ),
                title: Text(authProvider.currentUser?.displayName ?? 'User'),
                subtitle: Text(authProvider.currentUser?.email ?? ''),
                trailing: OutlinedButton(
                  onPressed: () => authProvider.signOut(),
                  child: const Text('Sign Out'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Event Specific Settings (Only if event selected)
            Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                final event = eventProvider.selectedEvent;
                if (event == null) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                        title: 'CURRENT EVENT: ${event.name.toUpperCase()}'),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Kiosk Mode'),
                            subtitle:
                                const Text('Enable self-service check-in'),
                            value: event.settings.enableKioskMode,
                            secondary: const Icon(Icons.tablet_mac),
                            onChanged: (val) {
                              // TODO: Update event settings
                            },
                          ),
                          const Divider(),
                          SwitchListTile(
                            title: const Text('Auto-print Badges'),
                            value: event.settings.autoPrintOnCheckin,
                            secondary: const Icon(Icons.print),
                            onChanged: (val) {
                              // TODO: Update
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.delete_forever,
                                color: Colors.red),
                            title: const Text('Reset Event Data',
                                style: TextStyle(color: Colors.red)),
                            onTap: () {
                              // TODO: Reset
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Badge Boss v1.0.0',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
