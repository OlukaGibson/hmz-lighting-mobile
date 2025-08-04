import 'package:flutter/material.dart';
import '../models/led_theme.dart';

class ThemeListItem extends StatelessWidget {
  final LedTheme theme;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ThemeListItem({
    super.key,
    required this.theme,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme preview
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: _getThemeGradient(),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Icon(_getThemeIcon(), size: 32, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Theme name
              Text(
                theme.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Theme type
              Text(
                theme.type.displayName,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brightness indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.brightness_6,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${((theme.brightness / 255) * 100).round()}%',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  // Edit and delete buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.blue[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Gradient _getThemeGradient() {
    switch (theme.type) {
      case LedAnimationType.solid:
        return LinearGradient(colors: [theme.color, theme.color]);
      case LedAnimationType.rainbow:
        return const LinearGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.indigo,
            Colors.purple,
          ],
        );
      case LedAnimationType.breathe:
        return LinearGradient(
          colors: [
            theme.color.withOpacity(0.3),
            theme.color,
            theme.color.withOpacity(0.3),
          ],
        );
      case LedAnimationType.fire:
        return const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.red, Colors.orange, Colors.yellow],
        );
      case LedAnimationType.wave:
        return LinearGradient(
          colors: [
            theme.color.withOpacity(0.2),
            theme.color,
            theme.color.withOpacity(0.2),
          ],
        );
      default:
        return LinearGradient(
          colors: [theme.color.withOpacity(0.6), theme.color],
        );
    }
  }

  IconData _getThemeIcon() {
    switch (theme.type) {
      case LedAnimationType.solid:
        return Icons.circle;
      case LedAnimationType.breathe:
        return Icons.air;
      case LedAnimationType.rainbow:
        return Icons.gradient;
      case LedAnimationType.theaterChase:
        return Icons.theaters;
      case LedAnimationType.fade:
        return Icons.gradient;
      case LedAnimationType.strobe:
        return Icons.flash_on;
      case LedAnimationType.wave:
        return Icons.waves;
      case LedAnimationType.fire:
        return Icons.local_fire_department;
      case LedAnimationType.sparkle:
        return Icons.auto_awesome;
    }
  }
}
