import 'package:flutter/material.dart';

enum LedAnimationType {
  solid,
  breathe,
  rainbow,
  theaterChase,
  fade,
  strobe,
  wave,
  fire,
  sparkle,
}

class LedTheme {
  final String id;
  final String name;
  final LedAnimationType type;
  final Color color;
  final int brightness; // 0-255
  final int speed; // 0-100
  final int saturation; // 0-100
  final int delay; // milliseconds
  final bool reverse;
  final DateTime created;
  final DateTime modified;

  const LedTheme({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.brightness = 255,
    this.speed = 50,
    this.saturation = 100,
    this.delay = 50,
    this.reverse = false,
    required this.created,
    required this.modified,
  });

  factory LedTheme.fromJson(Map<String, dynamic> json) {
    return LedTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      type: LedAnimationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LedAnimationType.solid,
      ),
      color: Color(json['color'] as int),
      brightness: json['brightness'] as int? ?? 255,
      speed: json['speed'] as int? ?? 50,
      saturation: json['saturation'] as int? ?? 100,
      delay: json['delay'] as int? ?? 50,
      reverse: json['reverse'] as bool? ?? false,
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'color': color.value,
      'brightness': brightness,
      'speed': speed,
      'saturation': saturation,
      'delay': delay,
      'reverse': reverse,
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
    };
  }

  LedTheme copyWith({
    String? id,
    String? name,
    LedAnimationType? type,
    Color? color,
    int? brightness,
    int? speed,
    int? saturation,
    int? delay,
    bool? reverse,
    DateTime? created,
    DateTime? modified,
  }) {
    return LedTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      brightness: brightness ?? this.brightness,
      speed: speed ?? this.speed,
      saturation: saturation ?? this.saturation,
      delay: delay ?? this.delay,
      reverse: reverse ?? this.reverse,
      created: created ?? this.created,
      modified: modified ?? this.modified,
    );
  }

  // Convert to BLE command format
  Map<String, dynamic> toBleCommand() {
    return {
      'command': 'set_theme',
      'theme': {
        'type': type.name,
        'color': {'r': color.red, 'g': color.green, 'b': color.blue},
        'brightness': brightness,
        'speed': speed,
        'saturation': saturation,
        'delay': delay,
        'reverse': reverse,
      },
    };
  }

  @override
  String toString() {
    return 'LedTheme(id: $id, name: $name, type: $type, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LedTheme && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extension to get display names for animation types
extension LedAnimationTypeExtension on LedAnimationType {
  String get displayName {
    switch (this) {
      case LedAnimationType.solid:
        return 'Solid Color';
      case LedAnimationType.breathe:
        return 'Breathe';
      case LedAnimationType.rainbow:
        return 'Rainbow';
      case LedAnimationType.theaterChase:
        return 'Theater Chase';
      case LedAnimationType.fade:
        return 'Fade';
      case LedAnimationType.strobe:
        return 'Strobe';
      case LedAnimationType.wave:
        return 'Wave';
      case LedAnimationType.fire:
        return 'Fire';
      case LedAnimationType.sparkle:
        return 'Sparkle';
    }
  }

  String get description {
    switch (this) {
      case LedAnimationType.solid:
        return 'Static solid color';
      case LedAnimationType.breathe:
        return 'Slow fade in and out';
      case LedAnimationType.rainbow:
        return 'Cycling rainbow colors';
      case LedAnimationType.theaterChase:
        return 'Classic theater marquee effect';
      case LedAnimationType.fade:
        return 'Smooth color transitions';
      case LedAnimationType.strobe:
        return 'Fast blinking effect';
      case LedAnimationType.wave:
        return 'Flowing wave pattern';
      case LedAnimationType.fire:
        return 'Flickering fire simulation';
      case LedAnimationType.sparkle:
        return 'Random sparkling dots';
    }
  }
}
