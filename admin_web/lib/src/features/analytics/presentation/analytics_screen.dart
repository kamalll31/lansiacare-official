import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:admin_web/src/features/analytics/view_models/analytics_view_model.dart';
import 'package:admin_web/src/shared/widgets/app_drawer.dart';
import 'package:admin_web/src/shared/widgets/custom_app_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data otomatis saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsViewModel>().fetchAllAnalytics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Laporan & Analitik',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Perbarui Data',
                onPressed: () => viewModel.fetchAllAnalytics(),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.error != null
                  ? Center(child: Text('Error: ${viewModel.error}'))
                  : _buildScrollableContent(viewModel),
        );
      },
    );
  }

  Widget _buildScrollableContent(AnalyticsViewModel viewModel) {
    // Helper safe access untuk nested map
    final stats = viewModel.summaryStats;
    final users = stats['users'] as Map? ?? {};
    final content = stats['content'] as Map? ?? {};
    final emergency = stats['emergency'] as Map? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. HEADER CARDS (Summary) ---
          Row(
            children: [
              _buildSummaryCard(
                'Total Pengguna',
                '${users['total'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Total Konten',
                '${content['total_articles'] ?? 0}',
                Icons.article,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'SOS (24 Jam)',
                '${emergency['sos_last_24h'] ?? 0}',
                Icons.warning_amber_rounded,
                Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // --- 2. ROW GRAFIK 1 (User & Emergency) ---
          SizedBox(
            height: 350, // Fixed height untuk row grafik
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // GRAFIK 1: Komposisi User (Pie Chart)
                Expanded(
                  flex: 1,
                  child: _buildChartCard(
                    title: 'Komposisi User',
                    chart: SfCircularChart(
                      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                      series: <CircularSeries>[
                        DoughnutSeries<ChartData, String>(
                          dataSource: viewModel.userRoleDistribution,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          pointColorMapper: (ChartData data, _) => data.color,
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                          enableTooltip: true,
                        )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // GRAFIK 2: Konten Terpopuler (Bar Chart)
                // Menggantikan Line Chart karena data backend adalah Top Content
                Expanded(
                  flex: 2, // Lebih lebar
                  child: _buildChartCard(
                    title: 'Konten Terpopuler (Top 5)',
                    chart: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(
                        labelStyle: TextStyle(fontSize: 10), // Font kecil agar muat
                      ),
                      primaryYAxis: const NumericAxis(
                        title: AxisTitle(text: 'Views'),
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries<ContentPerformanceData, String>>[
                        BarSeries<ContentPerformanceData, String>(
                          dataSource: viewModel.topContent,
                          xValueMapper: (ContentPerformanceData data, _) => 
                              data.title.length > 15 ? '${data.title.substring(0, 15)}...' : data.title,
                          yValueMapper: (ContentPerformanceData data, _) => data.views,
                          name: 'Views',
                          color: Colors.purple,
                          dataLabelSettings: const DataLabelSettings(isVisible: true),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              Flexible( // Agar text wrap jika layar sempit
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
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