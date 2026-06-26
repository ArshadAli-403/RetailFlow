
import 'package:sqflite/sqflite.dart';
import '../models/bill_model.dart';
import '../models/bill_item_model.dart';
import '../models/extra_charge_model.dart';
import 'database_helper.dart';

class BillDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createBillWithItems({
    required Bill bill,
    required List<BillItem> items,
    List<ExtraCharge> extraCharges = const [],
  }) async {
    final db = await _dbHelper.database;
    return db.transaction((txn) async {
      final billId = await txn.insert('bills', bill.toMap());
      for (final i in items) {
        await txn.insert('bill_items', i.copyWith(billId: billId).toMap());
      }
      for (final c in extraCharges) {
        await txn.insert('bill_extra_charges', c.copyWith(billId: billId).toMap());
      }
      return billId;
    });
  }

  Future<List<Bill>> getAllBills() async {
    final db = await _dbHelper.database;
    final rows = await db.query('bills', orderBy: 'id DESC');
    return rows.map(Bill.fromMap).toList();
  }

  Future<Bill?> getBillById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bills', where:'id=?', whereArgs:[id], limit:1);
    if(rows.isEmpty) return null;
    return Bill.fromMap(rows.first);
  }

  Future<List<BillItem>> getItemsForBill(int billId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bill_items', where:'bill_id=?', whereArgs:[billId]);
    return rows.map(BillItem.fromMap).toList();
  }

  Future<List<ExtraCharge>> getExtraChargesForBill(int billId) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bill_extra_charges', where:'bill_id=?', whereArgs:[billId]);
    return rows.map(ExtraCharge.fromMap).toList();
  }

  Future<int> deleteBill(int billId) async {
    final db = await _dbHelper.database;
    return db.delete('bills', where:'id=?', whereArgs:[billId]);
  }

  Future<List<Bill>> searchBillsByCustomer(String q) async {
    final db = await _dbHelper.database;
    final rows = await db.query('bills',where:'customer_name LIKE ?',whereArgs:['%$q%'],orderBy:'id DESC');
    return rows.map(Bill.fromMap).toList();
  }

  Future<double> totalSalesBetween(String from,String to) async{
    final db=await _dbHelper.database;
    final r=await db.rawQuery('SELECT SUM(grand_total) t FROM bills WHERE date>=? AND date<=?',[from,to]);
    return ((r.first['t'] as num?)??0).toDouble();
  }

  Future<int> totalInvoicesBetween(String from,String to) async{
    final db=await _dbHelper.database;
    final r=await db.rawQuery('SELECT COUNT(*) c FROM bills WHERE date>=? AND date<=?',[from,to]);
    return ((r.first['c'] as num?)??0).toInt();
  }
}
