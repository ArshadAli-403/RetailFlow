import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().generateReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports & Audit', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)));
          }

          final metrics = provider.currentMetrics;

          return Column(
            children: [
              // Segmented Period Selector Selector
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SegmentedButton<ReportPeriod>(
                  segments: const [
                    ButtonSegment(value: ReportPeriod.daily, label: Text('Daily'), icon: Icon(Icons.today)),
                    ButtonSegment(value: ReportPeriod.weekly, label: Text('Weekly'), icon: Icon(Icons.view_week)),
                    ButtonSegment(value: ReportPeriod.yearly, label: Text('Yearly'), icon: Icon(Icons.calendar_month)),
                  ],
                  selected: {provider.selectedPeriod},
                  onSelectionChanged: (Set<ReportPeriod> newSelection) {
                    provider.setPeriod(newSelection.first);
                  },
                ),
              ),

              Expanded(
                child: metrics == null
                    ? const Center(child: Text('No data compiled for this scope.'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // CRITICAL AUDIT: Cash Drawer Reconciliation Banner
                          Card(
                            color: Colors.green.shade50,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green.shade100,
                                    child: const Icon(Icons.point_of_sale, color: Colors.green),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Expected Drawer Cash',
                                          style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Rs. ${metrics.expectedDrawerCash.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Grid Layout for sub-metrics
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              _buildMetricCard(
                                title: 'Total Cash Received',
                                value: 'Rs.${metrics.totalCashReceived.toStringAsFixed(0)}',
                                icon: Icons.payments_outlined,
                                color: Colors.blue,
                              ),
                              _buildMetricCard(
                                title: 'Invoices Generated',
                                value: '${metrics.totalInvoices}',
                                icon: Icons.receipt_long_outlined,
                                color: Colors.deepOrange,
                              ),
                              _buildMetricCard(
                                title: 'Total Items Sold',
                                value: '${metrics.totalItemsSold} ',
                                icon: Icons.inventory_2_outlined,
                                color: Colors.purple,
                              ),
                              _buildMetricCard(
                                title: 'Discrepancy Check',
                                value: 'Rs.${(metrics.expectedDrawerCash - metrics.totalCashReceived).toStringAsFixed(0)}',
                                icon: Icons.calculate_outlined,
                                color: Colors.blueGrey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Pure Flutter Visual Chart Representation
                          const Text(
                            'Sales Volume Breakdown',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildCustomBarChart(metrics.salesOverTime),
                          const SizedBox(height: 32),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(100)),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Custom lightweight bar chart component without needing external packages
  Widget _buildCustomBarChart(Map<String, double> chartData) {
    if (chartData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('Not enough sales history to plot chart graph.', style: TextStyle(fontSize: 12))),
        ),
      );
    }

    final maxVal = chartData.values.reduce((a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.entries.map((entry) {
              final percentage = maxVal > 0 ? (entry.value / maxVal) : 0.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Rs.${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: (percentage * 110).clamp(8.0, 110.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(entry.key, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}