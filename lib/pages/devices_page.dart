import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../widgets/device_list_item.dart';

class DevicesPage extends StatefulWidget {
  final ESP32BLEService? bleService;

  const DevicesPage({super.key, this.bleService});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  late final ESP32BLEService _bleService;
  final StorageService _storageService = StorageService.instance;

  List<Device> _savedDevices = [];
  List<BluetoothDevice> _availableDevices = [];
  bool _isScanning = false;
  String _statusMessage = 'Ready';

  @override
  void initState() {
    super.initState();
    _bleService = widget.bleService ?? ESP32BLEService();
    _initializeServices();
    _setupListeners();
    _loadSavedDevices();
  }

  @override
  void dispose() {
    // Only dispose if we created our own instance
    if (widget.bleService == null) {
      _bleService.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _storageService.initialize();
  }

  void _setupListeners() {
    // Listen to BLE status updates
    _bleService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
      }
    });

    // Listen to device discoveries
    _bleService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _availableDevices = devices;
        });
      }
    });

    // Listen to device connections
    _bleService.deviceConnectedStream.listen((device) {
      if (mounted) {
        _onDeviceConnected(device);
      }
    });

    // Listen to device disconnections
    _bleService.deviceDisconnectedStream.listen((device) {
      if (mounted) {
        _onDeviceDisconnected(device);
      }
    });
  }

  Future<void> _loadSavedDevices() async {
    final devices = await _storageService.getSavedDevices();
    setState(() {
      _savedDevices = devices;
    });

    // Try to auto-reconnect to previously connected devices
    _autoReconnectDevices();
  }

  Future<void> _autoReconnectDevices() async {
    // Auto-reconnect is handled by the BLE service initialize method
    // This method can be used for additional UI-specific auto-reconnect logic if needed
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _availableDevices.clear();
    });

    await _bleService.startScan();

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _stopScan() async {
    await _bleService.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice bluetoothDevice) async {
    final success = await _bleService.connectToDevice(bluetoothDevice);
    if (success) {
      final device = Device(
        id: bluetoothDevice.remoteId.str,
        name: bluetoothDevice.localName.isNotEmpty
            ? bluetoothDevice.localName
            : "Unknown Device",
        address: bluetoothDevice.remoteId.str,
        lastConnected: DateTime.now(),
        isConnected: true,
      );

      await _storageService.addDevice(device);
      await _loadSavedDevices();
    }
  }

  Future<void> _disconnectDevice(Device device) async {
    await _bleService.disconnectDevice(device.id);
    final updatedDevice = device.copyWith(isConnected: false);
    await _storageService.updateDevice(updatedDevice);
    await _loadSavedDevices();
  }

  Future<void> _removeDevice(Device device) async {
    await _bleService.disconnectDevice(device.id);
    await _storageService.removeDevice(device.id);
    await _loadSavedDevices();
    
    setState(() {
      _statusMessage = 'Device ${device.name} removed from saved devices';
    });
  }

  void _onDeviceConnected(Device device) async {
    final updatedDevice = device.copyWith(
      isConnected: true,
      lastConnected: DateTime.now(),
    );
    await _storageService.updateDevice(updatedDevice);
    await _loadSavedDevices();
  }

  void _onDeviceDisconnected(Device device) async {
    final updatedDevice = device.copyWith(isConnected: false);
    await _storageService.updateDevice(updatedDevice);
    await _loadSavedDevices();
  }

  List<BluetoothDevice> get _filteredAvailableDevices {
    return _availableDevices.where((bluetoothDevice) {
      return !_savedDevices.any(
        (savedDevice) => savedDevice.id == bluetoothDevice.remoteId.str,
      );
    }).toList();
  }

  Future<void> _reconnectSavedDevice(Device device) async {
    // Find the BluetoothDevice in available or connected devices
    BluetoothDevice? bluetoothDevice = _availableDevices.firstWhere(
      (btDevice) => btDevice.remoteId.str == device.id,
      orElse: () => _bleService.connectedDevices.firstWhere(
        (btDevice) => btDevice.remoteId.str == device.id,
        orElse: () => throw Exception('Device not found'),
      ),
    );

    if (bluetoothDevice != null) {
      await _connectToDevice(bluetoothDevice);
    } else {
      // Device not found in scan results
      setState(() {
        _statusMessage =
            'Device ${device.name} not found. Make sure it\'s nearby and try scanning.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.search),
            onPressed: _isScanning ? _stopScan : _startScan,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(
                  _bleService.connectedDeviceCount > 0
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: _bleService.connectedDeviceCount > 0
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_isScanning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              children: [
                // My Devices section
                if (_savedDevices.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite),
                        const SizedBox(width: 8),
                        Text(
                          'My Devices',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  ..._savedDevices.map(
                    (device) => ListTile(
                      leading: Icon(
                        _bleService.isDeviceConnected(device.id) 
                          ? Icons.bluetooth_connected 
                          : Icons.bluetooth,
                        color: _bleService.isDeviceConnected(device.id) 
                          ? Colors.green 
                          : Colors.grey,
                      ),
                      title: Text(device.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.address),
                          Text(
                            'Last connected: ${_formatDateTime(device.lastConnected)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_bleService.isDeviceConnected(device.id))
                            ElevatedButton(
                              onPressed: () => _disconnectDevice(device),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Disconnect'),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _reconnectSavedDevice(device),
                              child: const Text('Connect'),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showForgetDeviceDialog(device),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Forget'),
                          ),
                        ],
                      ),
                      onTap: () => _navigateToControl(device),
                    ),
                  ),
                  const Divider(),
                ],

                // Available Devices section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.devices),
                      const SizedBox(width: 8),
                      Text(
                        'Available Devices',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),

                if (_filteredAvailableDevices.isEmpty && !_isScanning)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No devices found. Tap the search icon to scan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._filteredAvailableDevices.map(
                    (bluetoothDevice) => ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(
                        bluetoothDevice.localName.isNotEmpty
                            ? bluetoothDevice.localName
                            : "Unknown Device",
                      ),
                      subtitle: Text(bluetoothDevice.remoteId.str),
                      trailing: ElevatedButton(
                        onPressed: () => _connectToDevice(bluetoothDevice),
                        child: const Text('Connect'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToControl(Device device) {
    // Navigate to control page with selected device
    // This will be implemented when we create the control page
    Navigator.pushNamed(context, '/control', arguments: device);
  }

  void _showForgetDeviceDialog(Device device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Forget Device'),
          content: Text(
            'Are you sure you want to forget "${device.name}"? This will remove all saved data for this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeDevice(device);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Forget'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
