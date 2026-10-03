# Yakıtla — Google Play checklist

## Hazır

- İkon: `play/yakitla-icon-d-split-y.png` → launcher + `play/icon-512.png`
- Feature graphic: `play/feature-graphic.png` (1024×500)
- Ekran görselleri: `play/gorseller/{tr,en,ar}/01-*.png` (+ `feature.png`)
- Listing metinleri: `play/listings.json` (tr-TR, en-US, ar)
- Release: `play/versions/1/yakitla.aab` + `.apk`
- Keystore: `android/keystore/yakitla-upload.jks` (gitignore)
- Paket: `com.arusoft.yakitla` · Developer: ARU Soft
- Gizlilik: https://yakitla.vercel.app/privacy
- Destek: arusoft.company@gmail.com
- Dil: TR / EN / AR (Ayarlar)

## Sende (Play Console — API app oluşturamaz)

1. [Uygulama oluştur](https://play.google.com/console/u/0/developers/6672624803399105178/app-create)
   - Ad: **Yakıtla**
   - Varsayılan dil: Türkçe (Türkiye)
   - Uygulama / Ücretsiz
2. Oluşunca agent’a söyle; listing + screenshot + AAB yükleriz:

```bash
cd mobile-apps
python3 lib/play/upload_listings.py \
  --package com.arusoft.yakitla \
  --file yakitla/play/listings.json

python3 lib/play/upload_screenshots.py \
  --package com.arusoft.yakitla \
  --dir yakitla/play/gorseller \
  --types phone,feature,icon

python3 lib/play/upload_aab.py \
  --package com.arusoft.yakitla \
  --aab yakitla/play/versions/1/yakitla.aab \
  --whatsnew yakitla/play/whatsnew.txt \
  --track internal \
  --status draft
```

3. Console’da Data safety + Content rating + Countries doldur.
