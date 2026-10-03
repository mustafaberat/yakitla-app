# Yakıtla — Google Play

Paket: `com.arusoft.yakitla` · ARU Soft

## Mağaza görselleri (vitrin)

```text
play/gorseller/
  tr|en|ar/
    01-home.png      ← Play’e giden VİTRİN (commit)
    02-duel.png
    03-setup.png
    feature.png
  icon-512.png
  ozellik-grafik/
  raw/{tr,en,ar}/    ← düz UI (gitignore; capture üretir)
```

| Ne | Nerede | Git |
| --- | --- | --- |
| Capture script | `tool/capture_play_shots.dart` | commit |
| Vitrin compositor | `tool/make_play_vitrine.py` | commit |
| Shot fontları | `tool/fonts/*.ttf` | commit |
| Demo seed (Hesapla dolu) | `lib/screens/calculate_tab.dart` (`demo*`) | commit |
| Final vitrin PNG | `play/gorseller/{tr,en,ar}/0*.png` | commit |
| Raw UI PNG | `play/gorseller/raw/` | **ignore** |
| API fixture JSON | `tool/fixtures/` | **ignore** |
| howto / over | — | yok (3 ekran) |

### Yeniden üret

```bash
# 1) Düz UI → raw/  (API: localhost:3000 veya YAKITLA_API_BASE)
APP_ROOT=. ../lib/scripts/generate_game_images.sh

# 2) Vitrin → tr|en|ar/
python3 tool/make_play_vitrine.py

# 3) Play (opsiyonel)
cd .. && python3 lib/play/upload_screenshots.py \
  --package com.arusoft.yakitla \
  --dir yakitla/play/gorseller \
  --types phone
```

Skill: `/vitrin-goruntuleri` (`~/.cursor/skills/vitrin-goruntuleri/` — repo dışı).

## API ile tamamlandı

- [x] Store listing tr-TR / en-US / ar
- [x] İkon 512, feature graphic, telefon vitrin (3 dil × 3 ekran)
- [x] Contact: arusoft.company@gmail.com · https://yakitla.vercel.app
- [x] AAB `1.0.0` (versionCode 1) → **internal** track, status **completed**
- [x] Release notes tr / en / ar

## Console’da sen (API yok / form zorunlu)

1. **Privacy policy** → https://yakitla.vercel.app/privacy  
2. **Data safety** — konum (opsiyonel), ağ; Ads: No; data sold: No
3. **Content rating** anketi (Utility)
4. **Target audience** (18+ veya All; çocuklara yönelik değil)
5. **Internal testers** e-posta listesi
6. **Countries / regions — sadece Türkiye (TR)**  
   https://play.google.com/console/u/0/developers/6672624803399105178/app/4972345228912149647/tracks/production/countries
7. Pricing: ücretsiz

Dashboard: https://play.google.com/console/u/0/developers/6672624803399105178/app/com.arusoft.yakitla/app-dashboard  
Internal: https://play.google.com/console/u/0/developers/6672624803399105178/app/com.arusoft.yakitla/tracks/internal
