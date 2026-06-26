import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/history_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../invoice/invoice_screen.dart';
import '../../services/invoice_print_service.dart'; // Added print service integration
import '../../database/bill_dao.dart'; // Added to fetch bill items on the fly

/// Lists all past bills (most recent first), with search by
/// customer name. Tapping a bill reopens its invoice so the
/// cashier can reprint/reshare it.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BillDao _billDao = BillDao(); // Initialized database instance for on-demand printing

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadBills();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Triggers direct thermal/PDF printing directly from the list item view
  Future<void> _directPrintBill(dynamic bill) async {
    try {
      // Fetching accompanying relational item parameters from the database mapping layer
      final items = await _billDao.getItemsForBill(bill.id!);
      
      final success = await InvoicePrintService.printInvoice(
        bill: bill,
        items: items,
      );

      if (!mounted) return;
      if (success) {
        AppSnackBar.showSuccess(context, 'Print command sent successfully');
      } else {
        AppSnackBar.showError(context, 'Printing cancelled or failed');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to execute quick print: ${e.toString()}');
      }
    }
  }

  Future<void> _confirmDelete(int billId) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Bill',
      message: 'Delete this bill permanently? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    final error = await context.read<HistoryProvider>().deleteBill(billId);
    if (!mounted) return;

    if (error != null) {
      AppSnackBar.showError(context, error);
    } else {
      AppSnackBar.showSuccess(context, 'Bill deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (value) => context.read<HistoryProvider>().search(value),
            ),
          ),
          Expanded(
            child: Consumer<HistoryProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage != null) {
                  return Center(child: Text(provider.errorMessage!));
                }
                if (provider.bills.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No bills yet.\nCreate a new bill to see it here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadBills(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.bills.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bill = provider.bills[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepOrange.withAlpha(26), // FIXED: Kept safe for all Flutter build versions
                          child: const Icon(Icons.receipt, color: Colors.deepOrange),
                        ),
                        title: Text(bill.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(bill.date, style: const TextStyle(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rs ${bill.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            // NEW: Quick Reprint Action Trigger
                            IconButton(
                              icon: const Icon(Icons.print_outlined, color: Colors.blueGrey),
                              tooltip: 'Quick Reprint',
                              onPressed: () => _directPrintBill(bill),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Delete Record',
                              onPressed: () => _confirmDelete(bill.id!),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceScreen(billId: bill.id!),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}