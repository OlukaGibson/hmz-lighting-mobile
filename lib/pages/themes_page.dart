import 'package:flutter/material.dart';
import '../models/led_theme.dart';
import '../services/storage_service.dart';
import '../services/ble_service.dart';
import '../widgets/theme_list_item.dart';
import '../widgets/theme_create_dialog.dart';

class ThemesPage extends StatefulWidget {
  const ThemesPage({super.key});

  @override
  State<ThemesPage> createState() => _ThemesPageState();
}

class _ThemesPageState extends State<ThemesPage> {
  final StorageService _storageService = StorageService.instance;
  final ESP32BLEService _bleService = ESP32BLEService();

  List<LedTheme> _savedThemes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedThemes();
  }

  Future<void> _loadSavedThemes() async {
    setState(() {
      _isLoading = true;
    });

    final themes = await _storageService.getSavedThemes();
    setState(() {
      _savedThemes = themes;
      _isLoading = false;
    });
  }

  Future<void> _createNewTheme() async {
    final newTheme = await showDialog<LedTheme>(
      context: context,
      builder: (context) => const ThemeCreateDialog(),
    );

    if (newTheme != null) {
      await _storageService.addTheme(newTheme);
      await _loadSavedThemes();
    }
  }

  Future<void> _editTheme(LedTheme theme) async {
    final editedTheme = await showDialog<LedTheme>(
      context: context,
      builder: (context) => ThemeCreateDialog(theme: theme),
    );

    if (editedTheme != null) {
      await _storageService.updateTheme(editedTheme);
      await _loadSavedThemes();
    }
  }

  Future<void> _deleteTheme(LedTheme theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Theme'),
        content: Text('Are you sure you want to delete "${theme.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.removeTheme(theme.id);
      await _loadSavedThemes();
    }
  }

  Future<void> _sendThemeToDevice(LedTheme theme, String? deviceId) async {
    if (deviceId != null) {
      await _bleService.sendThemeToDevice(deviceId, theme);
    } else {
      await _bleService.sendThemeToAllDevices(theme);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deviceId != null
              ? 'Theme sent to device'
              : 'Theme sent to all connected devices',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSendToDeviceDialog(LedTheme theme) {
    final connectedDevices = _bleService.connectedDevices;

    if (connectedDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No devices connected'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send "${theme.name}" to:'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('All Connected Devices'),
              onTap: () {
                Navigator.of(context).pop();
                _sendThemeToDevice(theme, null);
              },
            ),
            const Divider(),
            ...connectedDevices.map(
              (device) => ListTile(
                leading: const Icon(Icons.lightbulb),
                title: Text(
                  device.localName.isNotEmpty
                      ? device.localName
                      : 'Unknown Device',
                ),
                subtitle: Text(device.remoteId.str),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendThemeToDevice(theme, device.remoteId.str);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createNewTheme),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedThemes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.palette, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No themes created yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first theme',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createNewTheme,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Theme'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _savedThemes.length,
              itemBuilder: (context, index) {
                final theme = _savedThemes[index];
                return ThemeListItem(
                  theme: theme,
                  onTap: () => _showSendToDeviceDialog(theme),
                  onEdit: () => _editTheme(theme),
                  onDelete: () => _deleteTheme(theme),
                );
              },
            ),
    );
  }
}
