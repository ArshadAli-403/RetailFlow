/// ===============================================================
/// BILL ITEM MODEL
/// RetailFlow POS
/// ===============================================================
///
/// Represents one product row inside an invoice.
///
/// Supports:
/// • Barcode Products
/// • Manual Products
/// • Different Units (pcs, kg, g, litre etc.)
///

class BillItem {
  final int? id;

  final int billId;

  /// Null when item is manually entered.
  final int? productId;

  final String productName;

  final double quantity;

  /// pcs / kg / g / litre / dozen etc.
  final String unit;

  final double unitPrice;

  final double totalPrice;

  /// true = manually added product
  final bool isManual;

  const BillItem({
    this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    this.isManual = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'bill_id': billId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'is_manual': isManual ? 1 : 0,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as int?,
      billId: map['bill_id'] as int,
      productId: map['product_id'] as int?,
      productName: map['product_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] ?? 'pcs',
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      isManual: (map['is_manual'] ?? 0) == 1,
    );
  }

  BillItem copyWith({
    int? id,
    int? billId,
    int? productId,
    String? productName,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? totalPrice,
    bool? isManual,
  }) {
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      isManual: isManual ?? this.isManual,
    );
  }
}