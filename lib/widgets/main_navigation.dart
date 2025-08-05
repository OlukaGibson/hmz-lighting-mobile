import 'package:flutter/material.dart';
import '../pages/devices_page.dart';
import '../pages/themes_page.dart';
import '../pages/control_page.dart';
import '../pages/settings_page.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final ESP32BLEService _bleService;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _bleService = ESP32BLEService();
    _pages = [
      DevicesPage(bleService: _bleService),
      const ThemesPage(),
      const ControlPage(),
      const SettingsPage(),
    ];
    _initializeAndAutoConnect();
  }

  Future<void> _initializeAndAutoConnect() async {
    try {
      // Initialize BLE service and attempt auto-reconnection
      await _bleService.initialize();
    } catch (e) {
      print('Failed to initialize BLE service: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF009973),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFFFFFFFF),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
          BottomNavigationBarItem(icon: Icon(Icons.palette), label: 'Themes'),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Control'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
