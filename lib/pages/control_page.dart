import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/device.dart';
import '../models/led_theme.dart';
import '../services/ble_service.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  final ESP32BLEService _bleService = ESP32BLEService();

  Device? _selectedDevice;
  final List<Device> _selectedDevices = [];
  Color _selectedColor = Colors.blue;
  double _brightness = 255;
  double _saturation = 100;
  LedAnimationType _selectedAnimation = LedAnimationType.solid;
  double _speed = 50;
  double _delay = 50;
  bool _reverse = false;

  @override
  void initState() {
    super.initState();
    _loadConnectedDevices();
  }

  void _loadConnectedDevices() {
    // Convert BluetoothDevice to Device for consistency
    final connectedBtDevices = _bleService.connectedDevices;
    final devices = connectedBtDevices
        .map(
          (btDevice) => Device(
            id: btDevice.remoteId.str,
            name: btDevice.localName.isNotEmpty
                ? btDevice.localName
                : 'Unknown Device',
            address: btDevice.remoteId.str,
            lastConnected: DateTime.now(),
            isConnected: true,
          ),
        )
        .toList();

    if (devices.isNotEmpty && _selectedDevice == null) {
      setState(() {
        _selectedDevice = devices.first;
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
              _sendCurrentTheme();
            },
            pickerAreaHeightPercent: 0.8,
            displayThumbColor: true,
            showLabel: true,
            paletteType: PaletteType.hueWheel,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _sendCurrentTheme() {
    final theme = LedTheme(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Live Control',
      type: _selectedAnimation,
      color: _selectedColor,
      brightness: _brightness.round(),
      speed: _speed.round(),
      saturation: _saturation.round(),
      delay: _delay.round(),
      reverse: _reverse,
      created: DateTime.now(),
      modified: DateTime.now(),
    );

    if (_selectedDevices.isNotEmpty) {
      // Send to multiple selected devices
      for (final device in _selectedDevices) {
        _bleService.sendThemeToDevice(device.id, theme);
      }
    } else if (_selectedDevice != null) {
      // Send to single selected device
      _bleService.sendThemeToDevice(_selectedDevice!.id, theme);
    } else {
      // Send to all connected devices
      _bleService.sendThemeToAllDevices(theme);
    }
  }

  Widget _buildDeviceSelector() {
    final connectedDevices = _bleService.connectedDevices;

    if (connectedDevices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              const Text(
                'No devices connected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Go to Devices tab to connect',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Devices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Send to all devices option
            CheckboxListTile(
              title: const Text('All Connected Devices'),
              subtitle: Text('${connectedDevices.length} devices'),
              value: _selectedDevices.isEmpty && _selectedDevice == null,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedDevices.clear();
                    _selectedDevice = null;
                  }
                });
              },
            ),

            const Divider(),

            // Individual device selection
            ...connectedDevices.map((btDevice) {
              final device = Device(
                id: btDevice.remoteId.str,
                name: btDevice.localName.isNotEmpty
                    ? btDevice.localName
                    : 'Unknown Device',
                address: btDevice.remoteId.str,
                lastConnected: DateTime.now(),
                isConnected: true,
              );

              final isSelected =
                  _selectedDevices.any((d) => d.id == device.id) ||
                  _selectedDevice?.id == device.id;

              return CheckboxListTile(
                title: Text(device.name),
                subtitle: Text(device.address),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedDevice = null;
                      if (!_selectedDevices.any((d) => d.id == device.id)) {
                        _selectedDevices.add(device);
                      }
                    } else {
                      _selectedDevices.removeWhere((d) => d.id == device.id);
                      if (_selectedDevices.isEmpty) {
                        _selectedDevice = device;
                      }
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildColorControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Color Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Color picker button
            InkWell(
              onTap: _showColorPicker,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Text(
                    'Tap to change color',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSliders() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brightness & Effects',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Brightness slider
            _buildSlider(
              label: 'Brightness',
              value: _brightness,
              min: 0,
              max: 255,
              divisions: 255,
              onChanged: (value) {
                setState(() => _brightness = value);
                _sendCurrentTheme();
              },
              valueLabel: '${(_brightness / 255 * 100).round()}%',
              icon: Icons.brightness_6,
            ),

            const SizedBox(height: 16),

            // Saturation slider
            _buildSlider(
              label: 'Saturation',
              value: _saturation,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() => _saturation = value);
                _sendCurrentTheme();
              },
              valueLabel: '${_saturation.round()}%',
              icon: Icons.opacity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Animation Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Animation type selector
            DropdownButtonFormField<LedAnimationType>(
              value: _selectedAnimation,
              decoration: const InputDecoration(
                labelText: 'Animation Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.animation),
              ),
              items: LedAnimationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAnimation = value!;
                });
                _sendCurrentTheme();
              },
            ),

            const SizedBox(height: 16),

            // Speed slider (only for animated types)
            if (_selectedAnimation != LedAnimationType.solid) ...[
              _buildSlider(
                label: 'Speed',
                value: _speed,
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (value) {
                  setState(() => _speed = value);
                  _sendCurrentTheme();
                },
                valueLabel: '${_speed.round()}%',
                icon: Icons.speed,
              ),

              const SizedBox(height: 16),

              // Delay slider
              _buildSlider(
                label: 'Delay',
                value: _delay,
                min: 10,
                max: 1000,
                divisions: 99,
                onChanged: (value) {
                  setState(() => _delay = value);
                  _sendCurrentTheme();
                },
                valueLabel: '${_delay.round()}ms',
                icon: Icons.timer,
              ),

              const SizedBox(height: 16),

              // Reverse switch
              SwitchListTile(
                title: const Text('Reverse Direction'),
                value: _reverse,
                onChanged: (value) {
                  setState(() => _reverse = value);
                  _sendCurrentTheme();
                },
                secondary: const Icon(Icons.swap_horiz),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueLabel,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDeviceSelector(),
            const SizedBox(height: 16),
            _buildColorControl(),
            const SizedBox(height: 16),
            _buildControlSliders(),
            const SizedBox(height: 16),
            _buildAnimationControl(),
          ],
        ),
      ),
    );
  }
}
