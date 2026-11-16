import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/app_database.dart';
import '../../../core/utils/money_format.dart';

class ExportService {
  const ExportService(this._db);

  final AppDatabase _db;

  /// Generates RFC 4180 CSV string for transactions.
  Future<String> generateCsv({
    DateTime? month,
    int? walletId,
  }) async {
    final query = _db.select(_db.transactions).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
      innerJoin(
        _db.wallets,
        _db.wallets.id.equalsExp(_db.transactions.walletId),
      ),
    ]);

    if (month != null) {
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1);
      query.where(_db.transactions.createdAt.isBiggerOrEqualValue(start) &
          _db.transactions.createdAt.isSmallerThanValue(end));
    }

    if (walletId != null) {
      query.where(_db.transactions.walletId.equals(walletId));
    }

    query.orderBy([OrderingTerm.desc(_db.transactions.createdAt)]);

    final rows = await query.get();

    final csvData = <List<dynamic>>[
      [
        'ID',
        'Date',
        'Time',
        'Type',
        'Category',
        'Wallet',
        'Amount',
        'Minor Units',
        'Title/Note',
        'Is Recurring',
      ],
    ];

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    for (final r in rows) {
      final tx = r.readTable(_db.transactions);
      final cat = r.readTable(_db.categories);
      final wall = r.readTable(_db.wallets);

      final isIncome = tx.type == TransactionType.income;
      final signedAmount = isIncome
          ? (tx.amountMinor / 100.0).toStringAsFixed(2)
          : (-tx.amountMinor / 100.0).toStringAsFixed(2);

      csvData.add([
        tx.id,
        dateFormat.format(tx.createdAt),
        timeFormat.format(tx.createdAt),
        isIncome ? 'Income' : 'Expense',
        cat.name,
        wall.name,
        signedAmount,
        tx.amountMinor,
        tx.title ?? '',
        tx.recurringRuleId != null ? 'Yes' : 'No',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  /// Generates a PDF Monthly Statement byte array.
  Future<Uint8List> generateMonthlyPdf({
    required DateTime month,
    int? walletId,
  }) async {
    final pdf = pw.Document();

    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final query = _db.select(_db.transactions).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
      innerJoin(
        _db.wallets,
        _db.wallets.id.equalsExp(_db.transactions.walletId),
      ),
    ]);

    query.where(_db.transactions.createdAt.isBiggerOrEqualValue(start) &
        _db.transactions.createdAt.isSmallerThanValue(end));

    if (walletId != null) {
      query.where(_db.transactions.walletId.equals(walletId));
    }

    query.orderBy([OrderingTerm.desc(_db.transactions.createdAt)]);
    final rows = await query.get();

    int totalIncomeMinor = 0;
    int totalExpenseMinor = 0;
    final categoryTotals = <String, int>{};

    for (final r in rows) {
      final tx = r.readTable(_db.transactions);
      final cat = r.readTable(_db.categories);

      if (tx.type == TransactionType.income) {
        totalIncomeMinor += tx.amountMinor;
      } else {
        totalExpenseMinor += tx.amountMinor;
        categoryTotals[cat.name] = (categoryTotals[cat.name] ?? 0) + tx.amountMinor;
      }
    }

    final netMinor = totalIncomeMinor - totalExpenseMinor;
    final monthLabel = DateFormat.yMMMM().format(month);
    final dateFormat = DateFormat('MMM d, yyyy');

    final primaryEmerald = PdfColor.fromHex('#0D9373');
    final incomeGreen = PdfColor.fromHex('#10B981');
    final expenseCoral = PdfColor.fromHex('#F43F5E');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Budget Tracker',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryEmerald,
                    ),
                  ),
                  pw.Text(
                    'Monthly Statement - $monthLabel',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Text(
                'Generated on ${DateFormat.yMd().format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
              ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Financial Overview Summary Cards
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryCard(
                  'Total Income',
                  formatMinor(totalIncomeMinor),
                  incomeGreen,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  formatMinor(totalExpenseMinor),
                  expenseCoral,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _buildSummaryCard(
                  'Net Savings',
                  formatMinor(netMinor),
                  netMinor >= 0 ? primaryEmerald : expenseCoral,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Category Breakdown (Top Expenses)
          if (categoryTotals.isNotEmpty) ...[
            pw.Text(
              'Spending by Category',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: primaryEmerald),
              headers: ['Category', 'Amount', '% of Total'],
              data: categoryTotals.entries.map((entry) {
                final pct = totalExpenseMinor > 0
                    ? ((entry.value / totalExpenseMinor) * 100).toStringAsFixed(1)
                    : '0.0';
                return [entry.key, formatMinor(entry.value), '$pct%'];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // Transaction Ledger
          pw.Text(
            'Transaction Ledger (${rows.length} entries)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E293B')),
            headers: ['Date', 'Type', 'Category', 'Wallet', 'Note', 'Amount'],
            data: rows.map((r) {
              final tx = r.readTable(_db.transactions);
              final cat = r.readTable(_db.categories);
              final wall = r.readTable(_db.wallets);
              final isIncome = tx.type == TransactionType.income;

              return [
                dateFormat.format(tx.createdAt),
                isIncome ? 'Income' : 'Expense',
                cat.name,
                wall.name,
                tx.title ?? '-',
                '${isIncome ? '+' : '-'}${formatMinor(tx.amountMinor)}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
