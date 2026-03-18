import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/comparison_response_model.dart';

/// Karşılaştırma radar grafiği widget'ı
class ComparisonRadarChart extends StatelessWidget {
  final RadarData radarData;
  final String item1Name;
  final String item2Name;

  const ComparisonRadarChart({
    super.key,
    required this.radarData,
    required this.item1Name,
    required this.item2Name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    // Renk skalasının karışmasını önlemek için Item 2 için zıt bir tertiary/sabit renk seçimi
    final secondaryColor = theme.colorScheme.tertiary.value != 0 
        ? theme.colorScheme.tertiary 
        : const Color(0xFF5B8A72); // Fallback yeşil tone

    if (radarData.categories.isEmpty || 
        radarData.item1Scores.isEmpty || 
        radarData.item2Scores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D34) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.radar, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Puan Karşılaştırması',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarTouchData: RadarTouchData(enabled: false),
                dataSets: [
                  RadarDataSet(
                    fillColor: primaryColor.withValues(alpha: 0.2),
                    borderColor: primaryColor,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: radarData.item1Scores
                        .map((e) => RadarEntry(value: e))
                        .toList(),
                  ),
                  RadarDataSet(
                    fillColor: secondaryColor.withValues(alpha: 0.2),
                    borderColor: secondaryColor,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: radarData.item2Scores
                        .map((e) => RadarEntry(value: e))
                        .toList(),
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(
                  color: isDark ? const Color(0xFF3A3A42) : Colors.grey[300]!,
                  width: 1.5,
                ),
                titlePositionPercentageOffset: 0.20,
                titleTextStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                getTitle: (index, angle) {
                  if (index < radarData.categories.length) {
                    return RadarChartTitle(
                      text: radarData.categories[index],
                    );
                  }
                  return const RadarChartTitle(text: '');
                },
                tickCount: 5,
                ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
                tickBorderData: BorderSide(
                  color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!,
                  width: 0.5,
                ),
                gridBorderData: BorderSide(
                  color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              Expanded(child: _buildLegendDot(primaryColor, item1Name)),
              const SizedBox(width: 10),
              Expanded(child: _buildLegendDot(secondaryColor, item2Name)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
