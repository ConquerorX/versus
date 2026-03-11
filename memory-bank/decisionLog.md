# Karar Günlüğü (Decision Log)

## [001] 2024-03-09 - Gemini API ve Cloudflare Proxy Kullanımı

- **Tarih:** 2024-03-09
- **Bağlam:** Gemini API anahtarlarının mobil uygulamada güvende tutulması gerekiyordu.
- **Karar:** İsteklerin Cloudflare Workers üzerinden proxylenmesine karar verildi.
- **Alternatifler:** Doğrudan mobil uygulamadan istek atmak (güvensiz) veya Firebase Functions kullanmak (daha maliyetli).
- **Sonuç:** API anahtarları sunucu tarafında gizlendi ve maliyetsiz bir güvenlik katmanı eklendi.

## [002] 2024-03-09 - State Management Olarak Riverpod Seçimi

- **Tarih:** 2024-03-09
- **Bağlam:** Uygulamanın auth ve tema gibi global durumlarını yönetmek için güvenilir bir yapı gerekiyordu.
- **Karar:** Flutter ekosisteminde en modern ve test edilebilir yapı olan Riverpod seçildi.
- **Alternatifler:** Provider (daha eski), Bloc (daha karmaşık boilerplate).
- **Sonuç:** Kodun bağımlılıkları daha net yönetilir hale geldi.

## [003] 2024-03-09 - Sonuçların Otomatik Kaydedilmesi

- **Tarih:** 2024-03-09
- **Bağlam:** Kullanıcılar her seferinde analiz sonucunu manuel kaydetmek zorunda kalıyordu.
- **Karar:** Analiz tamamlandığı anda sonucun Firestore'a "autoSave" özelliğiyle kaydedilmesine karar verildi.
- **Sonuç:** Kullanıcı deneyimi iyileştirildi, veritabanı tutarlılığı arttı.

## [004] 2024-03-10 - İnteraktif Sohbet Özelliği

- **Tarih:** 2024-03-10
- **Bağlam:** Statik karşılaştırmalar kullanıcının aklındaki her soruya cevap veremiyordu.
- **Karar:** ResultScreen altına genişleyebilir bir sohbet paneli eklenerek context-aware (bağlam duyarlı) sohbet desteği eklendi.
- **Sonuç:** Uygulama "statik bir araç" olmaktan çıkıp "interaktif bir asistan" haline geldi.

## [005] 2024-03-10 - Evrensel Karşılaştırma Platformuna Dönüşüm

- **Tarih:** 2024-03-10
- **Bağlam:** Uygulama sadece ürün karşılaştırma aracıydı; kullanıcılar farklı kategorilerdeki öğeleri de karşılaştırmak istiyordu.
- **Karar:** Tüm sistem dinamikleştirildi: AI prompt'u evrensel JSON formatına geçirildi, kart başlıkları YZ tarafından bağlama göre belirleniyor, `ComparisonModel` alan isimleri `product`'tan `item`'a değiştirildi.
- **Alternatifler:** Sadece ürün kategorilerini genişletmek (kısıtlayıcı) veya her kategori için ayrı prompt yazmak (bakım zorluğu).
- **Sonuç:** Tek bir prompt ile sonsuz kategori desteği sağlandı, kart başlıkları YZ'nin zekasına bırakıldı.

## [006] 2024-03-10 - Yapılandırılmış JSON Yanıt Formatı

