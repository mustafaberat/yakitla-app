library;

enum AppLang { tr, en }

class AppStrings {
  const AppStrings(this.lang);

  final AppLang lang;

  bool get isTr => lang == AppLang.tr;

  String get brand => 'Yakıtla';
  String get tabPrices => isTr ? 'Fiyatlar' : 'Prices';
  String get tabCalculate => isTr ? 'Hesapla' : 'Calculate';
  String get tabSettings => isTr ? 'Ayarlar' : 'Settings';

  String get gasoline => isTr ? 'Benzin 95' : 'Gasoline 95';
  String get diesel => isTr ? 'Motorin' : 'Diesel';
  String get bestPrice => isTr ? 'En Uygun' : 'Best';
  String get pin => isTr ? 'Sabit' : 'Pin';
  String get go => isTr ? 'Git' : 'Go';
  String get useMyLocation => isTr ? 'Konumumu kullan' : 'Use my location';

  String get selectCity => isTr ? 'İl' : 'City';
  String get selectDistrict => isTr ? 'İlçe' : 'District';
  String get pickDistrict =>
      isTr ? 'İlçe seçin' : 'Select a district';
  String get useLocation => isTr ? 'Konum' : 'Location';
  String get locating => isTr ? 'Konum…' : 'Locating…';
  String get lastUpdate => isTr ? 'Son güncelleme' : 'Last update';
  String get today => isTr ? 'Bugün' : 'Today';
  String get emptyStations => isTr
      ? 'Bu ilçe için istasyon bulunamadı.'
      : 'No stations for this district.';
  String get emptyPickDistrict => isTr
      ? 'Devam etmek için bir ilçe seçin.'
      : 'Pick a district to continue.';
  String get errorGeneric =>
      isTr ? 'Bir hata oluştu. Tekrar deneyin.' : 'Something went wrong.';
  String get retry => isTr ? 'Tekrar dene' : 'Retry';
  String get loading => isTr ? 'Yükleniyor…' : 'Loading…';
  String get locationDenied => isTr
      ? 'Konum izni reddedildi. İl seçerek devam edebilirsiniz.'
      : 'Location denied. You can pick a city instead.';

  String get tripDistance => isTr ? 'Gidilen Yol' : 'Distance';
  String get avgConsumption =>
      isTr ? 'Ortalama Yakıt Tüketimi' : 'Avg. fuel consumption';
  String get pricePerLitre => isTr ? 'Litre Fiyatı' : 'Price per litre';
  String get unitKm => 'km';
  String get unitTry => '₺';
  String get unitLPer100 => 'lt/100km';
  String get calculate => isTr ? 'Hesapla' : 'Calculate';
  String get reset => isTr ? 'Sıfırla' : 'Reset';
  String get pick => isTr ? 'Seç' : 'Pick';
  String get clearSelection => isTr ? 'Kaldır' : 'Clear';
  String get estimatedCost =>
      isTr ? 'Toplam Maliyet' : 'Total cost';
  String get totalFuel =>
      isTr ? 'Toplam Harcanan Yakıt' : 'Total fuel used';
  String get costPerKm =>
      isTr ? 'Km Başına Maliyet' : 'Cost per km';
  String get selectStation => isTr ? 'İstasyon Seç' : 'Select station';
  String get selectStationHint =>
      isTr ? 'Litre fiyatı otomatik dolar' : 'Litre price fills automatically';
  String get noStationsForCalc => isTr
      ? 'Önce Fiyatlar sekmesinden ilçe seçip istasyonları yükleyin.'
      : 'Load stations from the Prices tab first.';
  String get fieldRequired =>
      isTr ? 'Bu alan boş bırakılamaz' : 'This field is required';
  String get fieldInvalid =>
      isTr ? 'Geçerli bir değer girin' : 'Enter a valid value';

  String get language => isTr ? 'Dil' : 'Language';
  String get theme => isTr ? 'Tema' : 'Theme';
  String get themeSystem => isTr ? 'Sistem' : 'System';
  String get themeLight => isTr ? 'Aydınlık' : 'Light';
  String get themeDark => isTr ? 'Karanlık' : 'Dark';
  String get defaultLocation =>
      isTr ? 'Varsayılan konum' : 'Default location';
  String get about => isTr ? 'Hakkında' : 'About';
  String get aboutBody => isTr
      ? 'Yakıtla, Türkiye’deki akaryakıt istasyon fiyatlarını (benzin, motorin) il ve ilçe bazında takip etmenizi sağlar. Fiyatlar bilgilendirme amaçlıdır.'
      : 'Yakıtla helps you track fuel station prices across Turkey (gasoline, diesel) by city and district. Prices are for information only.';
  String get privacy => isTr ? 'Gizlilik politikası' : 'Privacy policy';
  String get terms => isTr ? 'Kullanım koşulları' : 'Terms of use';
  String get helpSupport => isTr ? 'Yardım ve destek' : 'Help & support';
  String get contactUs => isTr ? 'Bize ulaşın' : 'Contact us';
  String get rateApp => isTr ? 'Uygulamayı değerlendir' : 'Rate the app';
  String get version => isTr ? 'Sürüm' : 'Version';
  String get stationsCount => isTr ? 'istasyon' : 'stations';
}
