/// ===============================================================
/// BILL MODEL
/// RetailFlow POS
/// ===============================================================
///
/// Represents one invoice (Bill Header).
///
/// Line items are stored separately in bill_items.
/// Multiple extra charges are stored in bill_extra_charges.
///

class Bill {
  final int? id;

  final String customerName;

  final String date;

  /// Total of all products
  final double subtotal;

  /// Total extra charges
  final double extraCharges;

  /// Final amount
  final double grandTotal;

  /// Optional note
  final String productDescription;

  /// Customer Paid
  final double paidAmount;

  /// Change Returned
  final double returnAmount;

  const Bill({
    this.id,
    required this.customerName,
    required this.date,
    required this.subtotal,
    required this.extraCharges,
    required this.grandTotal,
    this.productDescription = '',
    this.paidAmount = 0,
    this.returnAmount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_name': customerName,
      'date': date,
      'subtotal': subtotal,
      'extra_charges': extraCharges,
      'grand_total': grandTotal,
      'product_description': productDescription,
      'paid_amount': paidAmount,
      'return_amount': returnAmount,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as int?,
      customerName: map['customer_name'] ?? '',
      date: map['date'] ?? '',
      subtotal: (map['subtotal'] as num).toDouble(),
      extraCharges: (map['extra_charges'] as num?)?.toDouble() ?? 0,
      grandTotal: (map['grand_total'] as num).toDouble(),
      productDescription: map['product_description'] ?? '',
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      returnAmount: (map['return_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Bill copyWith({
    int? id,
    String? customerName,
    String? date,
    double? subtotal,
    double? extraCharges,
    double? grandTotal,
    String? productDescription,
    double? paidAmount,
    double? returnAmount,
  }) {
    return Bill(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      subtotal: subtotal ?? this.subtotal,
      extraCharges: extraCharges ?? this.extraCharges,
      grandTotal: grandTotal ?? this.grandTotal,
      productDescription:
          productDescription ?? this.productDescription,
      paidAmount: paidAmount ?? this.paidAmount,
      returnAmount: returnAmount ?? this.returnAmount,
    );
  }
}