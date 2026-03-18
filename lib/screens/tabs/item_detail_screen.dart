import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/ai_service.dart';

/// Öğe detay ekranı — teknik özellikler için YZ'den bilgi al
class ItemDetailScreen extends StatefulWidget {
  final String itemName;
  final String otherItemName; // karşılaştırılan diğer öğe

  const ItemDetailScreen({
    super.key,
    required this.itemName,
    required this.otherItemName,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  String? _details;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final response = await AiService.getItemDetails(itemName: widget.itemName);
    if (mounted) {
      setState(() {
        _details = response;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemName),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Bilgiler yükleniyor...', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst başlık
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.itemName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('Detaylı Bilgi',
                                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // İçerik
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2D34) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!,
                      ),
                    ),
                    child: MarkdownBody(
                      data: _details ?? 'Bilgi alınamadı.',
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 14, height: 1.7,
                          color: isDark ? Colors.grey[300] : Colors.grey[700]),
                        strong: TextStyle(fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF2D2D34)),
                        h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF2D2D34)),
                        listBullet: TextStyle(fontSize: 14,
                          color: isDark ? Colors.grey[300] : Colors.grey[700]),
                        listIndent: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
