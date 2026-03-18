import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// YZ düşünürken gösterilen iskelet yükleme ekranı
class SkeletonResultScreen extends StatelessWidget {
  const SkeletonResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2D2D34) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF3A3A42) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst başlık skeleton
            _buildSkeletonBox(height: 72, borderRadius: 16),
            const SizedBox(height: 20),
            // Radar grafik skeleton
            _buildSkeletonBox(height: 260, borderRadius: 16),
            const SizedBox(height: 16),
            // 4 kart skeleton
            for (int i = 0; i < 4; i++) ...[
              _buildSkeletonCard(),
              const SizedBox(height: 12),
            ],
            // Sonuç skeleton
            _buildSkeletonBox(height: 100, borderRadius: 16),
            const SizedBox(height: 16),
            // Oylama skeleton
            _buildSkeletonBox(height: 80, borderRadius: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox({required double height, double borderRadius = 12}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 140,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity * 0.8,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
