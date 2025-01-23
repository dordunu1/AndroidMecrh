class ShippingAddress {
  final String id;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zip;
  final String phone;
  final String? name;
  final String? email;

  ShippingAddress({
    required this.id,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zip,
    required this.phone,
    this.name,
    this.email,
  });

  // Getters for compatibility
  String get street => address;
  String get zipCode => zip;

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      id: map['id'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      country: map['country'] ?? '',
      zip: map['zip'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] as String?,
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip': zip,
      'phone': phone,
      'name': name,
      'email': email,
    };
  }

  @override
  String toString() {
    return '$address, $city, $state $zip, $country';
  }

  ShippingAddress copyWith({
    String? id,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zip,
    String? phone,
    String? name,
    String? email,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zip: zip ?? this.zip,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
} 