# ESP32-S3 BLE Flutter Communication App

This Flutter app demonstrates Bluetooth Low Energy (BLE) communication between a Flutter mobile app and an ESP32-S3 microcontroller. The app provides a user-friendly interface to scan for BLE devices, connect to your ESP32, control LEDs, read sensor data, and send custom commands.

## 🚀 Features

- 📱 **BLE Device Scanning**: Discover nearby ESP32 BLE devices
- 🔗 **Device Connection**: Connect/disconnect from ESP32 with connection status
- 💡 **LED Control**: Turn ESP32 LED on/off remotely via BLE
- 📊 **Real-time Sensor Data**: Read temperature, humidity, light sensors
- ⚙️ **Device Control**: Send custom commands, get system status
- 🔔 **Live Notifications**: Receive real-time data from ESP32
- 🛡️ **Permission Management**: Automatic Bluetooth and location permissions

## 📋 Prerequisites

### Flutter Development Environment
- Flutter SDK 3.8+ 
- Dart SDK 3.8+
- Android Studio or VS Code with Flutter extensions
- Android device with Bluetooth (BLE not supported in iOS simulator)

### ESP32-S3 Setup
- ESP32-S3 development board
- Arduino IDE with ESP32 board support
- ArduinoJson library

## 🔧 Installation & Setup

### 1. Flutter App Setup

1. **Clone/Download the project**
   ```bash
   cd path/to/your/project
   flutter pub get
   ```

2. **Verify dependencies in pubspec.yaml**
   ```yaml
   dependencies:
     flutter_blue_plus: ^1.32.12
     permission_handler: ^11.3.1
   ```

3. **Android Permissions** (Already configured)
   The `android/app/src/main/AndroidManifest.xml` includes:
   - Bluetooth permissions
   - Location permissions (required for BLE scanning)
   - BLE feature requirements

4. **Run the app**
   ```bash
   flutter run
   ```

### 2. ESP32-S3 BLE Server Setup

1. **Install Required Libraries in Arduino IDE**
   - Go to **Tools > Manage Libraries**
   - Search and install: **ArduinoJson** by Benoit Blanchon

2. **ESP32 Board Setup**
   - Install ESP32 board package in Arduino IDE
   - Select **Tools > Board > ESP32 Arduino > ESP32S3 Dev Module**
   - Configure board settings:
     - Upload Speed: 921600
     - CPU Frequency: 240MHz (WiFi/BT)
     - Flash Mode: QIO
     - Flash Size: 4MB
     - Partition Scheme: Default 4MB

3. **Hardware Connections**
   ```
   ESP32-S3 Pin  | Component
   ------------- | ---------
   GPIO 2        | Built-in LED (or external LED + 220Ω resistor)
   GPIO A0       | Analog sensor (optional - light sensor, potentiometer)
   GND           | Ground for external components
   3.3V          | Power for sensors (max 50mA)
   ```

4. **Upload BLE Server Code**
   - Open `esp32_ble_server.ino` in Arduino IDE
   - Verify the UUIDs match between Arduino and Flutter code:
     ```cpp
     #define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
     #define CHARACTERISTIC_UUID "87654321-4321-4321-4321-cba987654321"
     ```
   - Upload the code to your ESP32-S3
   - Open Serial Monitor (115200 baud) to see connection status

## 📱 How to Use the App

### 1. Initial Setup
1. Launch the Flutter app on your Android device
2. Grant Bluetooth and Location permissions when prompted
3. Ensure Bluetooth is enabled on your device

### 2. Connect to ESP32
1. Tap **"Scan for Devices"** to discover nearby BLE devices
2. Your ESP32 should appear as "ESP32-BLE-Device" in the device list
3. Tap **"Connect"** next to your ESP32 device
4. Wait for "Connected" status message

### 3. Control Your ESP32
Once connected, you can:

- **🔆 LED Control**: Toggle the ESP32's LED on/off
- **📊 Sensor Data**: Request real-time sensor readings
- **ℹ️ Device Status**: Get ESP32 system information (CPU, memory, etc.)
- **⚡ Custom Commands**: 
  - Restart the ESP32
  - Make LED blink multiple times
  - Send custom commands

### 4. Real-time Data
- The app automatically receives notifications from the ESP32
- Sensor data updates every 2 seconds
- Connection status is monitored continuously

## 🔌 BLE Communication Protocol

### UUIDs Used
- **Service UUID**: `12345678-1234-1234-1234-123456789abc`
- **Characteristic UUID**: `87654321-4321-4321-4321-cba987654321`

