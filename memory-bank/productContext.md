# Ürün Bağlamı (Product Context)

Bu bölüm, uygulamanın kimin için yapıldığını ve kullanıcıların uygulamayla olan etkileşimini tanımlar.

## Kullanıcı Personaları
- **Teknoloji Meraklıları:** Yeni çıkan Apple, Samsung, Xiaomi gibi markaların modellerini teknik detaylarla kıyaslamak isteyenler.
- **Kararsız Müşteriler:** İki farklı ürün (TV, Süpürge, Laptop vb.) arasında kalmış ve yapay zekadan "hangisini almalıyım?" tavsiyesi almak isteyen bireyler.
- **Hızlı Bilgi Arayanlar:** Uzun inceleme videoları izlemek yerine 15 saniyede ana farkları ve fiyatları görmeyi tercih edenler.

## Kullanıcı Yolculuğu
1. **Giriş:** Kullanıcı e-posta ve şifreyle (veya yeni kayıt oluşturarak) uygulamaya giriş yapar.
2. **Keşfet:** Ana sayfada popüler ürünlerin banner'ını ve kendi geçmiş karşılaştırmalarını görür.
3. **Karşılaştır:** "Karşılaştır" sekmesine geçer, ürün isimlerini (autocomplete yardımıyla) yazar veya fotoğraf çeker.
4. **Analiz:** "YZ ile Analiz Et" butonuna basar ve sonucun (markdown) üretilmesini bekler.
5. **Sonuç:** Kilit farklar, fiyatlar ve nihai kararı kartlar halinde görür.
6. **Etkileşim:** Sonuç ekranının altındaki sohbet butonuna basarak YZ'ye ek sorular sorar (örn: "Hangisinin kamerası gece daha iyi?").
7. **Paylaş ve Kaydet:** Sonucu arkadaşlarıyla paylaşır; sonuç otomatik olarak geçmişine kaydedilir.
8. **Geçmişe Dönüş:** Daha sonra "Geçmiş" sekmesinden eski analizlerine tekrar ulaşır.

## Temel Problemler ve Çözümler
- **Problem:** Kullanıcılar ürünlerin teknik isimlerini tam hatırlamayabilir.
- **Çözüm:** 80+ ürünü içeren yerel bir otomatik tamamlama (autocomplete) sistemi eklendi.
- **Problem:** YZ yanıtları bazen çok uzun ve okunması zor olabilir.
- **Çözüm:** Yanıtlar bölümlere (Kilit Farklar, Fiyat, Analiz, Sonuç) ayrılarak kartlar içine yerleştirildi ve markdown ile görselleştirildi.
- **Problem:** Statik karşılaştırmalar kullanıcının özel sorularına cevap vermeyebilir.
- **Çözüm:** Karşılaştırma bağlamını koruyan interaktif bir sohbet paneli eklendi.
