# Yakitla — Mobil Uygulama Brief & API Entegrasyonu

Flutter uygulama kökü: `mobile-apps/yakitla/`.  
Bu doküman, **Yakitla web** (`websites/yakitla`) BFF sözleşmesini ve mobil ekran/veri kurallarını tanımlar.

---

## 1. Ürün özeti

**Yakitla**, Türkiye’deki akaryakıt istasyon fiyatlarını (benzin, motorin) il/ilçe bazında gösteren ve yolculuk maliyeti hesaplayan bir uygulamadır.

| Katman | Rol |
| --- | --- |
| Web | Next.js App Router — UI + BFF (`/api/v1/*`) |
| Mobil (hedef) | Flutter — aynı BFF’ye HTTP ile bağlanır |
| Upstream | [ServiceBox](https://api.servicebox.io) Akaryakıt Fiyatları API |
| Cache | Sunucu tarafı TTL (ilçe bazlı); krediyi boşa yakmamak için |

**Kritik kural:** Mobil uygulama **ServiceBox’a doğrudan gitmez**. `SERVICEBOX_API_KEY` sadece Yakitla backend’de kalır. Mobil her zaman Yakitla public API’sini kullanır.

```text
Flutter app  →  https://yakitla.vercel.app/api/v1/*  →  FuelService (cache)  →  ServiceBox
```

Yerel geliştirme: `http://localhost:3000/api/v1/*` (web projesi `npm run dev`).

Referans web UI: `src/components/AppShell.tsx`, `BrandCard.tsx`, `Calculator.tsx`  
Marka ikonları: `assets/brands/*` (web `public/brands` kopyası)

---

## 2. Mobil UI spesifikasyonu

### 2.1 Genel

- Uygulama adı: **Yakitla**
- Alt navigasyon (3 tab): **Fiyatlar** · **Hesapla** · **Ayarlar**
- Varsayılan dil: Türkçe (ileride çoklu dil Ayarlar’dan)
- Tema: sistem / karanlık / aydınlık

### 2.2 Tab: Fiyatlar (ana ekran)

Üst bar (tek satır / iki kolon mantığı):

| Sol | Sağ |
| --- | --- |
| **Yakitla** (marka) | Konum satırı: seçili **il · ilçe** (veya “Konum aç”) |
| | Altında: **Son güncelleme** (`meta.updatedAt` formatlanmış) |

Sağ üstte kullanıcı isterse **konum izni** verir → GPS → backend `locate` ile il bulunur → varsayılan il güncellenir; ilçe mümkünse manuel seçilir veya boş kalır.

Altında:

1. **İl / ilçe seçiciler** (dropdown veya bottom sheet)
2. **Yakıt filtresi / vurgusu:** Benzin · Motorin (sıralama ve kartlarda hangi fiyatın öne çıkacağı)
3. **İstasyon kartları** (marka dedupe yok — API’den gelen her istasyon bir kart):
   - Marka logosu + marka adı
   - İstasyon adı / kısa adres / ilçe
   - Aynı satırda fiyatlar: Benzin · Motorin (`₺X,XX /lt` veya `—`)
   - Opsiyonel: Haritada aç / Hesapla’ya git

Boş durumlar:

- İlçe seçilmeden şehir cache’i yoksa: “Bir ilçe seçerek devam edin.”
- Sonuç yok: “Bu ilçe için istasyon bulunamadı.”

### 2.3 Tab: Hesapla

Girdiler:

- Mesafe (km)
- Ortalama tüketim (L/100 km)
- Yakıt türü (benzin / motorin)
- Litre fiyatı — seçili istasyondan veya manuel

Çıktılar:

- Toplam yakıt (L)
- Tahmini maliyet (₺)
- km başına maliyet (₺)

Formül (sunucu ile aynı; istemci tarafında da hesaplanabilir):

```text
fuelConsumedLitres = distanceKm * consumptionLPer100Km / 100
totalCost          = fuelConsumedLitres * pricePerLitre
costPerKm          = totalCost / distanceKm
```

İstersen `POST /api/v1/calculate` kullan; ağsız için aynı formülü local uygula.

### 2.4 Tab: Ayarlar

| Bölüm | İçerik |
| --- | --- |
| Dil | TR (ve ileride diğerleri) |
| Tema | Sistem · Karanlık · Aydınlık |
| Varsayılan konum | Uygulama açılışında kullanılacak **il / ilçe** (SharedPreferences) |
| Hakkında | Kısa metin: bu uygulama Türkiye’deki akaryakıt fiyatlarını takip etmeyi sağlar |
| Gizlilik politikası | Link / ekran |
| Kullanım koşulları | Link / ekran |
| Yardım ve destek | **Bize ulaşın** (e-posta), **Uygulamayı değerlendir** (store review) |
| Footer | Uygulama **version** (+ build numarası, `package_info_plus`) |

Hakkında metin (öneri):

> Yakitla, Türkiye’deki akaryakıt istasyon fiyatlarını (benzin, motorin) il ve ilçe bazında takip etmenizi sağlar. Fiyatlar üçüncü taraf veri sağlayıcısından alınır; bilgilendirme amaçlıdır.

Destek e-postası / store URL’leri uygulama kurulurken `com.arusoft.yakitla` (veya seçilen paket) ile doldurulur.

---

## 3. Veri kaynağı ve iş kuralları

### 3.1 Kimden ne çekilir?

| Veri | Mobil → Yakitla API | Yakitla → ServiceBox | Not |
| --- | --- | --- | --- |
| İl listesi | `GET /api/v1/fuel/cities` | `/v1/fuel/cities` (0 kredi) | Cache’lenir |
| İlçe listesi | `GET /api/v1/fuel/districts?cityId=` | `/v1/fuel/districts` (0 kredi) | `cityId` zorunlu |
| İstasyonlar | `GET /api/v1/fuel/stations?...` | `/v1/fuel/stations` (**2 kredi** / miss) | **İlçe tercih edilir** |
| GPS → il | `GET /api/v1/fuel/locate?lat=&lon=` | Yok (centroid) | Ücretsiz, ServiceBox yok |
| Hesapla | `POST /api/v1/calculate` veya local | Yok | Pure math |
| Health | `GET /api/v1/health` | Yok | Opsiyonel |

### 3.2 Cache / kredi mantığı (mobil geliştirici için)

- Backend ilçe bazında cache tutar (`FUEL_CACHE_TTL_MS`, varsayılan 1 gün).
- Cache hit → ServiceBox’a gitmez → kredi yanmaz.
- Cache miss → ServiceBox stations (2 kredi) → sonucu cache’ler.
- **Şehir geneli** (`districtId` yok) için tüm ilçeleri sırayla taramaz; önceden warm edilmiş stale/city cache yoksa istemciden **ilçe seçmesi** istenir.
- ServiceBox live key için **API aboneliği + kredi** gerekir; yoksa stations **HTTP 402** döner (backend bunu genelde 502 `PROVIDER_FAILURE` olarak sarar).

Mobil tarafta: gereksiz polling yapma; kullanıcı il/ilçe değiştirince bir kez çek; pull-to-refresh isteğe bağlı.

### 3.3 cityId / districtId formatı

- `cityId`: plaka benzeri string, örn. `"34"` (İstanbul)
- `districtId`: ServiceBox ilçe id, örn. `"424"`
- Web varsayılan il: `34`

---

## 4. Public API sözleşmesi

**Base URL (prod):** `https://yakitla.vercel.app`  
**Base URL (local):** `http://localhost:3000`  
**Prefix:** `/api/v1`

Auth: public (API key yok). Rate limit / abuse için ileride eklenebilir; şimdilik yok.

Hata gövdesi:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "İnsan okunur mesaj"
  }
}
```

Olası `code`: `INVALID_REQUEST` · `INVALID_LOCATION` · `NOT_FOUND` · `RATE_LIMITED` · `PROVIDER_FAILURE` · `INTERNAL_ERROR`

### 4.1 `GET /api/v1/health`

```json
{ "ok": true }
```

### 4.2 `GET /api/v1/fuel/cities`

Yanıt:

```json
{
  "items": [
    { "id": "34", "name": "İstanbul" }
  ]
}
```

### 4.3 `GET /api/v1/fuel/districts?cityId=34`

| Query | Zorunlu | Açıklama |
| --- | --- | --- |
| `cityId` | Evet | İl id |

```json
{
  "items": [
    { "id": "424", "cityId": "34", "name": "Kadıköy" }
  ]
}
```

### 4.4 `GET /api/v1/fuel/stations`

| Query | Zorunlu | Açıklama |
| --- | --- | --- |
| `cityId` | Önerilir | İl |
| `districtId` | Güçlü öneri | İlçe — ücretsiz katmanda pratikte gerekli |
| `lat`, `lon` | Opsiyonel | Mesafe sıralama / konumdan il |
| `radius` | Opsiyonel | metre (varsayılan sunucu config) |

Örnek:

```http
GET /api/v1/fuel/stations?cityId=34&districtId=424
```

Yanıt:

```json
{
  "items": [
    {
      "id": "…",
      "name": "OPET Kadıköy",
      "brand": "Opet",
      "address": "…",
      "city": "İstanbul",
      "district": "Kadıköy",
      "cityId": "34",
      "districtId": "424",
      "location": { "latitude": 40.99, "longitude": 29.02 },
      "hasExactLocation": false,
      "prices": {
        "gasoline": 48.12,
        "diesel": 45.30,
              },
      "updatedAt": "2026-10-02T21:00:00.000Z",
      "distance": { "value": 1.2, "unit": "km" }
    }
  ],
  "meta": {
    "count": 12,
    "updatedAt": "2026-10-02T21:00:00.000Z"
  }
}
```

Alan notları:

- `prices.*`: `number | null` — yoksa `—` göster
- `hasExactLocation`: `false` ise lat/lon şehir centroid fallback olabilir → Maps’te adres/ilçe araması tercih et
- `distance`: sadece lat/lon ile sorgulanırsa dolabilir
- Liste **marka tekrarsız değil**; her istasyon ayrı satır

### 4.5 `GET /api/v1/fuel/stations/:id`

```json
{ "item": { /* Station */ } }
```

### 4.6 `GET /api/v1/fuel/locate?lat=41.01&lon=28.97`

ServiceBox çağırmaz. En yakın il centroid’i döner.

```json
{
  "cityId": "34",
  "cityName": "İstanbul",
  "latitude": 41.0082,
  "longitude": 28.9784
}
```

Mobil akış:

1. `geolocator` / permission → lat/lon  
2. `locate` → `cityId`  
3. `districts?cityId=` → kullanıcı ilçe seçer (veya kayıtlı default)  
4. `stations?cityId=&districtId=`

### 4.7 `POST /api/v1/calculate`

```json
{
  "distanceKm": 120,
  "consumptionLPer100Km": 7.5,
  "pricePerLitre": 48.12
}
```

```json
{
  "result": {
    "fuelConsumedLitres": 9,
    "totalCost": 433.08,
    "costPerKm": 3.61
  }
}
```

Limitler: mesafe &gt; 0 ve ≤ 10000 km; tüketim &gt; 0 ve ≤ 100; fiyat &gt; 0.

---

## 5. Flutter entegrasyon önerisi

### 5.1 Paketler (öneri)

- `http` veya `dio`
- `geolocator` + `permission_handler`
- `shared_preferences` (dil, tema, default il/ilçe)
- `package_info_plus` (version footer)
- `url_launcher` (Maps, e-posta, store)
- `flutter_localizations` / ARB (dil)

### 5.2 Servis katmanı iskeleti

```dart
// Örnek — baseUrl = https://yakitla.vercel.app
Future<List<City>> fetchCities();
Future<List<District>> fetchDistricts(String cityId);
Future<StationsResponse> fetchStations({
  required String cityId,
  String? districtId,
});
Future<LocateResult> locate(double lat, double lon);
Future<CalculateResult> calculate({
  required double distanceKm,
  required double consumptionLPer100Km,
  required double pricePerLitre,
});
```

Model alanları web ile aynı tut: `src/server/fuel/models.ts`.

### 5.3 Marka ikonları

Kaynak (uygulamada): `assets/brands/` — web: `websites/yakitla/public/brands/`

| Dosya | Marka eşlemesi (regex mantığı) |
| --- | --- |
| `shell.svg` | Shell |
| `opet.svg` | Opet |
| `petrol-ofisi.svg` | Petrol Ofisi |
| `go.svg` | GO / Güzel Enerji |
| `aytemiz.svg` | Aytemiz |
| `socar.svg` | Socar |
| `bp.svg` | BP |
| `total.svg` | Total |
| `kadoil.png` / `kadoil.svg` | Kadoil |
| `alpet.svg` | Alpet |
| `lukoil.svg` | Lukoil |
| `tp.svg` | TP / Türkiye Petrolleri |
| `default.svg` | Eşleşmeyen |

Eşleme referansı: `src/lib/brand-icons.ts`.

### 5.4 Maps

- `hasExactLocation == true` → Google Maps directions: destination=lat,lon  
- Aksi halde query: `"{adres veya ad} {marka} {ilçe} {il} akaryakıt"`

Web helper: `stationMapsUrl` in `src/lib/api-client.ts`.

### 5.5 Fiyat formatı

- Locale: `tr_TR`
- Örnek: `₺48,12`
- Null / ≤ 0 → `—`

### 5.6 Son güncelleme

`meta.updatedAt` ISO-8601 → `dd MMM yyyy HH:mm` (tr).

---

## 6. Önerilen ekran ağacı

```text
MainScaffold (BottomNavigationBar)
├── PricesTab
│   ├── Header (Yakitla | konum + son güncelleme)
│   ├── City / District pickers
│   ├── Fuel type chip (gasoline | diesel)
│   └── StationList → StationCard
│       └── (tap) StationDetail / Maps / Calculate prefill
├── CalculateTab
│   └── Trip form + result
└── SettingsTab
    ├── Language
    ├── Theme (system | dark | light)
    ├── Default city / district
    ├── About
    ├── Privacy Policy
    ├── Terms of Use
    ├── Help & Support
    │   ├── Contact us
    │   └── Rate the app
    └── Version footer