### Message Format
All communication uses JSON format:

**Commands sent from Flutter to ESP32:**
```json
{
  "command": "led",
  "state": "ON"
}
```

**Responses from ESP32 to Flutter:**
```json
{
  "sensors": {
    "temperature": 25.6,
    "humidity": 65.2,
    "light": 45.8,
    "ledState": "ON",
    "uptime": 12345
  }
}
```

### Available Commands

| Command | Parameters | Description |
|---------|------------|-------------|
| `led` | `state: "ON"/"OFF"` | Control LED |
| `sensors` | None | Request sensor data |
| `status` | None | Get device status |
| `restart` | None | Restart ESP32 |
| `blink` | `times: number` | Blink LED X times |

## 🛠️ Troubleshooting

### Flutter App Issues

1. **"Bluetooth not supported" error**
   - Ensure you're testing on a real Android device (not emulator)
   - Check that device has BLE support

2. **Permission denied errors**
   - Go to device Settings > Apps > Your App > Permissions
   - Enable Location and Nearby devices (Bluetooth) permissions
   - Restart the app

3. **No devices found during scan**
   - Ensure ESP32 is powered on and running BLE server code
   - Check that ESP32 is in advertising mode (see Serial Monitor)
   - Try moving devices closer together (within 10 meters)

4. **Connection failed**
   - Verify UUIDs match between Flutter and ESP32 code
   - Restart both ESP32 and Flutter app
   - Check ESP32 Serial Monitor for error messages

### ESP32 Issues

1. **BLE server not starting**
   - Check Serial Monitor for initialization errors
   - Verify ArduinoJson library is installed
   - Ensure sufficient power supply (use USB cable, not just pins)

2. **Device not advertising**
   - ESP32 might have crashed - check Serial Monitor
   - Try uploading code again
   - Press ESP32 reset button

3. **Commands not working**
   - Check JSON format in Serial Monitor
   - Verify characteristic UUIDs
   - Ensure BLE connection is active

### General BLE Issues

1. **Intermittent connection drops**
   - BLE has limited range (10-30 meters)
   - Reduce distance between devices
   - Check for interference from other devices

2. **Slow response times**
   - BLE has inherent latency (100-500ms typical)
   - This is normal for BLE communication
   - Consider WiFi for faster communication if needed

## 🔒 Security Considerations

- This example uses unencrypted BLE for simplicity
- For production use, consider:
  - BLE pairing and bonding
  - Encrypted characteristics
  - Authentication mechanisms
  - Input validation and sanitization

## 📈 Performance Tips

1. **Optimize BLE Communication**
   - Keep JSON messages under 500 bytes (BLE MTU limit)
   - Use short key names in JSON
   - Batch multiple sensor readings

2. **Battery Optimization**
   - Implement connection intervals appropriately
   - Use BLE notifications instead of polling
   - Consider sleep modes for ESP32

3. **User Experience**
   - Implement auto-reconnection logic
   - Show connection quality indicators
   - Provide offline mode capabilities

## 🚀 Advanced Features You Can Add

### 1. Multiple Sensor Support
Add more sensors to your ESP32:
```cpp
// In readSensors() function
float temperature = dht.readTemperature();
float humidity = dht.readHumidity();
float pressure = bmp.readPressure();
```

### 2. Data Logging
Store sensor data locally or in cloud:
```dart
// Add to Flutter app
import 'package:sqflite/sqflite.dart';
// Implement local database storage
```

### 3. Multiple Device Support
Connect to multiple ESP32 devices simultaneously:
```dart
// Modify BLE service to handle multiple connections
Map<String, ESP32BLEService> connectedDevices = {};
```

### 4. Real-time Graphing
Display sensor data in real-time charts:
```yaml
dependencies:
  fl_chart: ^0.68.0
```

## 📚 Additional Resources

- [Flutter Blue Plus Documentation](https://pub.dev/packages/flutter_blue_plus)
- [ESP32 BLE Arduino Library](https://github.com/espressif/arduino-esp32)
- [BLE Fundamentals](https://learn.adafruit.com/introduction-to-bluetooth-low-energy)
- [ESP32-S3 Datasheet](https://www.espressif.com/sites/default/files/documentation/esp32-s3_datasheet_en.pdf)

## 📄 License

This project is open source and available under the MIT License.

---

**Happy coding! 🎉**

Need help? Check the troubleshooting section or open an issue in the repository.
