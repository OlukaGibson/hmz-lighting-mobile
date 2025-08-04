import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';
import '../models/led_theme.dart';

class StorageService {
  static const String _devicesKey = 'saved_devices';
  static const String _themesKey = 'saved_themes';
  static const String _settingsKey = 'app_settings';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError(
        'StorageService not initialized. Call initialize() first.',
      );
    }
    return _prefs!;
  }

  // Device management
  Future<List<Device>> getSavedDevices() async {
    final devicesJson = prefs.getString(_devicesKey);
    if (devicesJson == null) return [];

    try {
      final List<dynamic> devicesList = jsonDecode(devicesJson);
      return devicesList.map((json) => Device.fromJson(json)).toList();
    } catch (e) {
      print('Error loading devices: $e');
      return [];
    }
  }

  Future<void> saveDevices(List<Device> devices) async {
    try {
      final devicesJson = jsonEncode(devices.map((d) => d.toJson()).toList());
      await prefs.setString(_devicesKey, devicesJson);
    } catch (e) {
      print('Error saving devices: $e');
    }
  }

  Future<void> addDevice(Device device) async {
    final devices = await getSavedDevices();
    final existingIndex = devices.indexWhere((d) => d.id == device.id);

    if (existingIndex >= 0) {
      devices[existingIndex] = device;
    } else {
      devices.add(device);
    }

    await saveDevices(devices);
  }

  Future<void> removeDevice(String deviceId) async {
    final devices = await getSavedDevices();
    devices.removeWhere((d) => d.id == deviceId);
    await saveDevices(devices);
  }

  Future<void> updateDevice(Device device) async {
    final devices = await getSavedDevices();
    final index = devices.indexWhere((d) => d.id == device.id);

    if (index >= 0) {
      devices[index] = device;
      await saveDevices(devices);
    }
  }

  // Theme management
  Future<List<LedTheme>> getSavedThemes() async {
    final themesJson = prefs.getString(_themesKey);
    if (themesJson == null) return [];

    try {
      final List<dynamic> themesList = jsonDecode(themesJson);
      return themesList.map((json) => LedTheme.fromJson(json)).toList();
    } catch (e) {
      print('Error loading themes: $e');
      return [];
    }
  }

  Future<void> saveThemes(List<LedTheme> themes) async {
    try {
      final themesJson = jsonEncode(themes.map((t) => t.toJson()).toList());
      await prefs.setString(_themesKey, themesJson);
    } catch (e) {
      print('Error saving themes: $e');
    }
  }

  Future<void> addTheme(LedTheme theme) async {
    final themes = await getSavedThemes();
    final existingIndex = themes.indexWhere((t) => t.id == theme.id);

    if (existingIndex >= 0) {
      themes[existingIndex] = theme;
    } else {
      themes.add(theme);
    }

    await saveThemes(themes);
  }

  Future<void> removeTheme(String themeId) async {
    final themes = await getSavedThemes();
    themes.removeWhere((t) => t.id == themeId);
    await saveThemes(themes);
  }

  Future<void> updateTheme(LedTheme theme) async {
    final themes = await getSavedThemes();
    final index = themes.indexWhere((t) => t.id == theme.id);

    if (index >= 0) {
      themes[index] = theme;
      await saveThemes(themes);
    }
  }

  // App settings
  Future<Map<String, dynamic>> getSettings() async {
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) return {};

    try {
      return jsonDecode(settingsJson);
    } catch (e) {
      print('Error loading settings: $e');
      return {};
    }
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final settingsJson = jsonEncode(settings);
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<T?> getSetting<T>(String key) async {
    final settings = await getSettings();
    return settings[key] as T?;
  }

  Future<void> setSetting<T>(String key, T value) async {
    final settings = await getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await prefs.remove(_devicesKey);
    await prefs.remove(_themesKey);
    await prefs.remove(_settingsKey);
  }
}
