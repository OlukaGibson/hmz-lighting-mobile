import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'splash_screen.dart';
import 'widgets/main_navigation.dart';
import 'services/storage_service.dart';
import 'services/ble_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HMZ Lighting',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(nextScreen: MainNavigation()),
    );
  }
}

class ESP32BLEHomePage extends StatefulWidget {
  const ESP32BLEHomePage({super.key, required this.title});

  final String title;

  @override
  State<ESP32BLEHomePage> createState() => _ESP32BLEHomePageState();
}

class _ESP32BLEHomePageState extends State<ESP32BLEHomePage> {
  final ESP32BLEService _bleService = ESP32BLEService();

  List<BluetoothDevice> _discoveredDevices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  bool _ledState = false;
  String _statusMessage = 'Ready to scan';
  String _sensorData = 'No data';
  String _deviceInfo = 'No device selected';

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to status updates
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
          _discoveredDevices = devices;
        });
      }
    });

    // Listen to data from ESP32
    _bleService.dataStream.listen((data) {
      if (mounted) {
        setState(() {
          if (data.containsKey('sensors')) {
            _sensorData = data['sensors'].toString();
          } else if (data.containsKey('status')) {
            _deviceInfo = data['status'].toString();
          } else if (data.containsKey('ledState')) {
            _ledState = data['ledState'] == 'ON';
          }
        });
      }
    });

    // Update connection status
    _updateConnectionStatus();
  }

  void _updateConnectionStatus() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _isConnected = _bleService.isConnected;
          _isScanning = _bleService.isScanning;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _startScanning() async {
    setState(() {
      _discoveredDevices.clear();
    });
    await _bleService.startScan();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final success = await _bleService.connectToDevice(device);
    if (success && mounted) {
      setState(() {
        _deviceInfo = 'Connected to ${device.platformName}';
      });
    }
  }

  Future<void> _disconnect() async {
    await _bleService.disconnect();
    if (mounted) {
      setState(() {
        _deviceInfo = 'Disconnected';
        _sensorData = 'No data';
      });
    }
  }

  Future<void> _toggleLED() async {
    final success = await _bleService.controlLED(!_ledState);
    if (success) {
      setState(() {
        _ledState = !_ledState;
      });
    }
  }

  Future<void> _requestSensorData() async {
    await _bleService.requestSensorData();
  }

  Future<void> _requestStatus() async {
    await _bleService.requestStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Connection Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: _isConnected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BLE Connection',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 8),
                    Text(
                      _deviceInfo,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isScanning ? null : _startScanning,
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(
                            _isScanning ? 'Scanning...' : 'Scan for Devices',
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_isConnected)
                          ElevatedButton.icon(
                            onPressed: _disconnect,
                            icon: const Icon(Icons.bluetooth_disabled),
                            label: const Text('Disconnect'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Device List Card
            if (_discoveredDevices.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discovered Devices',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ..._discoveredDevices.map(
                        (device) => ListTile(
                          title: Text(
                            device.platformName.isNotEmpty
                                ? device.platformName
                                : 'Unknown Device',
                          ),
                          subtitle: Text(device.remoteId.toString()),
                          trailing: ElevatedButton(
                            onPressed: _isConnected
                                ? null
                                : () => _connectToDevice(device),
                            child: const Text('Connect'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // LED Control Card
            if (_isConnected)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: _ledState ? Colors.yellow : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LED Control',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _toggleLED,
                          icon: Icon(
                            _ledState
                                ? Icons.lightbulb
                                : Icons.lightbulb_outline,
                          ),
                          label: Text(
                            _ledState ? 'Turn LED OFF' : 'Turn LED ON',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ledState ? Colors.orange : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Sensor Data Card
            if (_isConnected)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sensors),
                          const SizedBox(width: 8),
                          Text(
                            'Sensor Data',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _sensorData,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _requestSensorData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Get Sensor Data'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Control Buttons Card
            if (_isConnected)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESP32 Controls',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _requestStatus,
                            icon: const Icon(Icons.info),
                            label: const Text('Get Status'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _bleService.sendCommand('restart'),
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Restart ESP32'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _bleService.sendCommand(
                              'blink',
                              parameters: {'times': 5},
                            ),
                            icon: const Icon(Icons.flash_on),
                            label: const Text('Blink LED'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}
