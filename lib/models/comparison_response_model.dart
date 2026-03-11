import 'dart:convert';

/// YZ'den dönen yapılandırılmış karşılaştırma yanıtı
class ComparisonResponseModel {
  final String comparisonType;
  final List<SummaryDifference>? summaryDifferences;
  final List<ComparisonCard> cards;
  final List<String> item1Pros;
  final List<String> item1Cons;
  final List<String> item2Pros;
  final List<String> item2Cons;
  final RadarData? radar;
  final String conclusion;
  final List<String> suggestedQuestions;

  ComparisonResponseModel({
    required this.comparisonType,
    this.summaryDifferences,
    required this.cards,
    this.item1Pros = const [],
    this.item1Cons = const [],
    this.item2Pros = const [],
    this.item2Cons = const [],
    this.radar,
    required this.conclusion,
    required this.suggestedQuestions,
  });

  factory ComparisonResponseModel.fromJson(Map<String, dynamic> json) {
    return ComparisonResponseModel(
      comparisonType: json['karsilastirma_tipi'] ?? 'Genel',
      summaryDifferences: (json['ozet_farklar'] as List<dynamic>?)
          ?.map((e) => SummaryDifference.fromJson(e as Map<String, dynamic>))
          .toList(),
      cards: (json['kartlar'] as List<dynamic>?)
              ?.map((e) => ComparisonCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      item1Pros: (json['item1_artilar'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      item1Cons: (json['item1_eksiler'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      item2Pros: (json['item2_artilar'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      item2Cons: (json['item2_eksiler'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      radar: json['radar'] != null
          ? RadarData.fromJson(json['radar'] as Map<String, dynamic>)
          : null,
      conclusion: json['sonuc'] ?? '',
      suggestedQuestions: (json['soru_onerileri'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Ham markdown'dan fallback oluştur (JSON parse başarısız olursa)
  factory ComparisonResponseModel.fromMarkdown(String markdown) {
    final sections = <ComparisonCard>[];
    final lines = markdown.split('\n');
    String currentTitle = '';
    final buffer = StringBuffer();

    for (final line in lines) {
      if (line.trim().startsWith('## ')) {
        if (currentTitle.isNotEmpty || buffer.isNotEmpty) {
          sections.add(ComparisonCard(
            title: currentTitle.isNotEmpty ? currentTitle : 'Analiz',
            content: buffer.toString().trim(),
            item1Score: null,
            item2Score: null,
            item1Strong: null,
          ));
          buffer.clear();
        }
        currentTitle = line.trim().replaceFirst('## ', '');
      } else {
        buffer.writeln(line);
      }
    }
    if (currentTitle.isNotEmpty || buffer.isNotEmpty) {
      sections.add(ComparisonCard(
        title: currentTitle.isNotEmpty ? currentTitle : 'Analiz',
        content: buffer.toString().trim(),
        item1Score: null,
        item2Score: null,
        item1Strong: null,
      ));
    }

    if (sections.isEmpty) {
      sections.add(ComparisonCard(
        title: 'Analiz',
        content: markdown,
        item1Score: null,
        item2Score: null,
        item1Strong: null,
      ));
    }

    return ComparisonResponseModel(
      comparisonType: 'Genel',
      summaryDifferences: null,
      cards: sections,
      item1Pros: [],
      item1Cons: [],
      item2Pros: [],
      item2Cons: [],
      radar: null,
      conclusion: '',
      suggestedQuestions: [],
    );
  }

  /// Ham YZ yanıtından parse et — önce JSON, başarısızsa markdown fallback
  static ComparisonResponseModel parse(String rawResponse) {
    // JSON bloğu bul (```json ... ``` veya düz JSON)
    String jsonStr = rawResponse;

    // ```json ... ``` formatını temizle
    final jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = jsonBlockRegex.firstMatch(rawResponse);
    if (match != null) {
      jsonStr = match.group(1)!;
    } else {
      // Düz JSON olabilir — { ile başlıyor mu kontrol et
      final trimmed = rawResponse.trim();
      if (!trimmed.startsWith('{')) {
        // Markdown fallback
        return ComparisonResponseModel.fromMarkdown(rawResponse);
      }
      jsonStr = trimmed;
    }

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ComparisonResponseModel.fromJson(decoded);
    } catch (_) {
      return ComparisonResponseModel.fromMarkdown(rawResponse);
    }
  }
}

/// Özet Farklar (Hızlı Karşılaştırma Tablosu İçin)
class SummaryDifference {
  final String feature;
  final String item1Value;
  final String item2Value;

  SummaryDifference({
    required this.feature,
    required this.item1Value,
    required this.item2Value,
  });

  factory SummaryDifference.fromJson(Map<String, dynamic> json) {
    return SummaryDifference(
      feature: json['ozellik'] ?? '',
      item1Value: json['item1_deger'] ?? '',
      item2Value: json['item2_deger'] ?? '',
    );
  }
}

/// Dinamik bir karşılaştırma kartı
class ComparisonCard {
  final String title;
  final String content;
  final int? item1Score;
  final int? item2Score;
  final bool? item1Strong; // true = item1 güçlü, false = item2 güçlü, null = eşit

  ComparisonCard({
    required this.title,
    required this.content,
    this.item1Score,
    this.item2Score,
    this.item1Strong,
  });

  factory ComparisonCard.fromJson(Map<String, dynamic> json) {
    return ComparisonCard(
      title: json['baslik'] ?? 'Kategori',
      content: json['icerik'] ?? '',
      item1Score: json['item1_puan'] as int?,
      item2Score: json['item2_puan'] as int?,
      item1Strong: json['item1_guclu'] as bool?,
    );
  }
}

/// Radar grafik verileri
class RadarData {
  final List<String> categories;
  final List<double> item1Scores;
  final List<double> item2Scores;

  RadarData({
    required this.categories,
    required this.item1Scores,
    required this.item2Scores,
  });

  factory RadarData.fromJson(Map<String, dynamic> json) {
    return RadarData(
      categories: (json['kategoriler'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      item1Scores: (json['item1_puanlar'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      item2Scores: (json['item2_puanlar'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }
}
