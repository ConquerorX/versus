import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/comparison_model.dart';
import '../../services/ai_service.dart';
import 'result_screen.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tüm Trendler',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Limit 50 trend gösterilecek
        stream: FirebaseFirestore.instance
            .collection('trends')
            .orderBy('count', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Bir hata oluştu.', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_down, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Henüz popüler bir karşılaştırma yok.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final item1 = data['item1'] as String? ?? '';
              final item2 = data['item2'] as String? ?? '';
              final count = (data['count'] ?? 0) as int;
              // intl paketi gerekmemesi için veritabanındaki son tarihi Date formatına el ile çevirme
              String dateStr = '';
              if (data['lastCompared'] != null) {
                final dt = (data['lastCompared'] as Timestamp).toDate();
                dateStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
              }

              return _buildTrendTile(
                context: context,
                item1: item1,
                item2: item2,
                count: count,
                rank: index + 1,
                dateStr: dateStr,
                isDark: isDark,
                primaryColor: primaryColor,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrendTile({
    required BuildContext context,
    required String item1,
    required String item2,
    required int count,
    required int rank,
    required String dateStr,
    required bool isDark,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () async {
        BuildContext? dialogContext;
        // Loading göster
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return Center(child: CircularProgressIndicator(color: primaryColor));
          },
        );

        // Veritabanından mevcut karşılaştırmayı bulmaya çalış
        final query1 = await FirebaseFirestore.instance.collection('comparisons')
            .where('item1', isEqualTo: item1)
            .where('item2', isEqualTo: item2)
            .limit(1)
            .get();
            
        QueryDocumentSnapshot? existingDoc;
        if (query1.docs.isNotEmpty) {
          existingDoc = query1.docs.first;
        } else {
          final query2 = await FirebaseFirestore.instance.collection('comparisons')
              .where('item1', isEqualTo: item2)
              .where('item2', isEqualTo: item1)
              .limit(1)
              .get();
          if (query2.docs.isNotEmpty) {
            existingDoc = query2.docs.first;
          }
        } // Missing brace added here

        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.pop(dialogContext!); // loading kapat
        } else if (context.mounted) {
          Navigator.pop(context);
        }
          
        if (context.mounted) {  
          if (existingDoc != null) {
            final data = existingDoc.data() as Map<String, dynamic>;
            final comp = ComparisonModel.fromMap(existingDoc.id, data);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ResultScreen(
                markdownResult: comp.result,
                item1Name: comp.item1,
                item2Name: comp.item2,
                autoSave: false, // Zaten kayıtlı
              ),
            ));
          } else {
            // Bulunamazsa yeni üret
            final future = AiService.analyzeComparison(item1Text: item1, item2Text: item2);
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ResultScreen(
                analysisFuture: future, item1Name: item1, item2Name: item2,
              ),
            ));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D34) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A42) : const Color(0xFFE8E4DF),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Ranking Badge
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? primaryColor.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: rank <= 3 ? primaryColor : Colors.grey[500],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$item1 vs $item2',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 14, color: const Color(0xFFC75B5B).withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(
                        '$count aranma',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
