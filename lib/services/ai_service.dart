import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _proxyUrl = 'https://ai-bot-proxy.e-duralemre.workers.dev';

  static Future<String> analyzeComparison({
    required String item1Text, 
    required String item2Text,
    String? item1ImageBase64,
    String? item2ImageBase64,
  }) async {
    final List<Map<String, dynamic>> parts = [];
    
    // Evrensel YZ Sistem Promtu — JSON yanıt formatı
    parts.add({
      "text": """Sen yetkin bir analiz uzmanısın. Görevin iki öğeyi (ürün, şehir, sporcu, platform, yayıncı, gıda, araç veya herhangi bir şey olabilir) kısa, öz ve profesyonel bir dille karşılaştırmaktır. Karşılaştırılan öğelerin ne olduğunu otomatik tespit et ve bağlama uygun kategoriler oluştur.

{
  "karsilastirma_tipi": "Teknoloji / Şehirler / Sporcular / Platformlar / Genel",
  "ozet_farklar": [
    {"ozellik": "En önemli fark 1", "item1_deger": "Kısa değer", "item2_deger": "Kısa değer"},
    {"ozellik": "En önemli fark 2", "item1_deger": "Kısa değer", "item2_deger": "Kısa değer"},
    {"ozellik": "En önemli fark 3", "item1_deger": "Kısa değer", "item2_deger": "Kısa değer"},
    {"ozellik": "En önemli fark 4", "item1_deger": "Kısa değer", "item2_deger": "Kısa değer"}
  ],
  "kartlar": [
    {
      "baslik": "Kategori Başlığı (bağlama göre dinamik)",
      "icerik": "Karşılaştırma içeriği. Markdown formatında yaz (madde işaretleri, kalın metin kullanabilirsin).",
      "item1_puan": 8,
      "item2_puan": 7,
      "item1_guclu": true
    }
  ],
  "item1_artilar": ["Artı 1", "Artı 2"],
  "item1_eksiler": ["Eksi 1", "Eksi 2"],
  "item2_artilar": ["Artı 1", "Artı 2"],
  "item2_eksiler": ["Eksi 1", "Eksi 2"],
  "radar": {
    "kategoriler": ["Kategori1", "Kategori2", "Kategori3", "Kategori4", "Kategori5", "Kategori6"],
    "item1_puanlar": [8, 7, 9, 6, 8, 7],
    "item2_puanlar": [6, 9, 7, 8, 7, 8]
  },
  "sonuc": "2-3 paragraflı detaylı, argümanlı ve analitik bir final değerlendirmesi (Senin Tercihin) yaz. Hangi öğenin kimin için, hangi senaryolarda daha uygun olduğunu net bir şekilde açıkla.",
  "soru_onerileri": ["Bağlama uygun soru 1?", "Bağlama uygun soru 2?", "Bağlama uygun soru 3?", "Bağlama uygun soru 4?", "Bağlama uygun soru 5?"]
}
```

Kurallar:
- "ozet_farklar" listesinde kesinlikle 4 veya 5 net ve çarpıcı fark belirt.
- "sonuc" kısmı doyurucu olmalı, sadece bir cümle olmamalı.
- Tam olarak 4-5 kart üret. Kart başlıkları karşılaştırma bağlamına göre dinamik olsun (örn: şehirler için "İklim ve Coğrafya", yayıncılar için "İçerik Tarzı", ürünler için "Teknik Özellikler").
- Puanlar 1-10 arasında olsun.
- Radar grafikte TAM OLARAK 6 kategori olsun (grafiğin altıgen çizilebilmesi için şarttır).
- 5 adet bağlama uygun soru önerisi ver.
- Emoji kullanma.
- Gereksiz detaydan kaçın.
- Yapay zeka klişeleri kullanma.
- Sadece JSON döndür, başka metin ekleme."""
    });

    // Item 1 eklentileri
    parts.add({
      "text": "1. Seçenek: $item1Text"
    });
    
    if (item1ImageBase64 != null) {
      parts.add({
        "inlineData": {
          "mimeType": "image/jpeg",
          "data": item1ImageBase64
        }
      });
    }

    // Item 2 eklentileri
    parts.add({
      "text": "2. Seçenek: $item2Text"
    });
    
    if (item2ImageBase64 != null) {
      parts.add({
        "inlineData": {
          "mimeType": "image/jpeg",
          "data": item2ImageBase64
        }
      });
    }

    final Map<String, dynamic> requestPayload = {
      "messages": [
        {
          "role": "user",
          "parts": parts,
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (decodedResponse['candidates'] != null && decodedResponse['candidates'].isNotEmpty) {
           return decodedResponse['candidates'][0]['content']['parts'][0]['text'] ?? "Hata: YZ bir yanıt döndürmedi.";
        }
        
        return "Yanit anlasilamadi.";
      } else {
        return "Sunucu hatasi oluştu: ${response.statusCode}\nDetay: ${response.body}";
      }
    } catch (e) {
      return "Baglanti hatasi: $e";
    }
  }

  /// Görseldeki öğeyi sadece isim olarak tanımlar
  static Future<String?> identifyImage({required String imageBase64}) async {
    final requestPayload = {
      "messages": [
        {
          "role": "user",
          "parts": [
            {
               "text": "You are the world's most advanced visual analysis, object recognition, and OCR system. What EXACTLY is the main element, device, vehicle, product, place, or person in this image? If the image contains legible text (brand, model code, version, etc.) or distinctive features such as camera lens configuration, evaluate it with PRECISION. Name products (especially technological devices) with the MOST UP-TO-DATE, MOST SPECIFIC, AND MOST COMPLETE model name possible (e.g., not just ‘iPhone’, but ‘iPhone 17 Pro Max’; not just ‘Samsung’, but ‘Samsung Galaxy S26 Ultra’; ‘PlayStation 5 Pro’). Only use the most well-known, complete, and official name. Use a clear name consisting of one or a few words. Do not use punctuation marks or long explanations. Provide answers in Turkish only."
            },
            {
               "inlineData": {
                 "mimeType": "image/jpeg",
                 "data": imageBase64
               }
            }
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedResponse['candidates'] != null && decodedResponse['candidates'].isNotEmpty) {
           final text = decodedResponse['candidates'][0]['content']['parts'][0]['text'] as String?;
           return text?.trim() ?? "Bilinmeyen Öğe";
        }
      }
    } catch (_) {}
    return null;
  }

  /// Sohbet devam ettirme - karşılaştırma bağlamında takip sorusu sor
  static Future<String> sendFollowUp({
    required List<Map<String, String>> conversationHistory,
    required String item1,
    required String item2,
  }) async {
    // Mesajları Gemini formatına çevir
    final messages = <Map<String, dynamic>>[];

    // Sistem bağlamını ilk mesaj olarak ekle
    messages.add({
      "role": "user",
      "parts": [
        {
          "text": "Sen bir karşılaştırma asistanısın. $item1 ve $item2 öğelerini karşılaştırdık. Kullanıcının bu karşılaştırma hakkındaki sorularını kısa ve öz yanıtla. Türkçe cevap ver. Emoji kullanma. Yapay zeka klişeleri kullanma."
        }
      ]
    });

    messages.add({
      "role": "model",
      "parts": [
        {"text": "Tamam, $item1 ve $item2 karşılaştırması hakkında sorularınızı yanıtlamaya hazırım."}
      ]
    });

    // Konuşma geçmişini ekle
    for (final msg in conversationHistory) {
      messages.add({
        "role": msg['role'] == 'user' ? 'user' : 'model',
        "parts": [{"text": msg['text']}]
      });
    }

    final requestPayload = {"messages": messages};

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['candidates'] != null && decoded['candidates'].isNotEmpty) {
          return decoded['candidates'][0]['content']['parts'][0]['text'] ?? "Yanıt alınamadı.";
        }
        return "Yanıt alınamadı.";
      } else {
        return "Sunucu hatası: ${response.statusCode}";
      }
    } catch (e) {
      return "Bağlantı hatası: $e";
    }
  }

  /// Tekil öğe hakkında detaylı bilgi/teknik özellikler al
  static Future<String> getItemDetails({required String itemName}) async {
    final parts = <Map<String, dynamic>>[];

    parts.add({
      "text": """$itemName hakkında kapsamlı ve detaylı bilgi ver. Markdown formatında yaz.

Eğer bu bir teknoloji ürünüyse teknik özelliklerini tablo halinde sun. Eğer bir şehir, sporcu, platform veya başka bir şeyse o bağlama uygun detaylı bilgiler ver.

Kurallar:
- Türkçe yaz.
- Emoji kullanma.
- Kapsamlı ama okunabilir ol.
- ## ile başlıklar kullan.
- Mümkünse tablo formatında teknik bilgiler sun."""
    });

    final requestPayload = {
      "messages": [
        {"role": "user", "parts": parts}
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['candidates'] != null && decoded['candidates'].isNotEmpty) {
          return decoded['candidates'][0]['content']['parts'][0]['text'] ?? "Bilgi alınamadı.";
        }
        return "Bilgi alınamadı.";
      } else {
        return "Sunucu hatası: ${response.statusCode}";
      }
    } catch (e) {
      return "Bağlantı hatası: $e";
    }
  }

  /// Sürpriz İkilem - Yapay Zekadan rastgele eğlenceli ikilem iste
  static Future<List<String>> generateRandomPair() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final parts = <Map<String, dynamic>>[];
    
    parts.add({
      "text": """Sen mantıklı ve ilgi çekici bir ürün/kavram karşılaştırma jeneratörüsün. Görevin, insanların gerçekten kıyaslamak isteyeceği, BİRBİRİYLE DOĞRUDAN REKABET EDEN veya YAKIN İLİŞKİLİ iki öğe önermektir (Örn: İki rakip telefon, iki popüler oyun, aynı segmentte iki araba, iki spor markası, vs).
      
LÜTFEN birbiriyle alakasız veya absürt şeyler önerme (Örn: "Kaktüs vs Balon" GİBİ MANASIZ ŞEYLER YASAK).
Mantıklı kategorilerden seç: Teknolojik cihazlar, uygulamalar, oyunlar, markalar, günlük eşyalar, tarihi karakterler vs. Her defasında farklı bir kategoriden popüler bir rekabet veya ikilem öner (Örn: biri iOS tabanlıysa diğeri Android).

ÖNEMLİ: Zaman Damgası [$timestamp]. Bu sayıyı görüyorsan, daha önce verdiğin cevapları UNUT ve her geldiğinde tamamen YENİ, FARKLI BİR REKABET çifti yolla. Hep aynı şeyleri (ChatGPT vs Claude gibi) üretmekten kesinlikle kaçın!

Yanıtın SADECE VE SADECE 'Öğe 1 || Öğe 2' formatında olmalıdır. Başka hiçbir açıklama, yorum, ek kelime veya noktalama işareti kesinlikle ekleme.

Örnekler:
PlayStation 5 Pro || Xbox Series X
Netflix || Amazon Prime Video
Spotify || Apple Music
Nike || Adidas
Harry Potter || Yüzüklerin Efendisi
McDonald's || Burger King
BMW || Mercedes-Benz"""
    });

    final requestPayload = {
      "messages": [
        {"role": "user", "parts": parts}
      ],
      // Yaratıcılığı artırmak için daha yüksek temperature ayarı (eğer backend destekliyorsa)
      "temperature": 0.9, 
    };

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['candidates'] != null && decoded['candidates'].isNotEmpty) {
          final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String?;
          if (text != null && text.contains('||')) {
            final split = text.split('||');
            if (split.length == 2) {
              return [split[0].trim(), split[1].trim()];
            }
          }
        }
      }
    } catch (_) {}
    
    // Hata durumunda statik listeye geri dön
    final fallbackPairs = [
      ['iOS', 'Android'],
      ['PlayStation 5', 'Xbox Series X'],
      ['Mercedes', 'BMW'],
      ['Netflix', 'Amazon Prime'],
      ['Nike', 'Adidas'],
      ['Spotify', 'Apple Music'],
      ['Fenerbahçe', 'Galatasaray'],
    ];
    fallbackPairs.shuffle();
    return fallbackPairs.first;
  }

  /// Kullanıcının girdiği öğe isimlerini düzelt/resmileştir
  /// Örn: "cs2" → "Counter-Strike 2", "elma" → "Elma"
  static Future<List<String>> correctItemNames({
    required String item1,
    required String item2,
  }) async {
    final parts = <Map<String, dynamic>>[];

    parts.add({
      "text": """Görevin iki öğenin isimlerini düzeltmek ve resmileştirmek. Kullanıcılar bazen kısaltma, yanlış yazım veya küçük harf kullanabilir.

Kurallar:
- Eğer bir kısaltma veya lakap ise tam resmi adını yaz (örn: "cs2" → "Counter-Strike 2", "lol" → "League of Legends", "yt" → "YouTube")
- Eğer düz bir kelime ise sadece baş harfini büyük yap (örn: "elma" → "Elma", "muz" → "Muz")
- Eğer zaten doğru yazılmışsa aynen bırak
- Eğer bir marka/ürün ise resmi yazımını kullan (örn: "iphone" → "iPhone", "macbook" → "MacBook")

Yanıtın SADECE VE SADECE 'DüzeltilmişAd1 || DüzeltilmişAd2' formatında olmalıdır. Başka hiçbir şey ekleme.

Girdi: $item1 || $item2"""
    });

    final requestPayload = {
      "messages": [
        {"role": "user", "parts": parts}
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded['candidates'] != null && decoded['candidates'].isNotEmpty) {
          final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String?;
          if (text != null && text.contains('||')) {
            final split = text.split('||');
            if (split.length == 2) {
              return [split[0].trim(), split[1].trim()];
            }
          }
        }
      }
    } catch (_) {}

    // Hata durumunda en azından baş harfleri büyüt
    return [
      item1.isNotEmpty ? item1[0].toUpperCase() + item1.substring(1) : item1,
      item2.isNotEmpty ? item2[0].toUpperCase() + item2.substring(1) : item2,
    ];
  }
}
