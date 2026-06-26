/// ===============================================================
/// EXTRA CHARGE MODEL
/// RetailFlow POS
/// ===============================================================
///
/// Represents one additional charge added to a bill.
///
/// Examples:
/// • Delivery Charges
/// • Packing Charges
/// • Service Charges
/// • Tax
/// • Discount Recovery
/// • Any Custom Charge
///

class ExtraCharge {
  final int? id;

  /// Parent Bill ID
  final int billId;

  /// Charge title
  /// Example:
  /// Delivery Charges
  /// Packing Charges
  final String title;

  /// Charge amount
  final double amount;

  const ExtraCharge({
    this.id,
    required this.billId,
    required this.title,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bill_id': billId,
      'title': title,
      'amount': amount,
    };
  }

  factory ExtraCharge.fromMap(Map<String, dynamic> map) {
    return ExtraCharge(
      id: map['id'] as int?,
      billId: map['bill_id'] as int,
      title: map['title'] ?? '',
      amount: (map['amount'] as num).toDouble(),
    );
  }

  ExtraCharge copyWith({
    int? id,
    int? billId,
    String? title,
    double? amount,
  }) {
    return ExtraCharge(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
    );
  }
}