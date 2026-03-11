# Teknik Bağlam (Tech Context)

Bu bölüm, uygulamanın teknik altyapısını, kullanılan teknolojileri ve geliştirme ortamını tanımlar.

## Teknoloji Yığını (Tech Stack)
- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Backend/Veritabanı:** Firebase Auth, Cloud Firestore
- **Yapay Zeka API:** Gemini (Model: `gemini-3.1-flash-lite-preview`)
- **Proxy/Güvenlik:** Cloudflare Workers (API anahtarlarını gizlemek ve güvenli istekler için)
- **Navigasyon:** GoRouter (veya standart Flutter Navigator)
- **İçerik Render:** `flutter_markdown` (Markdown desteği için)
- **Kalıcı Depolama:** `shared_preferences` (Tema ayarları için)

## Geliştirme Kurulumu
1. **Firebase:** `firebase_options.dart` dosyası projenin kök dizininde hazır bulunmalıdır.
2. **Paketler:** `flutter pub get` komutuyla bağımlılıklar yüklenir.
3. **Emulator/Cihaz:** Android veya iOS emülatörü/cihazı bağlı olmalıdır.
4. **Çalıştırma:** `flutter run` komutuyla uygulama başlatılır.

## Teknik Kısıtlamalar ve Kararlar
- **API Güvenliği:** Gemini API anahtarları doğrudan mobil uygulamaya gömülmez. Tüm istekler `https://ai-bot-proxy.e-duralemre.workers.dev` adresindeki proxy üzerinden geçer.
- **Performans:** Görüntü seçimi sırasında `image_quality: 50` kullanılarak bellek ve bant genişliği tasarrufu sağlanır.
- **Veri Modeli:** Karşılaştırmalar `ComparisonModel` sınıfı üzerinden Firestore ile senkronize edilir.
- **Tema:** Kullanıcının seçtiği `ThemeMode` (Sistem, Açık, Koyu) `SharedPreferences` ile kaydedilir ve uygulama her açıldığında yüklenir.

## Bağımlılıklar (Öne Çıkanlar)
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `flutter_riverpod`, `riverpod_annotation`
- `http` (API istekleri için)
- `flutter_markdown` (Sonuç ekranı render'ı)
- `shared_preferences` (Kalancılık)
- `share_plus` (Sonuç paylaşma)
- `image_picker` (Fotoğraf çekme/seçme)
- `google_fonts` (Poppins yazı tipi)