```

---

## 7. Ortam değişkenleri (sadece backend — mobil’e koyma)

Mobil `.env` / secrets içine **ServiceBox key koyma**.

Backend (`websites/yakitla`):

| Değişken | Açıklama |
| --- | --- |
| `FUEL_PROVIDER` | `servicebox` \| `mock` |
| `SERVICEBOX_API_KEY` | `sbx_demo` veya live |
| `SERVICEBOX_BASE_URL` | `https://api.servicebox.io` |
| `FUEL_CACHE_TTL_MS` | örn. `86400000` |
| `UPSTASH_REDIS_REST_URL` / `TOKEN` | Prod paylaşımlı cache (önerilir) |

Detay: [SERVICEBOX.md](./SERVICEBOX.md)

---

## 8. Agent checklist (mobil implementasyon)

1. Flutter app scaffold + 3 tab navigasyon  
2. `ApiClient` → prod base URL  
3. Cities → Districts → Stations akışı  
4. GPS → `locate` → cityId  
5. Station kartları + brand asset’ler  
6. Hesapla tab (local veya POST)  
7. Ayarlar: dil, tema, default il/ilçe, hakkında, gizlilik, koşullar, destek, rate, version  
8. Hata / boş / loading state’leri web copy ile hizala (`src/i18n/tr.ts`)  
9. ServiceBox key’i asla client’a alma  

---

## 9. Referans dosyalar (web repo)

| Dosya | Ne için |
| --- | --- |
| `src/server/fuel/models.ts` | Tip sözleşmesi |
| `src/lib/api-client.ts` | Endpoint kullanımı + format helpers |
| `src/components/AppShell.tsx` | Fiyatlar + konum akışı |
| `src/components/BrandCard.tsx` | Kart UI |
| `src/components/Calculator.tsx` | Hesapla UI |
| `src/lib/trip-calculator.ts` | Hesap formülü |
| `src/lib/brand-icons.ts` | Logo eşlemesi |
| `src/i18n/tr.ts` | Türkçe metinler |
| `docs/SERVICEBOX.md` | Upstream kredi / cache |
| `public/brands/*` | Logo asset’leri |

---

*Son güncelleme: web API’sine göre yazılmıştır. Endpoint değişirse önce bu dosya ve `README.md` Public API bölümü güncellensin.*
