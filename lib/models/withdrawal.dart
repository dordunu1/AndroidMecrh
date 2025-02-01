class Withdrawal {
  final String id;
  final String sellerId;
  final String sellerName;
  final double amount;
  final String status;
  final String paymentMethod;
  final String paymentDetails;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? adminNote;

  Withdrawal({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.paymentDetails,
    required this.createdAt,
    this.processedAt,
    this.adminNote,
  });

  factory Withdrawal.fromMap(Map<String, dynamic> map, String id) {
    return Withdrawal(
      id: id,
      sellerId: map['sellerId'] as String,
      sellerName: map['sellerName'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      paymentMethod: map['paymentMethod'] as String,
      paymentDetails: map['paymentDetails'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      processedAt: map['processedAt'] != null ? DateTime.parse(map['processedAt'] as String) : null,
      adminNote: map['adminNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentDetails': paymentDetails,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'adminNote': adminNote,
    };
  }

  Withdrawal copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    double? amount,
    String? status,
    String? paymentMethod,
    String? paymentDetails,
    DateTime? createdAt,
    DateTime? processedAt,
    String? adminNote,
  }) {
    return Withdrawal(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      adminNote: adminNote ?? this.adminNote,
    );
  }
} 