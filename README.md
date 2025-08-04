# HMZ Lighting

A Flutter app for controlling ESP32-based LED lighting devices via Bluetooth Low Energy (BLE).

## Overview

HMZ Lighting lets you scan for, connect to, and control multiple ESP32 devices equipped with addressable LEDs. You can adjust colors, brightness, effects, and save your favorite themes. The app is designed for hobbyists and makers who want wireless control of their LED projects.

## Features

- **Device Discovery:** Scan for nearby ESP32 BLE devices and connect to up to 4 at once.
- **Live Control:** Change LED color, brightness, speed, and effect in real time.
- **Theme Management:** Save, load, and apply custom lighting themes.
- **Multi-Device Support:** Control multiple ESP32 devices simultaneously.
- **Status & Sensor Data:** Request device status and sensor readings (if supported).
- **Persistent Storage:** Remembers your devices and themes between app launches.

## How It Works

1. **Scan for Devices:** Tap the search icon to find ESP32 devices running the compatible BLE firmware.
2. **Connect:** Select a device to connect. The app will show connection status and allow you to control LEDs.
3. **Control LEDs:** Use sliders and color pickers to adjust lighting. Changes are sent instantly via BLE.
4. **Save Themes:** Create and save your favorite lighting setups for quick access.
5. **Manage Devices:** Disconnect, remove, or rename devices as needed.

## Requirements

- **Hardware:** ESP32 microcontroller with BLE and addressable LEDs (e.g., WS2812, SK6812).
- **Firmware:** ESP32 must run compatible BLE server code (see `/esp32_ble_server.ino` for example).
- **Android Device:** Tested on Android 10+ with BLE support.
- **Flutter SDK:** Version 3.10 or newer recommended.

## Setup

1. **Flash ESP32:** Upload the provided Arduino sketch to your ESP32.
2. **Install App:** Run `flutter pub get` and `flutter run` to build and install the app.
3. **Permissions:** Grant Bluetooth and location permissions when prompted.
4. **Connect & Control:** Start scanning and enjoy wireless LED control!

## File Structure

- `lib/` — Main Flutter app code
  - `main.dart` — App entry point
  - `services/ble_service.dart` — BLE communication logic
  - `models/` — Device and theme data models
  - `pages/` — UI screens (devices, control, themes)
  - `widgets/` — Reusable UI components
- `esp32_ble_server.ino` — Example ESP32 BLE firmware
- `README.md` — Project documentation

## Useful Links

- [Flutter Documentation](https://docs.flutter.dev/)
- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)
- [ESP32 Arduino Core](https://docs.espressif.com/projects/arduino-esp32/en/latest/)

## License

MIT License

---

**Made by makers,
For questions or support, open an issue or contact the [Gibson Oluka](http://github.com/OlukaGibson)
To reach me on other socials
[x.com](https://x.com/OlsGibson)
[youtube](https://www.youtube.com/@theemusicNmovies)
[insta](https://www.instagram.com/olsgibson/)