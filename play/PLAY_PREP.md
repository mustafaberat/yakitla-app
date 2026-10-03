# Yakıtla — Google Play öncesi checklist

## İkon (seçildi)

Kaynak: `play/yakitla-icon-d-split-y.png` → `assets/icon/app_icon.png`

```bash
dart run flutter_launcher_icons
```

## Uygulama kimliği

- Paket: `com.arusoft.yakitla`
- Developer: ARU Soft (Play Console account.json)
- [ ] `android/key.properties` + `android/keystore/yakitla-upload.jks`
- [ ] `versionName` / `versionCode`: `1.0.0` / `1`

## Store listing (tr-TR, en-US, ar)

- [ ] Uygulama adı: **Yakıtla**
- [ ] Kısa / uzun açıklama (3 dil)
- [ ] Feature graphic 1024×500
- [ ] Telefon ekran görselleri (dil başına)
- [ ] Gizlilik politikası URL
- [ ] İletişim: arusoft.company@gmail.com

## Teknik

- [ ] Production API base (Vercel)
- [ ] `APP_ROOT=. ../lib/scripts/install_release.sh`
- [ ] `play/whatsnew.txt` (tr-TR, en-US, ar)
- [ ] Smoke: Fiyatlar → ilçe → Git → Hesapla
