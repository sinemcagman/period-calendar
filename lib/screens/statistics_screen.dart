import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CycleProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                AppStrings.statsTitle,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandPink.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, color: AppColors.brandPink),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.statusSummary, 
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.cycles.length > 2 ? AppStrings.cycleRegular : "Yeterli veri yok.", 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Line Chart Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.cycleLengthAnalysis, 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: _buildLineChart(provider),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.monthAverage.replaceAll('{days}', '${provider.averageCycleLength}'), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                        Text(AppStrings.monthShortest.replaceAll('{days}', '${_getShortestCycle(provider)}'), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                        Text(AppStrings.monthLongest.replaceAll('{days}', '${_getLongestCycle(provider)}'), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pie Chart Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.frequentSymptoms, 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: _buildPieChart(provider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  int _getShortestCycle(CycleProvider provider) {
    if (provider.cycles.length < 2) return 0;
    int shortest = 999;
    for (int i = 0; i < provider.cycles.length - 1; i++) {
       int diff = provider.cycles[i].startDate.difference(provider.cycles[i+1].startDate).inDays;
       if (diff < shortest) shortest = diff;
    }
    return shortest == 999 ? 0 : shortest;
  }

  int _getLongestCycle(CycleProvider provider) {
    if (provider.cycles.length < 2) return 0;
    int longest = 0;
    for (int i = 0; i < provider.cycles.length - 1; i++) {
       int diff = provider.cycles[i].startDate.difference(provider.cycles[i+1].startDate).inDays;
       if (diff > longest) longest = diff;
    }
    return longest;
  }

  Widget _buildLineChart(CycleProvider provider) {
    if (provider.cycles.length < 2) {
      return Center(child: Text('Çizgi grafik için yeterli döngü verisi yok', style: TextStyle(color: Colors.grey.shade600)));
    }

    // Get last 6 cycle lengths (or less)
    List<FlSpot> spots = [];
    List<String> months = [];
    int limit = provider.cycles.length - 1;
    if (limit > 6) limit = 6;
    
    int minLen = 999;
    int maxLen = 0;

    for (int i = limit - 1; i >= 0; i--) {
      // cycles are ordered by date DESC
      // index 0 is the current/latest cycle. index 1 is previous. Length is diff btn index 0 and 1.
      int diff = provider.cycles[i].startDate.difference(provider.cycles[i+1].startDate).inDays;
      spots.add(FlSpot((limit - 1 - i).toDouble(), diff.toDouble()));
      months.add('${provider.cycles[i+1].startDate.month}/${provider.cycles[i+1].startDate.year}');
      
      if (diff < minLen) minLen = diff;
      if (diff > maxLen) maxLen = diff;
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: AppColors.borderDark, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if(index >= 0 && index < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(months[index], style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10));
              },
              reservedSize: 28,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: (minLen - 3).toDouble(),
        maxY: (maxLen + 3).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.brandPink,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.brandPink.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(CycleProvider provider) {
    if (provider.dailyLogs.isEmpty) {
      return Center(child: Text('Pasta grafik için günlük veri yok', style: TextStyle(color: Colors.grey.shade600)));
    }

    Map<String, int> symptomCounts = {};
    int totalSymptomsLogged = 0;

    for (var log in provider.dailyLogs) {
      for (var sym in log.physicalSymptoms) {
        symptomCounts[sym] = (symptomCounts[sym] ?? 0) + 1;
        totalSymptomsLogged++;
      }
    }

    if (totalSymptomsLogged == 0) {
      return Center(child: Text('Hiç belirti kaydedilmemiş', style: TextStyle(color: Colors.grey.shade600)));
    }

    // Sort by frequency
    var sortedEntries = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Color> pieColors = [
      const Color(0xFFEC4899),
      const Color(0xFFA855F7),
      const Color(0xFF3B82F6),
      const Color(0xFF64748B),
      const Color(0xFFEAB308),
    ];

    List<PieChartSectionData> sections = [];
    List<Widget> legendWidgets = [];

    int count = sortedEntries.length > 5 ? 5 : sortedEntries.length;
    for (int i = 0; i < count; i++) {
        double percentage = (sortedEntries[i].value / totalSymptomsLogged) * 100;
        sections.add(PieChartSectionData(
          color: pieColors[i],
          value: percentage,
          title: '',
          radius: 25,
        ));
        
        legendWidgets.add(_buildLegend(sortedEntries[i].key, pieColors[i], '${percentage.round()}%'));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: legendWidgets,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          Text(percent, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