- **Tarih:** 2024-03-10
- **Bağlam:** Sabit markdown başlıkları (## Kilit Farklar, ## Fiyat) evrensel karşılaştırma için uygun değildi.
- **Karar:** YZ'den yapılandırılmış JSON yanıt istenmesine karar verildi; JSON parse başarısız olursa markdown fallback mekanizması korundu.
- **Alternatifler:** Markdown formatını koruyup regex ile parse etmek (kırılgan), sabit JSON şeması kullanmak (esnek değil).
- **Sonuç:** Dinamik kart başlıkları, puan verisi, radar grafik verileri ve soru önerileri tek bir yapıda toplandı.

## [007] 2024-03-10 - Radar Grafik İçin fl_chart Paketi

- **Tarih:** 2024-03-10
- **Bağlam:** Karşılaştırma sonuçlarını görsel olarak sunmak için radar grafik gerekiyordu.
- **Karar:** `fl_chart` paketi seçildi (Flutter için en olgun ve en çok kullanılan grafik kütüphanesi).
- **Alternatifler:** `syncfusion_flutter_charts` (lisans gerektirir), `charts_flutter` (deprecated).
- **Sonuç:** Hafif, özelleştirilebilir radar grafik widget'ı oluşturuldu.

## [008] 2024-03-11 - "Editorial Luxury" Tasarım Dilinin Benimsenmesi

- **Tarih:** 2024-03-11
- **Bağlam:** Uygulamanın önceki mor-mavi ağırlıklı "AI teması" ucuz hissettiriyordu.
- **Karar:** Uygulamanın renk paleti Copper (Bakır) ve Dark Slate (Koyu Füme) ağırlıklı Premium / Editorial Luxury bir stile evirildi.
- **Alternatifler:** Tailwind standart renkleri, Material 3 standart renkleri.
- **Sonuç:** Kullanıcıda prestij uyandıran, sade ve yüksek kontrastlı bir görsel dile geçildi. Degrade (gradient) kullanımları kısıtlanıp daha tutarlı bir yapı elde edildi.

## [009] 2024-03-11 - Canlı Oylama Sistemi İçin Firestore Stream Kullanımı

- **Tarih:** 2024-03-11
- **Bağlam:** "Senin tercihin hangisi?" bölümündeki sonuçlar statikti ve canlı güncellenmiyordu.
- **Karar:** `FutureBuilder` veya `get()` çağırmak yerine, `snapshots().listen()` mekanizması devreye alındı.
- **Sonuç:** Oylama anlık (real-time) oldu ve kullanıcılar ekrandayken diğerlerinin oylarını animasyonlu görebilir duruma geldi. Optimistik UI ile tıklama anındaki bekleme hissi kaldırıldı.

## [010] 2024-03-11 - İnfografik Paylaşımı İçin Bağımsız Off-Screen Rendering

- **Tarih:** 2024-03-11
- **Bağlam:** `ResultScreen`'in widget ağacındaki `RepaintBoundary` çıktısı (ss alma) bozuk orantılara, gereksiz scroll uzunluklarına neden oluyordu.
- **Karar:** Ekranda görünmeyen (off-screen) özel bir `InfographicWidget` (1080x1350) üretildi ve cihaz arkasında çizdirilerek doğrudan paylaşıma sunuldu.
- **Sonuç:** Kullanıcıya çok daha kaliteli, sosyal ağ (Instagram vb.) formatına tam oturan temiz çıktılar paylaştırma yeteneği sağlandı.

## [011] 2026-03-11 - Ana Sayfa ve Profil Ekranı Yenilemesi

- **Tarih:** 2026-03-11
- **Bağlam:** Ana sayfadaki "Hızlı Başlat" bölümündeki hazır ürünler statik hissettiriyordu, trendler çok aşağıdaydı. Profil hesabı çok boştu ve sadece tema değiştirilebiliyordu.
- **Karar:** Ana sayfada Trendler üst tarafa taşındı, "Hızlı Başlat" yerine rastgele ürün getiren yenilikçi "Sürpriz İkilem" butonu yerleştirildi. Profil ekranında tasarımsal olarak degradeli ve şık bir avatar yapısına geçildi, istatistik (seviye, inceleme sayısı vb.) bölümü Firestore'a bağlandı.
- **Sonuç:** Kullanıcı arayüzü son derece interaktif, premium ve sürükleyici hale getirildi. Kullanıcı sayfaları işlevsel kılındı.

## [012] 2026-03-11 - Uygulama İsminin "V/S" Yapılması ve Adaptif İkon Entegrasyonu

- **Tarih:** 2026-03-11
- **Bağlam:** Uygulama adının "ai_product_compare" olarak kalması ve varsayılan ikonun basitliği markalaşmayı önlüyordu. Siyah arka planlı V/S logosu Android adaptif ikon standartlarına uymadığı için beyaz çerçeve veriyordu.
- **Karar:** Uygulama adı `AndroidManifest.xml` ve `Info.plist` tarafında "V/S" yapıldı. `flutter_launcher_icons` kütüphanesi ile logoyu arka plan renk koduyla uyumlu (`#18181A`) harmanlayan "Adaptive Icon" konfigürasyonu uygulandı.
- **Sonuç:** Uygulama, yüklendiğinde artık çok daha profesyonel ve cihaza oturan temiz bir ikon / V/S ismi ile görünmektedir.

## [013] 2026-03-11 - Adaptive Icon Foreground'un Düzenlenmesi (Kutu İçinde Kutu Hatası)

- **Tarih:** 2026-03-11
- **Bağlam:** `app_icon.png` görselinin #000000 arka plana sahip olması, Android Adaptive Icon oluşturulurken '#18181A' arka plan üzerinde "kutu içinde kutu" görünümüne ve logonun gereksiz küçük kalmasına (padding) neden oluyordu.
- **Karar:** Kullanıcı `app_icon.png` dosyasını 1024x1024 çözünürlüğünde, içeriği tam kapsayacak şekilde güncellediğini bildirdi. Mevcut geçici Dart betiği ayarlamaları iptal edilerek yeni `app_icon.png`, Pubspec.yaml dosyasında direkt olarak `adaptive_icon_foreground` ve image path olarak atandı.
- **Sonuç:** Logo boyutlandırması ve orantısı en optimum standart haline getirildi, Dark Slate (#18181A) arka plan üzerine devasa bir boyutta oturan, kesintisiz bir Adaptive Icon otomatik olarak oluşturuldu.

## [014] 2026-03-11 - "Sürpriz İkilem" İçin Dinamik Yapay Zeka Entegrasyonu

- **Tarih:** 2026-03-11
- **Bağlam:** Ana sayfadaki "Şansımı Dene" (Sürpriz İkilem) butonu statik bir algoritma ile sadece 7-8 eşleşme çeviriyordu.
- **Karar:** `AiService` içine, Google Gemini'dan her seferinde yaratıcı ve akla gelmeyen birbiriyle eşleşebilecek öğeler isteyen bir prompt eklendi (`generateRandomPair()`).
- **Sonuç:** Kullanıcı butona bastığı anda yapay zeka tarafından 1-2 saniye içinde anlık olarak komik, ilginç ve yepyeni ikilemler üretiliyor, uygulama çok daha dinamik ve eğlenceli hale geldi.

## [015] 2026-03-11 - Trendlerin Senkronizasyon Sorununu Giderme ("Tümünü Gör" Ekranı)

- **Tarih:** 2026-03-11
- **Bağlam:** `ResultScreen` üzerinde yapılan Firestore `runTransaction` çağrısı, offline durumlarda veya ağ kopmalarında trendleri veritabanına ya eksik yansıtıyor ya da geciktiriyordu. Ayrıca trendlerin hepsi görülmüyordu.
- **Karar:** Trend sayımı `runTransaction` yerine doğrudan `FieldValue.increment` ve `SetOptions(merge: true)` metoduna çevrildi, bu sayede Firestore'un lokal cache opsiyonu devreye girmiş oldu. Ayrıca `trends_screen.dart` adlı ek bir arayüz oluşturulup ana sayfadan yönlendirildi.
- **Sonuç:** Trendler ağ kopmalarında bile tıklandığı an sayılmaya/kaydedilmeye başlandı ve gecikmeli düşme sorunu root seviyesinde çözüldü. Kullanıcılar artık tüm trend listesine erişebiliyor.

## [016] 2026-03-11 - Trend Karşılaştırmalarında Cihazlar Arası Farklı Sonuç Çıkma (Determinizm) Sorunu

- **Tarih:** 2026-03-11
- **Bağlam:** Kullanıcı aynı trend eşleşmesine farklı cihazlardan (emülatör ve telefon) bastığında, uygulamanın farklı puanlar ve içerikler verdiğini fark etti. Bunun sebebi her tıklanmada yapay zekaya baştan sorulmasıydı.
- **Karar:** `home_screen.dart` ve `trends_screen.dart` sayfalarındaki `onTap` eylemi değiştirildi. Artık o trende basıldığında öncelikle Firestore'un `comparisons` koleksiyonuna bakılıyor ve **daha önce yapılmış bir karşılaştırma var mı** diye kontrol ediliyor. Eğer varsa (ki trendlerde her zaman vardır), O sonuç ekrana basılıyor. Yoksa AI yepyeni oluşturuyor.
- **Sonuç:** Hangi cihazdan bakılırsa bakılsın, "A vs B" trendine tıklandığında herkes aynı ekranı (puanı, içeriği) görüyor. Tutarsızlık ve AI halüsinasyonu ortadan kaldırıldı. Eşitleme sağlandı.
