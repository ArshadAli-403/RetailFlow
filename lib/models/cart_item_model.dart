import 'product_model.dart';

/// In-memory representation of a single line in the current cart
/// while a bill is being built on the Billing screen.
///
/// This is NOT a database table. Once checkout happens, each
/// [CartItem] is converted into a `bill_items` row by [BillItem].
class CartItem {
  final Product product;
  double quantity;

  CartItem({
    required this.product,
    this.quantity = 1.0,
  });

  double get totalPrice => product.price * quantity;

  void increment() => quantity+=1.0;

  /// Decrements quantity by one.
  /// Returns true once quantity reaches 0, signaling to the caller
  /// (BillingProvider) that this line should be removed from the
  /// cart entirely rather than displayed at zero.
  bool decrement() {
    quantity-=1.0;
    return quantity <= 0;
  }
}