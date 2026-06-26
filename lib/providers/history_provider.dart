import 'package:flutter/foundation.dart';
import '../database/bill_dao.dart';
import '../models/bill_item_model.dart';
import '../models/bill_model.dart';

/// Backs the History screen: lists past bills and loads the
/// line items for any bill the user taps on (e.g. to reopen an
/// invoice for re-sharing).
class HistoryProvider extends ChangeNotifier {
  final BillDao _billDao = BillDao();

  List<Bill> _bills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBills() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bills = await _billDao.getAllBills();
    } catch (e) {
      _errorMessage = 'Failed to load bill history: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      await loadBills();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _bills = await _billDao.searchBillsByCustomer(query.trim());
    } catch (e) {
      _errorMessage = 'Search failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<BillItem>> loadItemsForBill(int billId) async {
    try {
      return await _billDao.getItemsForBill(billId);
    } catch (e) {
      _errorMessage = 'Failed to load bill items: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  Future<String?> deleteBill(int billId) async {
    try {
      await _billDao.deleteBill(billId);
      await loadBills();
      return null;
    } catch (e) {
      return 'Failed to delete bill: ${e.toString()}';
    }
  }
}