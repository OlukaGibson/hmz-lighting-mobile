import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/led_theme.dart';

class ThemeCreateDialog extends StatefulWidget {
  final LedTheme? theme;

  const ThemeCreateDialog({super.key, this.theme});

  @override
  State<ThemeCreateDialog> createState() => _ThemeCreateDialogState();
}

class _ThemeCreateDialogState extends State<ThemeCreateDialog> {
  late TextEditingController _nameController;
  late LedAnimationType _selectedType;
  late Color _selectedColor;
  late double _brightness;
  late double _speed;
  late double _saturation;
  late double _delay;
  late bool _reverse;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Initialize with existing theme values or defaults
    _nameController = TextEditingController(text: widget.theme?.name ?? '');
    _selectedType = widget.theme?.type ?? LedAnimationType.solid;
    _selectedColor = widget.theme?.color ?? Colors.blue;
    _brightness = (widget.theme?.brightness ?? 255).toDouble();
    _speed = (widget.theme?.speed ?? 50).toDouble();
    _saturation = (widget.theme?.saturation ?? 100).toDouble();
    _delay = (widget.theme?.delay ?? 50).toDouble();
    _reverse = widget.theme?.reverse ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  void _saveTheme() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final theme = LedTheme(
      id: widget.theme?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _selectedType,
      color: _selectedColor,
      brightness: _brightness.round(),
      speed: _speed.round(),
      saturation: _saturation.round(),
      delay: _delay.round(),
      reverse: _reverse,
      created: widget.theme?.created ?? now,
      modified: now,
    );

    Navigator.of(context).pop(theme);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.theme != null ? 'Edit Theme' : 'Create Theme',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Theme name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Theme Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a theme name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Animation type
                      DropdownButtonFormField<LedAnimationType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Animation Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.animation),
                        ),
                        items: LedAnimationType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(type.displayName),
                                Text(
                                  type.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Color picker
                      InkWell(
                        onTap: _showColorPicker,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.color_lens),
                              const SizedBox(width: 12),
                              const Text('Color'),
                              const Spacer(),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _selectedColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Brightness slider
                      _buildSlider(
                        label: 'Brightness',
                        value: _brightness,
                        min: 0,
                        max: 255,
                        divisions: 255,
                        onChanged: (value) =>
                            setState(() => _brightness = value),
                        valueLabel: '${(_brightness / 255 * 100).round()}%',
                        icon: Icons.brightness_6,
                      ),

                      const SizedBox(height: 16),

                      // Speed slider (only for animated types)
                      if (_selectedType != LedAnimationType.solid)
                        _buildSlider(
                          label: 'Speed',
                          value: _speed,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          onChanged: (value) => setState(() => _speed = value),
                          valueLabel: '${_speed.round()}%',
                          icon: Icons.speed,
                        ),

                      if (_selectedType != LedAnimationType.solid)
                        const SizedBox(height: 16),

                      // Saturation slider
                      _buildSlider(
                        label: 'Saturation',
                        value: _saturation,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (value) =>
                            setState(() => _saturation = value),
                        valueLabel: '${_saturation.round()}%',
                        icon: Icons.opacity,
                      ),

                      const SizedBox(height: 16),

                      // Delay slider (only for animated types)
                      if (_selectedType != LedAnimationType.solid)
                        _buildSlider(
                          label: 'Delay',
                          value: _delay,
                          min: 10,
                          max: 1000,
                          divisions: 99,
                          onChanged: (value) => setState(() => _delay = value),
                          valueLabel: '${_delay.round()}ms',
                          icon: Icons.timer,
                        ),

                      if (_selectedType != LedAnimationType.solid)
                        const SizedBox(height: 16),

                      // Reverse switch (only for animated types)
                      if (_selectedType != LedAnimationType.solid)
                        SwitchListTile(
                          title: const Text('Reverse Direction'),
                          subtitle: const Text('Play animation in reverse'),
                          value: _reverse,
                          onChanged: (value) =>
                              setState(() => _reverse = value),
                          secondary: const Icon(Icons.swap_horiz),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveTheme,
                    child: Text(widget.theme != null ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
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
}
