class ShippingAddress {
  final String id;
  final String name;
  final String street;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String? phone;

  ShippingAddress({
    required this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    this.phone,
  });

  // Getters for compatibility
  String get streetAddress => street;
  String get postalCode => zipCode;
  String get phoneNumber => phone ?? '';

  factory ShippingAddress.fromMap(Map<String, dynamic> map, String id) {
    return ShippingAddress(
      id: id,
      name: map['name'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      zipCode: map['zipCode'] ?? '',
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'phone': phone,
    };
  }

  @override
  String toString() {
    return '$street, $city, $state $zipCode';
  }

  ShippingAddress copyWith({
    String? id,
    String? name,
    String? street,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    String? phone,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      phone: phone ?? this.phone,
    );
  }
} 