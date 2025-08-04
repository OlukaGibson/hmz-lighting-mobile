import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/led_theme.dart';
import '../models/device.dart';

class ESP32BLEService {
  // Service and characteristic UUIDs
  static const String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String deviceInfoRxUUID = "87654321-4321-4321-4321-cba987654321";
  static const String deviceInfoTxUUID = "11111111-2222-3333-4444-555555555555";
  static const String themeRxUUID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";

  // Private fields
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, Map<String, BluetoothCharacteristic>>
  _deviceCharacteristics = {};
  bool _isScanning = false;

  // Stream controllers
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _dataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<BluetoothDevice>> _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<Device> _deviceConnectedController =
      StreamController<Device>.broadcast();
  final StreamController<Device> _deviceDisconnectedController =
      StreamController<Device>.broadcast();

  // Getters
  bool get isConnected => _connectedDevices.isNotEmpty;
  bool get isScanning => _isScanning;
  int get connectedDeviceCount => _connectedDevices.length;
  List<BluetoothDevice> get connectedDevices =>
      _connectedDevices.values.toList();

  // Streams
  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<Device> get deviceConnectedStream => _deviceConnectedController.stream;
  Stream<Device> get deviceDisconnectedStream =>
      _deviceDisconnectedController.stream;

  // Start scanning for devices - renamed to match devices_page.dart usage
  Future<void> startScan() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      _statusController.add("Scanning for devices...");

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      FlutterBluePlus.scanResults.listen((results) {
        final devices = results.map((r) => r.device).toList();
        _devicesController.add(devices);
      });

      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      _statusController.add("Scan completed");
    } catch (e) {
      _isScanning = false;
      _statusController.add("Scan failed: $e");
    }
  }

  // Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  // Check if device is connected
  bool isDeviceConnected(String deviceId) {
    return _connectedDevices.containsKey(deviceId);
  }

  // Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_connectedDevices.containsKey(device.remoteId.str)) {
      return true;
    }

    if (_connectedDevices.length >= 4) {
      _statusController.add(
        "Maximum of 4 devices can be connected simultaneously",
      );
      return false;
    }

    try {
      _statusController.add("Connecting to ${device.localName}...");

      await device.connect(timeout: const Duration(seconds: 10));

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDeviceDisconnected(device);
        }
      });

      final services = await device.discoverServices();
      final targetService = services.firstWhere(
        (service) =>
            service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase(),
        orElse: () => throw Exception("LED control service not found"),
      );

      final characteristics = <String, BluetoothCharacteristic>{};
      for (final characteristic in targetService.characteristics) {
        final uuidStr = characteristic.uuid.toString().toLowerCase();
        if (uuidStr == deviceInfoRxUUID.toLowerCase()) {
          characteristics['deviceInfoRx'] = characteristic;
        } else if (uuidStr == deviceInfoTxUUID.toLowerCase()) {
          characteristics['deviceInfoTx'] = characteristic;
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((value) {
            _handleDeviceData(device.remoteId.str, value);
          });
        } else if (uuidStr == themeRxUUID.toLowerCase()) {
          characteristics['themeRx'] = characteristic;
        }
      }

      if (characteristics.isEmpty) {
        throw Exception("Required characteristics not found");
      }

      _connectedDevices[device.remoteId.str] = device;
      _deviceCharacteristics[device.remoteId.str] = characteristics;

      await _requestDeviceInfo(device.remoteId.str);

      _statusController.add("Connected to ${device.localName}");

      final deviceObj = Device(
        id: device.remoteId.str,
        name: device.localName.isNotEmpty ? device.localName : "Unknown Device",
        address: device.remoteId.str,
        lastConnected: DateTime.now(),
        isConnected: true,
      );
      _deviceConnectedController.add(deviceObj);

      return true;
    } catch (e) {
      _statusController.add("Connection failed: $e");
      return false;
    }
  }

  // Disconnect from a device
  Future<void> disconnectDevice(String deviceId) async {
    final device = _connectedDevices[deviceId];
    if (device == null) return;

    try {
      await device.disconnect();
      _handleDeviceDisconnected(device);
    } catch (e) {
      _statusController.add("Disconnect error: $e");
    }
  }

  // Disconnect all devices
  Future<void> disconnectAll() async {
    final devices = List.from(_connectedDevices.values);
    for (final device in devices) {
      await disconnectDevice(device.remoteId.str);
    }
  }

  // Handle device disconnection
  void _handleDeviceDisconnected(BluetoothDevice device) {
    final deviceId = device.remoteId.str;
    _connectedDevices.remove(deviceId);
    _deviceCharacteristics.remove(deviceId);

    final deviceObj = Device(
      id: deviceId,
      name: device.localName.isNotEmpty ? device.localName : "Unknown Device",
      address: deviceId,
      lastConnected: DateTime.now(),
      isConnected: false,
    );
    _deviceDisconnectedController.add(deviceObj);

    _statusController.add("Disconnected from ${device.localName}");
  }

  // Send theme to device(s)
  Future<bool> sendThemeToDevice(String deviceId, LedTheme theme) async {
    return await _sendDataToDevice(deviceId, 'themeRx', theme.toBleCommand());
  }

  Future<bool> sendThemeToAllDevices(LedTheme theme) async {
    bool allSuccessful = true;
    for (final deviceId in _connectedDevices.keys) {
      final success = await sendThemeToDevice(deviceId, theme);
      if (!success) allSuccessful = false;
    }
    return allSuccessful;
  }

  // Send device info to device
  Future<bool> sendDeviceInfo(
    String deviceId,
    List<Device> knownDevices,
  ) async {
    final deviceInfo = {
      'command': 'device_info',
      'devices': knownDevices.map((d) => d.toJson()).toList(),
    };
    return await _sendDataToDevice(deviceId, 'deviceInfoRx', deviceInfo);
  }

  // Request device info from device
  Future<bool> _requestDeviceInfo(String deviceId) async {
    final request = {'command': 'get_device_info'};
    return await _sendDataToDevice(deviceId, 'deviceInfoRx', request);
  }

  // Generic method to send data to device
  Future<bool> _sendDataToDevice(
    String deviceId,
    String characteristicKey,
    Map<String, dynamic> data,
  ) async {
    final characteristics = _deviceCharacteristics[deviceId];
    if (characteristics == null) {
      _statusController.add("Device not connected: $deviceId");
      return false;
    }

    final characteristic = characteristics[characteristicKey];
    if (characteristic == null) {
      _statusController.add("Characteristic not found: $characteristicKey");
      return false;
    }

    try {
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);

      if (bytes.length > 512) {
        // MTU limit consideration
        _statusController.add("Data too large to send");
        return false;
      }

      await characteristic.write(bytes);
      return true;
    } catch (e) {
      _statusController.add("Send error: $e");
      return false;
    }
  }

  // Handle incoming data from device
  void _handleDeviceData(String deviceId, List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      final Map<String, dynamic> parsedData = jsonDecode(jsonString);

      // Add device ID to the data
      parsedData['deviceId'] = deviceId;

      _dataController.add(parsedData);
    } catch (e) {
      print("Error parsing device data: $e");
    }
  }

  // Legacy methods for compatibility with main.dart
  Future<bool> controlLED(bool state) async {
    final command = {'command': 'led_control', 'state': state ? 'ON' : 'OFF'};
    bool allSuccessful = true;
    for (final deviceId in _connectedDevices.keys) {
      final success = await _sendDataToDevice(deviceId, 'themeRx', command);
      if (!success) allSuccessful = false;
    }
    return allSuccessful;
  }

  Future<bool> requestSensorData() async {
    final command = {'command': 'get_sensors'};
    bool allSuccessful = true;
    for (final deviceId in _connectedDevices.keys) {
      final success = await _sendDataToDevice(
        deviceId,
        'deviceInfoRx',
        command,
      );
      if (!success) allSuccessful = false;
    }
    return allSuccessful;
  }

  Future<bool> requestStatus() async {
    final command = {'command': 'get_status'};
    bool allSuccessful = true;
    for (final deviceId in _connectedDevices.keys) {
      final success = await _sendDataToDevice(
        deviceId,
        'deviceInfoRx',
        command,
      );
      if (!success) allSuccessful = false;
    }
    return allSuccessful;
  }

  Future<bool> sendCommand(
    String commandName, {
    Map<String, dynamic>? parameters,
  }) async {
    final command = {'command': commandName, ...?parameters};
    bool allSuccessful = true;
    for (final deviceId in _connectedDevices.keys) {
      final success = await _sendDataToDevice(
        deviceId,
        'deviceInfoRx',
        command,
      );
      if (!success) allSuccessful = false;
    }
    return allSuccessful;
  }

  Future<void> disconnect() async {
    await disconnectAll();
  }

  // Dispose of all resources
  void dispose() {
    disconnectAll();
    _statusController.close();
    _dataController.close();
    _devicesController.close();
    _deviceConnectedController.close();
    _deviceDisconnectedController.close();
  }
}
