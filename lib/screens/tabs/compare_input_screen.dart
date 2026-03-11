import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/ai_service.dart';
import '../../models/comparison_model.dart';
import '../../services/haptic_feedback_service.dart';
import '../../services/sound_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import 'result_screen.dart';

// Genişletilmiş öneri listesi (evrensel)
const _popularSuggestions = [
  // Teknoloji Ürünleri
  'iPhone 17 Pro', 'iPhone 17 Pro Max', 'iPhone 17', 'iPhone 16 Pro', 'iPhone 16 Pro Max',
  'iPhone 16', 'iPhone 15 Pro', 'iPhone 15', 'iPhone 14 Pro', 'iPhone SE',
  'Samsung Galaxy S26 Ultra', 'Samsung Galaxy S26', 'Samsung Galaxy S25 Ultra', 'Samsung Galaxy S25',
  'Samsung Galaxy S24 Ultra', 'Samsung Galaxy S24', 'Samsung Galaxy Z Fold 6', 'Samsung Galaxy Z Flip 6',
  'Samsung Galaxy A55', 'Samsung Galaxy A35',
  'Google Pixel 10 Pro', 'Google Pixel 10', 'Google Pixel 9 Pro', 'Google Pixel 9',
  'OnePlus 13', 'OnePlus 12', 'OnePlus Nord 4',
  'Xiaomi 15 Ultra', 'Xiaomi 15 Pro', 'Xiaomi 15', 'Xiaomi 14 Ultra', 'Xiaomi Redmi Note 14 Pro',
  'MacBook Pro M4', 'MacBook Air M4', 'MacBook Air M3',
  'Dell XPS 16', 'Dell XPS 14', 'Dell XPS 13',
  'iPad Pro M4', 'iPad Air M3', 'iPad mini 7',
  'PlayStation 5 Pro', 'PlayStation 5', 'Xbox Series X', 'Nintendo Switch 2',
  'Apple Watch Ultra 3', 'Apple Watch Series 10',
  'Sony WH-1000XM6', 'Sony WH-1000XM5',
  'Apple AirPods Pro 3', 'Apple AirPods Pro 2',
  'Tesla Model 3', 'Tesla Model Y', 'Tesla Model S',
  'BYD Seal', 'Togg T10X', 'Togg T10F',
  // Platformlar
  'Telegram', 'WhatsApp', 'Signal', 'Discord', 'Slack',
  'Netflix', 'Disney+', 'Amazon Prime Video', 'HBO Max', 'Apple TV+',
  'Spotify', 'Apple Music', 'YouTube Music', 'Tidal',
  'Instagram', 'TikTok', 'YouTube', 'Twitter/X', 'Threads',
  'ChatGPT', 'Google Gemini', 'Claude', 'Copilot',
  // Sporcular
  'Cristiano Ronaldo', 'Lionel Messi', 'Kylian Mbappe', 'Erling Haaland',
  'LeBron James', 'Stephen Curry', 'Nikola Jokic',
  'Novak Djokovic', 'Carlos Alcaraz', 'Rafael Nadal',
  // Şehirler
  'İstanbul', 'Ankara', 'İzmir', 'Antalya', 'Bursa',
  'Londra', 'Paris', 'Berlin', 'Madrid', 'Roma',
  'New York', 'Tokyo', 'Dubai', 'Barselona',
  'Mardin', 'Trabzon', 'Bodrum', 'Kapadokya',
  // Yayıncılar
  'Elraenn', 'Rraene', 'Enes Batur', 'Berkcan Güven', 'Pqueen',
  'MrBeast', 'PewDiePie', 'Pokimane',
];

class CompareInputScreen extends StatefulWidget {
  const CompareInputScreen({super.key});

  @override
  State<CompareInputScreen> createState() => _CompareInputScreenState();
}

class _CompareInputScreenState extends State<CompareInputScreen> {
  final _item1Ctrl = TextEditingController();
  final _item2Ctrl = TextEditingController();

