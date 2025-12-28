import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:admin_web/src/features/analytics/view_models/analytics_view_model.dart';
import 'package:admin_web/src/shared/widgets/app_drawer.dart';
import 'package:admin_web/src/shared/widgets/custom_app_bar.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalyticsViewModel(),
      child: const _AnalyticsContent(),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalyticsViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Laporan & Analitik',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.fetchAllStats(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER CARDS ---
                  Row(
                    children: [
                      _buildSummaryCard(
                        'Total Pengguna',
                        '${viewModel.generalStats['total_users'] ?? 0}',
                        Icons.people,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Konten Dilihat',
                        '${viewModel.generalStats['total_activities'] ?? 0}', // Menggunakan activity sebagai proxy view
                        Icons.visibility,
                        Colors.purple,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Darurat (SOS)',
                        '${viewModel.generalStats['total_emergencies'] ?? 0}',
                        Icons.warning,
                        Colors.red,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // --- CHARTS ROW 1 ---
                  Row(
                    children: [
                      // Chart 1: Komposisi User (Lansia vs Keluarga)
                      Expanded(
                        child: _buildChartCard(
                          title: 'Komposisi Pengguna',
                          chart: SfCircularChart(
                            legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                            series: <CircularSeries>[
                              DoughnutSeries<ChartData, String>(
                                dataSource: viewModel.userRoleData,
                                xValueMapper: (ChartData data, _) => data.x,
                                yValueMapper: (ChartData data, _) => data.y,
                                pointColorMapper: (ChartData data, _) => data.color,
                                dataLabelSettings: const DataLabelSettings(isVisible: true),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Chart 2: Distribusi Konten
                      Expanded(
                        child: _buildChartCard(
                          title: 'Distribusi Tipe Konten',
                          chart: SfCircularChart(
                            legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                            series: <CircularSeries>[
                              PieSeries<ChartData, String>(
                                dataSource: viewModel.contentDistributionData,
                                xValueMapper: (ChartData data, _) => data.x,
                                yValueMapper: (ChartData data, _) => data.y,
                                pointColorMapper: (ChartData data, _) => data.color,
                                dataLabelSettings: const DataLabelSettings(isVisible: true),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- CHARTS ROW 2 ---
                  // Chart 3: Tren Mingguan (Line Chart)
                  _buildChartCard(
                    title: 'Tren Aktivitas Mingguan',
                    height: 300,
                    chart: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      primaryYAxis: const NumericAxis(title: AxisTitle(text: 'Views')),
                      series: <CartesianSeries<dynamic, dynamic>>[
                        LineSeries<WeeklyChartData, String>(
                          dataSource: viewModel.weeklyViewsData,
                          xValueMapper: (WeeklyChartData data, _) => data.date,
                          yValueMapper: (WeeklyChartData data, _) => data.views,
                          color: Colors.blue,
                          markerSettings: const MarkerSettings(isVisible: true),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart, double height = 300}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(child: chart),
          ],
        ),
      ),
    );
  }
}