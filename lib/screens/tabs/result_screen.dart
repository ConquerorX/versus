import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/haptic_feedback_service.dart';
import '../../services/sound_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/comparison_model.dart';
import '../../models/comparison_response_model.dart';
import '../../widgets/radar_chart_widget.dart';
import '../../widgets/community_vote_widget.dart';
import '../../widgets/skeleton_loading.dart';
import 'chat_screen.dart';
import 'item_detail_screen.dart';

class ResultScreen extends StatefulWidget {
  final String? markdownResult;
  final Future<String>? analysisFuture;
  final String item1Name;
  final String item2Name;
  final bool autoSave;

  const ResultScreen({
    super.key,
    this.markdownResult,
    this.analysisFuture,
    required this.item1Name,
    required this.item2Name,
    this.autoSave = true,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saved = false;
  String? _rawResult;
  ComparisonResponseModel? _parsedResult;
  bool _isLoading = false;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    if (widget.markdownResult != null) {
      _rawResult = widget.markdownResult;
      _parsedResult = ComparisonResponseModel.parse(_rawResult!);
      if (widget.autoSave) _autoSaveToFirestore();
    } else if (widget.analysisFuture != null) {
      _isLoading = true;
      widget.analysisFuture!.then((result) {
        if (mounted) {
          setState(() {
            _rawResult = result;
            _parsedResult = ComparisonResponseModel.parse(result);
            _isLoading = false;
          });
          HapticService.success();
          SoundService.playSuccess();
          if (widget.autoSave) _autoSaveToFirestore();
        }
      });
    }
  }

  Future<void> _autoSaveToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _rawResult == null) return;
    try {
      final comparison = ComparisonModel(
        item1: widget.item1Name,
        item2: widget.item2Name,
        result: _rawResult!,
        userId: user.uid,
        createdAt: DateTime.now(),
        comparisonType: _parsedResult?.comparisonType,
      );
      await FirebaseFirestore.instance.collection('comparisons').add(comparison.toMap());

      // Trend takibi — anonim karşılaştırma sayacı
      _trackTrend();

      if (mounted) {
        setState(() {
          _saved = true;
        });
      }
    } catch (_) {}
  }

  /// Trend koleksiyonunda bu karşılaştırmayı say
  Future<void> _trackTrend() async {
    final trendKey = _normalizeTrendKey(widget.item1Name, widget.item2Name);
    
    try {
      await FirebaseFirestore.instance.collection('trends').doc(trendKey).set({
        'item1': widget.item1Name,
        'item2': widget.item2Name,
        'count': FieldValue.increment(1),
        'lastCompared': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  String _normalizeTrendKey(String a, String b) {
    // Sıralama yaparak her iki sırayı da aynı belgeye yönlendir
    final sorted = [a.trim().toLowerCase(), b.trim().toLowerCase()]..sort();
    return '${sorted[0]}_vs_${sorted[1]}'.replaceAll(' ', '_');
  }

  void _shareAsText() {
    if (_parsedResult == null) return;
    HapticFeedback.lightImpact();
    final buffer = StringBuffer();
    buffer.writeln('${widget.item1Name} vs ${widget.item2Name}\n');
    
    for (final card in _parsedResult!.cards) {
      buffer.writeln('🔸 ${card.title.toUpperCase()}');
      final cleanContent = card.content.replaceAll(RegExp(r'\*\*|\*|#'), '').trim();
      buffer.writeln(cleanContent);
      if (card.item1Score != null && card.item2Score != null) {
        buffer.writeln('Puanlar: ${widget.item1Name} (${card.item1Score}) - ${widget.item2Name} (${card.item2Score})');
      }
      buffer.writeln();
    }
    
    if (_parsedResult!.conclusion.isNotEmpty) {
      buffer.writeln('💡 SONUÇ');
      final cleanConclusion = _parsedResult!.conclusion.replaceAll(RegExp(r'\*\*|\*|#'), '').trim();
      buffer.writeln(cleanConclusion);
      buffer.writeln();
    }
    
    buffer.writeln('— AI Karşılaştır ile analiz edildi');
    
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          item1Name: widget.item1Name,
          item2Name: widget.item2Name,
          initialContext: _rawResult,
          suggestedQuestions: _parsedResult?.suggestedQuestions ?? [],
        ),
      ),
    );
  }

  void _openItemDetail(String itemName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          itemName: itemName,
          otherItemName: itemName == widget.item1Name ? widget.item2Name : widget.item1Name,
        ),
      ),
    );
  }

  // Dinamik ikon eşleştirme
  IconData _getIconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('fiyat') || lower.contains('maliyet') || lower.contains('ücret') || lower.contains('bütçe')) return Icons.payments_outlined;
    if (lower.contains('performans') || lower.contains('hız') || lower.contains('güç')) return Icons.speed;
    if (lower.contains('tasarım') || lower.contains('görünüm') || lower.contains('estetik')) return Icons.palette_outlined;
    if (lower.contains('kamera') || lower.contains('fotoğraf') || lower.contains('görüntü')) return Icons.camera_alt_outlined;
    if (lower.contains('batarya') || lower.contains('pil') || lower.contains('şarj')) return Icons.battery_charging_full;
    if (lower.contains('ekran') || lower.contains('displesy') || lower.contains('çözünürlük')) return Icons.smartphone;
    if (lower.contains('iklim') || lower.contains('hava') || lower.contains('coğrafya')) return Icons.wb_sunny_outlined;
    if (lower.contains('kültür') || lower.contains('yaşam') || lower.contains('eğlence')) return Icons.theater_comedy;
    if (lower.contains('yemek') || lower.contains('mutfak') || lower.contains('gıda')) return Icons.restaurant;
    if (lower.contains('ulaşım') || lower.contains('trafik') || lower.contains('toplu taşıma')) return Icons.directions_bus;
    if (lower.contains('kitle') || lower.contains('takipçi') || lower.contains('izleyici')) return Icons.people_outline;
    if (lower.contains('içerik') || lower.contains('tarz') || lower.contains('format')) return Icons.movie_outlined;
    if (lower.contains('özellik') || lower.contains('fonksiyon') || lower.contains('teknik')) return Icons.settings_outlined;
    if (lower.contains('güvenlik') || lower.contains('gizlilik') || lower.contains('mahremiyet')) return Icons.security;
    if (lower.contains('kariyer') || lower.contains('başarı') || lower.contains('istatistik')) return Icons.emoji_events_outlined;
    if (lower.contains('eğitim') || lower.contains('akademik')) return Icons.school_outlined;
    if (lower.contains('sağlık') || lower.contains('spor') || lower.contains('fizik')) return Icons.fitness_center;
    if (lower.contains('kilit') || lower.contains('fark') || lower.contains('karşılaştırma')) return Icons.compare_arrows;
    if (lower.contains('analiz') || lower.contains('sonuç') || lower.contains('değerlendirme')) return Icons.analytics_outlined;
    return Icons.article_outlined;
  }

  Color _getColorForIndex(int index, Color primaryColor, Color secondaryColor) {
    final colors = [
      primaryColor, // Copper
      const Color(0xFF8B9298), // Muted Slate
      const Color(0xFF5B8A72), // Sage Green (Positive)
      const Color(0xFFC75B5B), // Muted Red (Negative)
      const Color(0xFF9E8B7E), // Warm Greige
      const Color(0xFF6B7A8F), // Dusky Blue
      const Color(0xFFD4B59E), // Light Copper
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.tertiary.value != 0 
        ? theme.colorScheme.tertiary 
        : const Color(0xFF5B8A72);

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_parsedResult?.comparisonType != null
              ? '${_parsedResult!.comparisonType} Karşılaştırması'
              : 'Karşılaştırma Sonucu'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _rawResult != null ? _shareAsText : null,
            tooltip: 'Paylaş',
          ),
          const SizedBox(width: 4),
        ],
      ),
      // Sohbet FAB — sağ alt köşede küçük buton
      floatingActionButton: (!_isLoading && _parsedResult != null)
          ? FloatingActionButton(
              onPressed: _openChat,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
              ),
            )
          : null,
      body: _isLoading
          ? const SkeletonResultScreen()
          : _parsedResult != null
              ? _buildMainContent(isDark, primaryColor, secondaryColor)
              : const Center(child: Text('Bir hata oluştu.')),
    );
  }

  Widget _buildMainContent(bool isDark, Color primaryColor, Color secondaryColor) {
    final parsed = _parsedResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst başlık
          _buildHeader(isDark, primaryColor, secondaryColor),
          const SizedBox(height: 12),

          // Öğe detay butonları
          _buildItemDetailButtons(isDark, primaryColor, secondaryColor),
          const SizedBox(height: 16),

          // Radar grafik
          if (parsed.radar != null && parsed.radar!.categories.isNotEmpty)
            ...[
              ComparisonRadarChart(
                radarData: parsed.radar!,
                item1Name: widget.item1Name,
                item2Name: widget.item2Name,
              ),
              const SizedBox(height: 12),
            ],

          // Özet Farklar
          if (parsed.summaryDifferences != null && parsed.summaryDifferences!.isNotEmpty)
            ...[
              _buildSummaryDifferences(parsed.summaryDifferences!, isDark, primaryColor, secondaryColor),
              const SizedBox(height: 12),
            ],

          // Dinamik kartlar
          ...parsed.cards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            final color = _getColorForIndex(index, primaryColor, secondaryColor);
            final icon = _getIconForTitle(card.title);
            return _buildAnimatedCard(card, icon, color == const Color(0xFFC8956C) ? primaryColor : (color == const Color(0xFF5B8A72) ? secondaryColor : color), isDark, index, primaryColor, secondaryColor);
          }),

          // Artılar & Eksiler
          if (parsed.item1Pros.isNotEmpty || parsed.item2Pros.isNotEmpty)
            ...[
              const SizedBox(height: 12),
              _buildProsCons(parsed, isDark, primaryColor, secondaryColor),
              const SizedBox(height: 12),
            ],

          // Kazanan Özeti (Eğer puanlar varsa)
          _buildWinnerSummary(parsed, isDark, primaryColor, secondaryColor),

          // Sonuç kartı
          if (parsed.conclusion.isNotEmpty)
            _buildConclusionCard(parsed.conclusion, isDark, secondaryColor),

          // Puanlama & Geri Bildirim
          const SizedBox(height: 12),
          _buildFeedbackSection(isDark, primaryColor, secondaryColor),

          // Topluluk oylaması — her zaman göster
          const SizedBox(height: 12),
          CommunityVoteWidget(
            item1: widget.item1Name,
            item2: widget.item2Name,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor, Color secondaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yapay Zeka Analizi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${widget.item1Name} vs ${widget.item2Name}',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (_saved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Kayıtlı', style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Öğe detay butonları — tıklayınca teknik özellik ekranına git
  Widget _buildItemDetailButtons(bool isDark, Color primaryColor, Color secondaryColor) {
    return Row(
      children: [
        Expanded(
          child: _itemDetailCard(widget.item1Name, primaryColor, isDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _itemDetailCard(widget.item2Name, const Color(0xFF8B9298), isDark),
        ),
      ],
    );
  }

  Widget _itemDetailCard(String name, Color color, bool isDark) {
    return GestureDetector(
      onTap: () => _openItemDetail(name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D34) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.info_outline, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCard(ComparisonCard card, IconData icon, Color color, bool isDark, Color primaryColor, Color secondaryColor) {
    // Semantik renklendirme
    Color? bgTint;
    if (card.item1Strong == true) {
      bgTint = const Color(0xFF5B8A72).withValues(alpha: 0.04);
    } else if (card.item1Strong == false) {
      bgTint = const Color(0xFFC75B5B).withValues(alpha: 0.04);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgTint ?? (isDark ? const Color(0xFF2D2D34) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.item1Strong == true
              ? const Color(0xFF5B8A72).withValues(alpha: 0.2)
              : card.item1Strong == false
                  ? const Color(0xFFC75B5B).withValues(alpha: 0.2)
                  : (isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Text(card.title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              ),
              // Puan göstergesi
              if (card.item1Score != null && card.item2Score != null)
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: _buildScoreBadges(card.item1Score!, card.item2Score!, primaryColor, secondaryColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: card.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 14, height: 1.6,
                color: isDark ? Colors.grey[300] : Colors.grey[700]),
              strong: TextStyle(fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF2D2D34)),
              listBullet: TextStyle(fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700]),
              listIndent: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(ComparisonCard card, IconData icon, Color color, bool isDark, int index, Color primaryColor, Color secondaryColor) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 150).clamp(0, 600)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildDynamicCard(card, icon, color, isDark, primaryColor, secondaryColor),
    );
  }

  Widget _buildScoreBadges(int score1, int score2, Color primaryColor, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(child: Text(widget.item1Name, style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1)),
            const SizedBox(width: 8),
            _scoreBar(score1, primaryColor),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(child: Text(widget.item2Name, style: TextStyle(fontSize: 10, color: secondaryColor, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1)),
            const SizedBox(width: 8),
            _scoreBar(score2, secondaryColor),
          ],
        ),
      ],
    );
  }

  Widget _scoreBar(int score, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 50 * (score / 10),
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 20,
          child: Text(
            '$score',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildConclusionCard(String conclusion, bool isDark, Color secondaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            secondaryColor.withValues(alpha: isDark ? 0.1 : 0.05),
            secondaryColor.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: secondaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.psychology, color: secondaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Senin Tercihin',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: secondaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: conclusion,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(fontSize: 14, height: 1.6,
                color: isDark ? Colors.grey[300] : Colors.grey[700]),
              strong: TextStyle(fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF2D2D34)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDifferences(List<SummaryDifference> diffs, bool isDark, Color primaryColor, Color secondaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D34) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.flash_on, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Öne Çıkan Farklar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          ...diffs.map((diff) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D34) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  diff.feature.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w800, 
                    color: isDark ? Colors.grey[500] : Colors.grey[500], 
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        diff.item1Value, 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor), 
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3A42) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.compare_arrows_rounded, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    Expanded(
                      child: Text(
                        diff.item2Value, 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: secondaryColor), 
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildProsCons(ComparisonResponseModel parsed, bool isDark, Color primaryColor, Color secondaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildProsConsCard(widget.item1Name, parsed.item1Pros, parsed.item1Cons, primaryColor, isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildProsConsCard(widget.item2Name, parsed.item2Pros, parsed.item2Cons, secondaryColor, isDark),
        ),
      ],
    );
  }

  Widget _buildProsConsCard(String itemName, List<String> pros, List<String> cons, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D34) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(itemName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 12),
          if (pros.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.add_circle, color: Color(0xFF5B8A72), size: 14),
                SizedBox(width: 6),
                Text('Artılar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B8A72))),
              ],
            ),
            const SizedBox(height: 6),
            ...pros.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 16),
              child: Text('• $p', style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[700])),
            )),
            const SizedBox(height: 12),
          ],
          if (cons.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.remove_circle, color: Color(0xFFC75B5B), size: 14),
                SizedBox(width: 6),
                Text('Eksiler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC75B5B))),
              ],
            ),
            const SizedBox(height: 6),
            ...cons.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 16),
              child: Text('• $c', style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[700])),
            )),
          ]
        ],
      ),
    );
  }

  Widget _buildWinnerSummary(ComparisonResponseModel parsed, bool isDark, Color primaryColor, Color secondaryColor) {
    int score1 = 0;
    int score2 = 0;
    int ratedCards = 0;

    for (var card in parsed.cards) {
      if (card.item1Score != null && card.item2Score != null) {
        score1 += card.item1Score!;
        score2 += card.item2Score!;
        ratedCards++;
      }
    }

    if (ratedCards == 0) return const SizedBox();

    String winnerName;
    Color winnerColor;
    String text;

    if (score1 > score2) {
      winnerName = widget.item1Name;
      winnerColor = primaryColor;
      text = 'Kategorilerde gösterdiği genel performans ile $winnerName öne çıkıyor.';
    } else if (score2 > score1) {
      winnerName = widget.item2Name;
      winnerColor = secondaryColor;
      text = 'Kategorilerde gösterdiği genel performans ile $winnerName öne çıkıyor.';
    } else {
      winnerName = 'Berabere';
      winnerColor = const Color(0xFF8B9298);
      text = 'Her iki öğe de birbirine oldukça yakın performans gösteriyor.';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: winnerColor.withValues(alpha: isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: winnerColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: winnerColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: winnerColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KAZANAN: ${winnerName.toUpperCase()}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: winnerColor)),
                  const SizedBox(height: 4),
                  Text(text,
                    style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[800])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text('$score1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryColor)),
                Text(' - ', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                Text('$score2', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: secondaryColor)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(bool isDark, Color primaryColor, Color secondaryColor) {
    if (_hasVoted) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D34) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text('Bu analizi faydalı buldunuz mu?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : Colors.grey[800])),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _feedbackButton(Icons.thumb_up_alt_outlined, 'Evet', secondaryColor, isDark),
              const SizedBox(width: 16),
              _feedbackButton(Icons.thumb_down_alt_outlined, 'Hayır', const Color(0xFFC75B5B), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feedbackButton(IconData icon, String label, Color color, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        setState(() {
          _hasVoted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geri bildiriminiz için teşekkürler!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
