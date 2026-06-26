import 'package:flutter/material.dart';

/// Centralized SnackBar helpers so every screen shows success/error
/// messages with consistent styling instead of building SnackBars
/// inline everywhere.
class AppSnackBar {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Colors.green.shade600, Icons.check_circle);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Colors.red.shade600, Icons.error);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, Colors.blueGrey.shade700, Icons.info);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }
}