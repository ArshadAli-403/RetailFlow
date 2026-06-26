import 'package:flutter/material.dart';

/// Generic Yes/No confirmation dialog. Used for delete-product and
/// delete-bill confirmations so we don't duplicate the same
/// AlertDialog boilerplate across screens.
///
/// Returns `true` if the user confirmed, `false`/`null` otherwise.
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Delete',
  String cancelText = 'Cancel',
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : null,
            ),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

/// Dialog shown when a scanned barcode has no matching product.
/// Returns `true` if the cashier wants to add it as a new product.
Future<bool> showProductNotFoundDialog({
  required BuildContext context,
  required String barcode,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Product Not Found'),
        content: Text(
          'No product matches barcode "$barcode".\n\n'
          'Do you want to add it as a new product?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add Product'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}