# Aktif Baglam (Active Context)

## Su Anki Odak

OTA guncelleme sisteminin stabilizasyonu ve release surecinin otomasyonu. `ota_update` provider sinifi duzeltildi, guncelleme surum karsilastirmasi `+build` numarasini dikkate aliyor. Lokal release akisi `update.ps1` ile tek komuta indirildi. Son surum `v1.0.0+2` GitHub Releases'a yuklendi.

## Mental Yigin (Mental Stack)

1. **OTA Guncelleme Testi:** Eski surumden yeni surume update akisinin (changelog + indirme/kurulum) cihazda dogrulanmasi.
2. **Release Otomasyonu:** `update.ps1` ile surum artirma + changelog + release akisinin pratikte kullanimi.
3. **Firestore Guvenlik Kurallari:** `votes` ve `trends` koleksiyonlari icin kurallarin ayarlanmasi.

## Son Yapilan Degisiklikler

- `android/app/src/main/AndroidManifest.xml` icindeki `OtaUpdateFileProvider` sinifi dogru pakete (`sk.fourq.otaupdate.OtaUpdateFileProvider`) cekildi ve startup crash cozuldu.
- `UpdateService` artik surum karsilastirmasinda `+build` numarasini da dikkate aliyor.
- `update.ps1` eklendi: tek komutla release APK build + GitHub Release + changelog gonderimi.
- `CHANGELOG.md` eklendi ve `v1.0.0+2` release yayinlandi.
