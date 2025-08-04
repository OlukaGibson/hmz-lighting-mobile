import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final StorageService _storageService = StorageService.instance;

  bool _autoConnect = false;
  bool _showNotifications = true;
  bool _darkMode = false;
  double _connectionTimeout = 10.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoConnect =
        await _storageService.getSetting<bool>('auto_connect') ?? false;
    final showNotifications =
        await _storageService.getSetting<bool>('show_notifications') ?? true;
    final darkMode =
        await _storageService.getSetting<bool>('dark_mode') ?? false;
    final connectionTimeout =
        await _storageService.getSetting<double>('connection_timeout') ?? 10.0;

    setState(() {
      _autoConnect = autoConnect;
      _showNotifications = showNotifications;
      _darkMode = darkMode;
      _connectionTimeout = connectionTimeout;
    });
  }

  Future<void> _updateSetting<T>(String key, T value) async {
    await _storageService.setSetting(key, value);
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will remove all saved devices, themes, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearAllData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All data cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connection Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Auto Connect'),
                    subtitle: const Text(
                      'Automatically connect to known devices',
                    ),
                    value: _autoConnect,
                    onChanged: (value) {
                      setState(() => _autoConnect = value);
                      _updateSetting('auto_connect', value);
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Connection Timeout: ${_connectionTimeout.round()} seconds',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    value: _connectionTimeout,
                    min: 5.0,
                    max: 30.0,
                    divisions: 25,
                    onChanged: (value) {
                      setState(() => _connectionTimeout = value);
                      _updateSetting('connection_timeout', value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notification Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Show Notifications'),
                    subtitle: const Text(
                      'Display connection status notifications',
                    ),
                    value: _showNotifications,
                    onChanged: (value) {
                      setState(() => _showNotifications = value);
                      _updateSetting('show_notifications', value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      _updateSetting('dark_mode', value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Data Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text('Clear All Data'),
                    subtitle: const Text('Remove all saved devices and themes'),
                    onTap: _clearAllData,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // About
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  const ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                  ),

                  const ListTile(
                    leading: Icon(Icons.business),
                    title: Text('Developer'),
                    subtitle: Text('Zooft Technologies'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
