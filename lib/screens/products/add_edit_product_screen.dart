import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/barcode_scanner_screen.dart';

/// Add/Edit screen for a single product.
///
/// If [product] is null, this screen is in "add" mode (insert new
/// row). If [product] is provided, it's in "edit" mode (update the
/// existing row, keeping its id/created_at).
///
/// [initialBarcode] optionally pre-fills the barcode field — used
/// when the Billing screen scans a barcode with no matching product
/// and the cashier chooses to register it on the spot.
class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  final String? initialBarcode;

  const AddEditProductScreen({
    super.key,
    this.product,
    this.initialBarcode,
  });

  bool get isEditing => product != null;

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _barcodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _barcodeController = TextEditingController(
      text: p?.barcode ?? widget.initialBarcode ?? '',
    );
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p != null ? _trimTrailingZeros(p.price) : '',
    );
  }

  String _trimTrailingZeros(double value) {
    // Avoid showing "10.00" in an editable field; show "10" instead,
    // but keep "10.50" as-is.
    String text = value.toStringAsFixed(2);
    if (text.endsWith('.00')) {
      text = text.substring(0, text.length - 3);
    }
    return text;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(title: 'Scan Product Barcode'),
      ),
    );
    if (code != null && mounted) {
      setState(() => _barcodeController.text = code);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<ProductProvider>();
    final barcode = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());

    final String? error;
    if (widget.isEditing) {
      error = await provider.updateProduct(
        id: widget.product!.id!,
        barcode: barcode,
        name: name,
        price: price,
        createdAt: widget.product!.createdAt,
      );
    } else {
      error = await provider.addProduct(
        barcode: barcode,
        name: name,
        price: price,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      AppSnackBar.showError(context, error);
    } else {
      AppSnackBar.showSuccess(
        context,
        widget.isEditing ? 'Product Updated Successfully' : 'Product Saved Successfully',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan barcode',
                  onPressed: _scanBarcode,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Barcode is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Unit',
                border: OutlineInputBorder(),
                prefixText: 'Rs ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Price is required';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null) {
                  return 'Enter a valid number';
                }
                if (parsed <= 0) {
                  return 'Price must be greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Product'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}