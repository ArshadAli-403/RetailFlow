import 'package:flutter/material.dart';
//import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import '../../database/bill_dao.dart';
import '../../models/bill_item_model.dart';
import '../../models/bill_model.dart';
import '../../services/invoice_service.dart';
import '../../services/share_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../services/invoice_print_service.dart';

/// Displays a printable-looking invoice for [billId], and lets the
/// user:
/// - Share it as a PDF (built with the `pdf` package)
/// - Share it as a PNG screenshot of the on-screen invoice widget
///
/// Both share paths reuse [ShareService]. The PDF is built from
/// structured data via [InvoiceService]; the image capture uses the
/// `screenshot` package on the rendered widget tree below.
class InvoiceScreen extends StatefulWidget {
  final int billId;

  const InvoiceScreen({super.key, required this.billId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final BillDao _billDao = BillDao();
  final ScreenshotController _screenshotController = ScreenshotController();

  Bill? _bill;
  List<BillItem> _items = [];
  bool _isLoading = true;
  bool _isShareImageBusy = false;
  bool _isPrintingBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    try {
      final bill = await _billDao.getBillById(widget.billId);
      final items = await _billDao.getItemsForBill(widget.billId);
      if (!mounted) return;
      setState(() {
        _bill = bill;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load invoice: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /*Future<void> _sharePdf() async {
    if (_bill == null) return;
    setState(() => _isSharePdfBusy = true);
    try {
      final bytes = await InvoiceService.generateInvoicePdf(
        bill: _bill!,
        items: _items,
        qrData: 'BILL-${_bill!.id}',
      );
      await ShareService.sharePdfBytes(bytes: bytes, billId: _bill!.id!);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to share PDF: $e');
    } finally {
      if (mounted) setState(() => _isSharePdfBusy = false);
    }
  }*/

  Future<void> _shareImage() async {
    if (_bill == null) return;
    setState(() => _isShareImageBusy = true);
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 2.5);
      if (bytes == null) {
        throw Exception('Could not capture invoice image');
      }
      await ShareService.shareImageBytes(bytes: bytes, billId: _bill!.id!);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Failed to share image: $e');
    } finally {
      if (mounted) setState(() => _isShareImageBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.billId}'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _bill == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isShareImageBusy ? null : _shareImage,
                        icon: _isShareImageBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.image_outlined),
                        label: const Text('Share Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 1. Ek loading variable screen ki state (top of class) mein lazmi bana lein:
// bool _isPrintingBusy = false;

Expanded(
  child: FilledButton.icon(
    onPressed: (_isPrintingBusy || _bill == null) 
        ? null 
        : () async {
            setState(() {
              _isPrintingBusy = true;
            });

            // ✅ FIXED: Local state variables '_bill!' aur '_items' pass kar diye
            await InvoicePrintService.printInvoice(
              bill: _bill!, 
              items: _items,
            );

            setState(() {
              _isPrintingBusy = false;
            });
          },
    icon: _isPrintingBusy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.print_outlined),
    label: const Text('Print Invoice'),
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
  ),
),                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_bill == null) {
      return const Center(child: Text('Bill not found.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: _InvoiceContent(bill: _bill!, items: _items),
        ),
      ),
    );
  }
}

/// Pure visual representation of the invoice. Kept separate so the
/// same widget tree can be wrapped in [Screenshot] for image export
/// without entangling state/loading logic.
class _InvoiceContent extends StatelessWidget {
  final Bill bill;
  final List<BillItem> items;

  const _InvoiceContent({required this.bill, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          InvoiceService.shopName,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 2),
        Text(
          InvoiceService.shopAddress,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          InvoiceService.shopPhone,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.black26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bill #: ${bill.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                Text('Customer: ${bill.customerName}', style: const TextStyle(color: Colors.black)),
              ],
            ),
            Text(bill.date, style: const TextStyle(fontSize: 12, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 12),
        // Items table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black26)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
              Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
              Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
              Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
            ],
          ),
        ),
        ...items.map(
          (item) {
            final bool isManualItem = item.productId == null;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                       Text(item.productName, style: const TextStyle(color: Colors.black)),
if (isManualItem) ...[
  const SizedBox(width: 4),
  Text(
    // 🔥 FIXED: Hardcoded '(*)' ko real unit data se replace kar diya hai
    '(${item.unit ?? 'kg'})', 
    style: TextStyle(
      fontSize: 10, 
      color: Colors.grey.shade600, 
      fontWeight: FontWeight.bold,
    ),
  ),
]
                      ],
                    ),
                  ),
                  Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black))),
                  Expanded(flex: 2, child: Text(item.unitPrice.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(color: Colors.black))),
                  Expanded(flex: 2, child: Text(item.totalPrice.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(color: Colors.black))),
                ],
              ),
            );
          },
        ),
        const Divider(color: Colors.black26),
        _totalLine('Subtotal', bill.subtotal),
        if (bill.extraCharges > 0) _totalLine('Extra Charges', bill.extraCharges),
        const SizedBox(height: 4),
        _totalLine('Grand Total', bill.grandTotal, emphasize: true),
        const SizedBox(height: 4),

        if (bill.paidAmount > 0) _totalLine('Paid Amount', bill.paidAmount),
        if (bill.paidAmount > 0) _totalLine('Return Amount', bill.returnAmount, emphasize: true),
        
        // Dynamic Notes/Description implementation
        if (bill.productDescription != null && bill.productDescription!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          // Line 289 ko iske sath replace karein:
const Divider(color: Colors.black12, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notes / Remarks:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  bill.productDescription!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        const Divider(color: Colors.black26),
        const SizedBox(height: 8),
        const Text(
          'Thank you for shopping with us!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black),
        ),
        const SizedBox(height: 8),
        const Text(
          'Generated by RetailFlow\nDeveloped by Mr.Arshad +92 3127461403',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _totalLine(String label, double value, {bool emphasize = false}) {
    final style = TextStyle(
      fontSize: emphasize ? 16 : 14,
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: Colors.black,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('Rs ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}