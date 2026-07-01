import 'package:flutter/material.dart';
import '../../database/bill_dao.dart';

enum ReportPeriod { daily, weekly, yearly }

class ReportMetrics {
  final int totalInvoices;
  final double totalItemsSold;
  final double expectedDrawerCash; // Total Grand Totals
  final double totalCashReceived;  // Total Paid Amounts
  final Map<String, double> salesOverTime; // For Chart Mapping (Date -> Sales Amount)

  ReportMetrics({
    required this.totalInvoices,
    required this.totalItemsSold,
    required this.expectedDrawerCash,
    required this.totalCashReceived,
    required this.salesOverTime,
  });
}

class ReportsProvider extends ChangeNotifier {
  final BillDao _billDao = BillDao();

  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  ReportMetrics? _currentMetrics;
  bool _isLoading = false;
  String? _errorMessage;

  ReportPeriod get selectedPeriod => _selectedPeriod;
  ReportMetrics? get currentMetrics => _currentMetrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setPeriod(ReportPeriod period) {
    _selectedPeriod = period;
    generateReport();
  }

  Future<void> generateReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch all bills from Database via DAO
      final allBills = await _billDao.getAllBills();
      final DateTime now = DateTime.now();

      // 2. Filter bills based on selected period
      final filteredBills = allBills.where((bill) {
        // Assuming bill.date is stored as ISO String (YYYY-MM-DD) or parsed correctly
        final billDate = DateTime.tryParse(bill.date) ?? now; 

        if (_selectedPeriod == ReportPeriod.daily) {
          return billDate.year == now.year &&
                 billDate.month == now.month &&
                 billDate.day == now.day;
        } else if (_selectedPeriod == ReportPeriod.weekly) {
          final oneWeekAgo = now.subtract(const Duration(days: 7));
          return billDate.isAfter(oneWeekAgo);
        } else { // Yearly
          return billDate.year == now.year;
        }
      }).toList();

      // 3. Aggregate Core Audit Metrics
      double itemsCount = 0.0;
      double expectedCash = 0.0;
      double cashReceived = 0.0;
      Map<String, double> timeSeriesData = {};

      for (var bill in filteredBills) {
        final billDate = DateTime.tryParse(bill.date) ?? now;
        expectedCash += bill.grandTotal;
        cashReceived += (bill.paidAmount > 0) ? bill.paidAmount : bill.grandTotal; // Cash fallback check
        
        // Fetch items count for each bill from DB relational mapper
        final items = await _billDao.getItemsForBill(bill.id!);
        for (var item in items) {
          itemsCount += item.quantity;
        }

        // Time Series aggregation for charts (Grouping by Date or Month)
        String label = _selectedPeriod == ReportPeriod.yearly 
            ? "${billDate.year}-${billDate.month.toString().padLeft(2, '0')}" // Monthly buckets for Yearly report
            : "${billDate.month}/${billDate.day}"; // Daily buckets for Weekly/Daily report
            
        timeSeriesData[label] = (timeSeriesData[label] ?? 0.0) + bill.grandTotal;
      }

      _currentMetrics = ReportMetrics(
        totalInvoices: filteredBills.length,
        totalItemsSold: itemsCount,
        expectedDrawerCash: expectedCash,
        totalCashReceived: cashReceived,
        salesOverTime: timeSeriesData,
      );

    } catch (e) {
      _errorMessage = "Failed to compile financial metrics: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}