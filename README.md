# Yakitla (Flutter)

Türkiye akaryakıt fiyatları + yolculuk maliyeti. Backend: [yakitla.vercel.app](https://yakitla.vercel.app).

Ürün / API brief: [MOBILE_APP.md](./MOBILE_APP.md)

## Çalıştır

```bash
cd mobile-apps/yakitla
flutter pub get
flutter run
```

Yerel BFF:

```bash
flutter run --dart-define=YAKITLA_API_BASE=http://10.0.2.2:3000
```

(`10.0.2.2` Android emülatör → host `localhost`. iOS simülatörde `http://localhost:3000`.)

## Release / Play

```bash
APP_ROOT=. ../lib/scripts/install_release.sh
```
