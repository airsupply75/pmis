import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  bool _notificationsEnabled = true; // Example setting

  @override
  bool get wantKeepAlive => true; // Essential for IndexedStack to keep state

  @override
  Widget build(BuildContext context) {
    super.build(
      context,
    ); // Call super.build(context) for AutomaticKeepAliveClientMixin
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text('App Settings', style: Theme.of(context).textTheme.headlineSmall),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          value: _notificationsEnabled,
          onChanged: (bool value) {
            setState(() {
              _notificationsEnabled = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notifications set to $value')),
            );
          },
        ),
        ListTile(
          title: const Text('Change Password'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navigate to a dedicated Change Password page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navigate to Change Password')),
            );
          },
        ),
        ListTile(
          title: const Text('About App'),
          trailing: const Icon(Icons.info_outline),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'My Awesome App',
              applicationVersion: '1.0.0',
            );
          },
        ),
        // More settings options
      ],
    );
  }
}
