class Device {
  final String id;
  final String name;
  final String address;
  final DateTime lastConnected;
  final bool isConnected;
  final Map<String, dynamic>? configuration;

  const Device({
    required this.id,
    required this.name,
    required this.address,
    required this.lastConnected,
    this.isConnected = false,
    this.configuration,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lastConnected: DateTime.parse(json['lastConnected'] as String),
      isConnected: json['isConnected'] as bool? ?? false,
      configuration: json['configuration'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lastConnected': lastConnected.toIso8601String(),
      'isConnected': isConnected,
      'configuration': configuration,
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? lastConnected,
    bool? isConnected,
    Map<String, dynamic>? configuration,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lastConnected: lastConnected ?? this.lastConnected,
      isConnected: isConnected ?? this.isConnected,
      configuration: configuration ?? this.configuration,
    );
  }

  @override
  String toString() {
    return 'Device(id: $id, name: $name, address: $address, isConnected: $isConnected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
