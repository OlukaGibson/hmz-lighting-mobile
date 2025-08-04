import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/device.dart';
import 'models/led_theme.dart';

class ESP32BLEService {
  // ESP32 BLE Service and Characteristic UUIDs
  static const String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String deviceInfoRxUUID = "87654321-4321-4321-4321-cba987654321";
  static const String deviceInfoTxUUID = "87654321-4321-4321-4321-cba987654322";
  static const String themeRxUUID = "87654321-4321-4321-4321-cba987654323";

  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, Map<String, BluetoothCharacteristic>>
  _deviceCharacteristics = {};
  bool _isScanning = false;

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

  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<Device> get deviceConnectedStream => _deviceConnectedController.stream;
  Stream<Device> get deviceDisconnectedStream =>
      _deviceDisconnectedController.stream;

  bool get isScanning => _isScanning;
  bool get isConnected => _connectedDevices.isNotEmpty;
  List<BluetoothDevice> get connectedDevices =>
      _connectedDevices.values.toList();
  int get connectedDeviceCount => _connectedDevices.length;

  // Check if specific device is connected
  bool isDeviceConnected(String deviceId) {
    return _connectedDevices.containsKey(deviceId);
  }

  // Check if Bluetooth is supported and enabled
  Future<bool> checkBluetoothSupport() async {
    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        _statusController.add("Bluetooth not supported on this device");
        return false;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _statusController.add("Bluetooth is turned off");
        return false;
      }

      return true;
    } catch (e) {
      _statusController.add("Error checking Bluetooth: $e");
      return false;
    }
  }

  // Request necessary permissions
  Future<bool> requestPermissions() async {
    try {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();

      bool allGranted = statuses.values.every(
        (status) =>
            status == PermissionStatus.granted ||
            status == PermissionStatus.limited,
      );

      if (!allGranted) {
        _statusController.add("Some permissions were denied");
        return false;
      }

      return true;
    } catch (e) {
      _statusController.add("Error requesting permissions: $e");
      return false;
    }
  }

  // Start scanning for devices
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (_isScanning) {
        await stopScan();
      }

      if (!await checkBluetoothSupport()) return;
      if (!await requestPermissions()) return;

      _isScanning = true;
      _statusController.add("Scanning for ESP32 devices...");

      List<BluetoothDevice> devices = [];

      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        devices = results
            .where((result) => result.device.localName.isNotEmpty)
            .map((result) => result.device)
            .toList();
        _devicesController.add(devices);
      });

      // Start scanning
      await FlutterBluePlus.startScan(timeout: timeout);

      // Wait for scan to complete
      await Future.delayed(timeout);
      await stopScan();

      subscription.cancel();

      if (devices.isEmpty) {
        _statusController.add("No BLE devices found");
      } else {
        _statusController.add("Found ${devices.length} device(s)");
      }
    } catch (e) {
      _statusController.add("Scanning error: $e");
      _isScanning = false;
    }
  }

  // Stop scanning
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
    } catch (e) {
      _statusController.add("Error stopping scan: $e");
    }
  }

  // Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;

    if (_connectedDevices.containsKey(deviceId)) {
      _statusController.add("Device already connected");
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

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));

      // Listen to connection state changes
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDeviceDisconnected(device);
        }
      });

      // Discover services
      final services = await device.discoverServices();
      final targetService = services.firstWhere(
        (service) =>
            service.uuid.toString().toLowerCase() == serviceUUID.toLowerCase(),
        orElse: () => throw Exception("LED control service not found"),
      );

      // Get characteristics
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

      // Store device and characteristics
      _connectedDevices[device.remoteId.str] = device;
      _deviceCharacteristics[device.remoteId.str] = characteristics;

      // Request device info
      await _requestDeviceInfo(device.remoteId.str);

      _statusController.add("Connected to ${device.localName}");

      // Create Device object and notify listeners
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
