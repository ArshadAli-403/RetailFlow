import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/barcode_scanner_screen.dart';
import '../../widgets/cart_item_tile.dart';
import '../../widgets/confirmation_dialog.dart';
import '../invoice/invoice_screen.dart';
import '../products/add_edit_product_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _paidAmountController =   TextEditingController();

  @override
  void dispose() {
    _customerController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _scanAndAdd() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(title: 'Scan Product'),
      ),
    );
    if (code == null || !mounted) return;
    await _handleBarcode(code);
  }

  Future<void> _handleBarcode(String barcode) async {
    final billingProvider = context.read<BillingProvider>();
    final result = await billingProvider.handleScannedBarcode(barcode);

    if (!mounted) return;

    switch (result) {
      case ScanResult.added:
        AppSnackBar.showSuccess(context, 'Product added to cart');
        break;
      case ScanResult.notFound:
        final shouldAdd = await showProductNotFoundDialog(
          context: context,
          barcode: barcode,
        );
        if (shouldAdd && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditProductScreen(initialBarcode: barcode),
            ),
          );
          if (mounted) {
            await context.read<BillingProvider>().handleScannedBarcode(barcode);
          }
        }
        break;
      case ScanResult.error:
        AppSnackBar.showError(
          context,
          billingProvider.errorMessage ?? 'Something went wrong',
        );
        break;
    }
  }

  void _showManualProductBottomSheet() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String selectedUnit = 'pcs';
    final units = ['pcs', 'kg', 'g', 'litre', 'pack', 'dozen'];

    showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent, // 1. ✅ Background transparent kiya taake margins visible hon
  builder: (context) {
    return Container(
      // 2. ✅ Horizontally margins di hain taake edges chipke na aur card look aaye
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      // Inner Padding (Content layout management aur keyboard safety)
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Dynamic keyboard cushion + spacing
        left: 16,
        right: 16,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // App theme ka card background color
        borderRadius: BorderRadius.circular(16), // 3. ✅ Charon corners round kar diye card look ke liye
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add Manual Product',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Product Name',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price (PKR)',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) {
                    if (val != null) selectedUnit = val;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Quantity',
              prefixIcon: Icon(Icons.production_quantity_limits),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              final qty = double.tryParse(qtyController.text) ?? 1;

              if (name.isEmpty || price <= 0 || qty <= 0) {
                AppSnackBar.showError(context, 'Please enter valid product details');
                return;
              }

              context.read<BillingProvider>().addManualProductToCart(
                    name: name,
                    price: price,
                    quantity: qty,
                    unit: selectedUnit,
                  );

              Navigator.pop(context);
              AppSnackBar.showSuccess(context, 'Manual item added to cart');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add to Invoice'),
          ),
        ],
      ),
    );
  },
);
  }

  void _showMultipleChargesBottomSheet() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent, // 1. ✅ Background ko transparent kiya taake floating gap dikhe
  builder: (context) {
    return Consumer<BillingProvider>(
      builder: (context, provider, _) {
        return Container(
          // 2. ✅ Outer Margin lagayi taake sheet sides se screen chor de aur card lage
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          // Inner Padding for contents
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Dynamic keyboard cushion + spacing
            left: 16,
            right: 16,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, // White ya theme ka base background card color
            borderRadius: BorderRadius.circular(16), // 3. ✅ Charon koney round kiye card look ke liye
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manage Additional Charges',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (provider.additionalChargesList.isNotEmpty) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.additionalChargesList.length,
                    itemBuilder: (context, idx) {
                      final charge = provider.additionalChargesList[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.label_important_outline, color: Colors.blue),
                        title: Text(charge.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Rs.${charge.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () => provider.removeAdditionalCharge(idx),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Charge Label (e.g., Delivery)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final t = titleController.text.trim();
                  final a = double.tryParse(amountController.text) ?? 0.0;
                  if (t.isEmpty || a <= 0) {
                    AppSnackBar.showError(context, 'Enter valid title and amount');
                    return;
                  }
                  provider.addAdditionalCharge(t, a);
                  titleController.clear();
                  amountController.clear();
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Charge'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  },
);
  }

  Future<void> _checkout() async {
    final billingProvider = context.read<BillingProvider>();

    if (billingProvider.isCartEmpty) {
      AppSnackBar.showError(context, 'Cart is empty. Scan a product first.');
      return;
    }

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Confirm Checkout',
      message:
          'Grand total: PKR ${billingProvider.grandTotal.toStringAsFixed(2)}\n\nProceed to generate invoice?',
      confirmText: 'Checkout',
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;

    final billId = await billingProvider.checkout();

    if (!mounted) return;

    if (billId == null) {
      AppSnackBar.showError(
        context,
        billingProvider.errorMessage ?? 'Checkout failed',
      );
      return;
    }

    AppSnackBar.showSuccess(context, 'Bill created successfully');

    _customerController.clear();
    _paidAmountController.clear();
    
    billingProvider.clearCart();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceScreen(billId: billId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIXED: Upper corner action icon removed as requested. Only clean title & delete action left.
      appBar: AppBar(
        title: const Text('New Bill', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Consumer<BillingProvider>(
            builder: (context, provider, _) {
              if (provider.isCartEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear cart',
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context: context,
                    title: 'Clear Cart',
                    message: 'Remove all items from this bill?',
                  );
                  if (confirmed) provider.clearCart();
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    TextField(
                      controller: _customerController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name (optional)',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) =>
                          context.read<BillingProvider>().setCustomerName(value),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showMultipleChargesBottomSheet,
                      child: AbsorbPointer(
                        child: Consumer<BillingProvider>(
                          builder: (context, provider, _) {
                            return TextField(
                              decoration: InputDecoration(
                                labelText: provider.additionalChargesList.isEmpty
                                    ? 'Extra Charges (Tap to Add)'
                                    : 'Charges Count: ${provider.additionalChargesList.length} (Total: Rs.${provider.totalExtraCharges})',
                                prefixIcon: const Icon(Icons.add_circle_outline),
                                suffixIcon: const Icon(Icons.edit_note, color: Colors.blue),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ❌ Description Textfield removed entirely from here!
                    TextField(
                      controller: _paidAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Paid Amount',
                        prefixIcon: Icon(Icons.payments),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 0;
                        context.read<BillingProvider>().setPaidAmount(amount);
                      },
                    ),
                  ],
                ),
              ),
            ),

            Consumer<BillingProvider>(
              builder: (context, provider, _) {
                if (provider.isCartEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Cart is empty.\nTap "Scan Product" or "Add Manually" below to add items.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = provider.cartItems[index];
                        return CartItemTile(
                          item: item,
                          onIncrement: () =>
                              provider.incrementQuantity(item.product.id!),
                          onDecrement: () =>
                              provider.decrementQuantity(item.product.id!),
                          onRemove: () => provider.removeItem(item.product.id!),
                        );
                      },
                      childCount: provider.cartItems.length,
                    ),
                  ),
                );
              },
            ),

            Consumer<BillingProvider>(
              builder: (context, provider, _) {
                return SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _totalsRow('Subtotal', provider.subtotal),
                          if (provider.totalExtraCharges > 0)
                            _totalsRow('Extra Charges', provider.totalExtraCharges),
                          _totalsRow(
                            'Grand Total',
                            provider.grandTotal,
                            emphasize: true,
                          ),
                          const SizedBox(height: 12),
                          if (provider.paidAmount > 0)
                            _totalsRow(
                              'Paid Amount',
                              provider.paidAmount,
                            ),
                          if (provider.paidAmount > 0)
                            _totalsRow(
                              'Return Amount',
                              provider.returnAmount,
                              emphasize: true,
                            ),
                          const SizedBox(height: 16),
                          
                          // 🔥 FIXED: Row configuration for Scan Product and Add Manually side-by-side
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _scanAndAdd,
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scan Product'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showManualProductBottomSheet,
                                  icon: const Icon(Icons.playlist_add), // Explicit requested manual entry icon
                                  label: const Text(
                                    'Add Manually', // Explicit descriptive text label added
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 🔥 FIXED: Stretched checkout action directly underneath the core button rows
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: provider.isProcessing ? null : _checkout,
                              icon: provider.isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.receipt_long),
                              label: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalsRow(String label, double value, {bool emphasize = false}) {
    final style = TextStyle(
      fontSize: emphasize ? 18 : 14,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: emphasize ? null : Colors.grey.shade700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('Rs.${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}