  File? _image1;
  File? _image2;

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _item1Ctrl.dispose();
    _item2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int itemIndex, ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        if (itemIndex == 1) {
          _image1 = File(pickedFile.path);
        } else {
          _image2 = File(pickedFile.path);
        }
      });
      _identifySelectedImage(itemIndex, pickedFile.path);
    }
  }

  Future<void> _identifySelectedImage(int itemIndex, String path) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Görsel analiz ediliyor...'), duration: Duration(seconds: 2)),
    );
    setState(() => _isLoading = true);
    
    try {
      final base64Image = base64Encode(await File(path).readAsBytes());
      final identifiedName = await AiService.identifyImage(imageBase64: base64Image);
      
      if (identifiedName != null && identifiedName.isNotEmpty && identifiedName != "Bilinmeyen Öğe") {
        if (mounted) {
          setState(() {
            if (itemIndex == 1) {
              _item1Ctrl.text = identifiedName;
            } else {
              _item2Ctrl.text = identifiedName;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Görsel Tanındı: $identifiedName'), duration: const Duration(seconds: 2)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Görsel anlaşılamadı. Lütfen ismini elle yazın.')),
          );
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showImageOptions(int itemIndex) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                title: const Text('Fotoğraf Çek', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(itemIndex, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.secondary, size: 20),
                ),
                title: const Text('Galeriden Seç', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(itemIndex, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeItems() async {
    if (_item1Ctrl.text.trim().isEmpty && _image1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 1. Seçenek hakkında bilgi verin.')),
      );
      return;
    }
    if (_item2Ctrl.text.trim().isEmpty && _image2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 2. Seçenek hakkında bilgi verin.')),
      );
      return;
    }

    HapticService.heavyImpact();
    SoundService.playWoosh();

    // YZ ile item isimlerini düzelt
    final correctedNames = await AiService.correctItemNames(
      item1: _item1Ctrl.text.trim(),
      item2: _item2Ctrl.text.trim(),
    );
    final correctedItem1 = correctedNames[0];
    final correctedItem2 = correctedNames[1];

    if (!mounted) return;

    // Loading başlat (arka planda Firestore kontrolü yapılacağı için)
    setState(() => _isLoading = true);

    try {
      // 1) SPAM ENGELLEYİCİ: Veritabanında daha önce bu ikili karşılaştırılmış mı kontrol et.
      QueryDocumentSnapshot? existingDoc;
      final query1 = await FirebaseFirestore.instance.collection('comparisons')
          .where('item1', isEqualTo: correctedItem1)
          .where('item2', isEqualTo: correctedItem2)
          .limit(1)
          .get();

      if (query1.docs.isNotEmpty) {
        existingDoc = query1.docs.first;
      } else {
        final query2 = await FirebaseFirestore.instance.collection('comparisons')
            .where('item1', isEqualTo: correctedItem2)
            .where('item2', isEqualTo: correctedItem1)
            .limit(1)
            .get();
        if (query2.docs.isNotEmpty) {
          existingDoc = query2.docs.first;
        }
      }

      if (existingDoc != null && mounted) {
        // Zaten aranmış, var olanı getir! 
        final data = existingDoc.data() as Map<String, dynamic>;
        final comp = ComparisonModel.fromMap(existingDoc.id, data);
        
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              markdownResult: comp.result,
              item1Name: comp.item1,
              item2Name: comp.item2,
              autoSave: false, // Zaten kayıtlı!
            ),
          ),
        );
        return;
      }

      // 2) EĞER BULUNAMADIYSA YZ'YE İSTEK AT
      String? base64Image1;
      if (_image1 != null) {
        base64Image1 = base64Encode(await _image1!.readAsBytes());
      }
      String? base64Image2;
      if (_image2 != null) {
        base64Image2 = base64Encode(await _image2!.readAsBytes());
      }

      // Future olarak oluştur ve skeleton loading ile ResultScreen'e geç
      final future = AiService.analyzeComparison(
        item1Text: correctedItem1,
        item2Text: correctedItem2,
        item1ImageBase64: base64Image1,
        item2ImageBase64: base64Image2,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              analysisFuture: future,
              item1Name: correctedItem1,
              item2Name: correctedItem2,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Karşılaştırma'),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ne karşılaştırmak\nistiyorsunuz?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
            ),
            const SizedBox(height: 6),
            Text(
              'Ürün, şehir, sporcu, platform... herhangi iki şeyi yazın.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),

            _buildItemInputCard(
              title: '1. Seçenek',
              controller: _item1Ctrl,
              hint: 'Örn: Telegram, Madrid, Ronaldo...',
              itemIndex: 1,
              imageFile: _image1,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 16),

            // VS göstergesi
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildItemInputCard(
              title: '2. Seçenek',
              controller: _item2Ctrl,
              hint: 'Örn: WhatsApp, Barselona, Messi...',
              itemIndex: 2,
              imageFile: _image2,
              color: Theme.of(context).colorScheme.secondary,
            ),

            const SizedBox(height: 28),

            GradientButton(
              text: 'YZ ile Analiz Et',
              icon: Icons.auto_awesome,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _analyzeItems,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInputCard({
    required String title,
    required TextEditingController controller,
    required String hint,
    required int itemIndex,
    File? imageFile,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D34) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A42) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$itemIndex',
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
              if (imageFile != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (itemIndex == 1) _image1 = null;
                      else _image2 = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text('Kaldır', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Autocomplete TextField
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return _popularSuggestions.where((item) =>
                  item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) {
              controller.text = selection;
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              // Controller'ı senkronize et
              textEditingController.text = controller.text;
              textEditingController.addListener(() {
                if (controller.text != textEditingController.text) {
                  controller.text = textEditingController.text;
                }
              });

              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: hint,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.camera_alt_outlined, size: 20, color: color),
                        onPressed: () => _showImageOptions(itemIndex),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.search, size: 20, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: options.length > 5 ? 5 : options.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.search, size: 18, color: color),
                          title: Text(option, style: const TextStyle(fontSize: 14)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          if (imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(imageFile, height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
        ],
      ),
    );
  }
}
