library;

enum AppLang { tr, en, ar }

class AppStrings {
  const AppStrings(this.lang);

  final AppLang lang;

  String _t(String tr, String en, String ar) {
    switch (lang) {
      case AppLang.tr:
        return tr;
      case AppLang.en:
        return en;
      case AppLang.ar:
        return ar;
    }
  }

  String get brand => 'Yakıtla';
  String get tabPrices => _t('Fiyatlar', 'Prices', 'الأسعار');
  String get tabCalculate => _t('Hesapla', 'Calculate', 'احسب');
  String get tabSettings => _t('Ayarlar', 'Settings', 'الإعدادات');

  String get gasoline => _t('Benzin 95', 'Gasoline 95', 'بنزين 95');
  String get diesel => _t('Motorin', 'Diesel', 'ديزل');
  String get bestPrice => _t('En Uygun', 'Best', 'الأفضل');
  String get pin => _t('Sabit', 'Pin', 'تثبيت');
  String get go => _t('Git', 'Go', 'اذهب');
  String get useMyLocation =>
      _t('Konumumu kullan', 'Use my location', 'استخدم موقعي');

  String get selectCity => _t('İl', 'City', 'المدينة');
  String get selectDistrict => _t('İlçe', 'District', 'المنطقة');
  String get pickDistrict =>
      _t('İlçe seçin', 'Select a district', 'اختر المنطقة');
  String get useLocation => _t('Konum', 'Location', 'الموقع');
  String get locating => _t('Konum…', 'Locating…', 'جاري التحديد…');
  String get lastUpdate =>
      _t('Son güncelleme', 'Last update', 'آخر تحديث');
  String get today => _t('Bugün', 'Today', 'اليوم');
  String get emptyStations => _t(
        'Bu ilçe için istasyon bulunamadı.',
        'No stations for this district.',
        'لا توجد محطات في هذه المنطقة.',
      );
  String get emptyPickDistrict => _t(
        'Devam etmek için bir ilçe seçin.',
        'Pick a district to continue.',
        'اختر منطقة للمتابعة.',
      );
  String get errorGeneric => _t(
        'Bir hata oluştu. Tekrar deneyin.',
        'Something went wrong.',
        'حدث خطأ. حاول مرة أخرى.',
      );
  String get retry => _t('Tekrar dene', 'Retry', 'إعادة المحاولة');
  String get loading => _t('Yükleniyor…', 'Loading…', 'جاري التحميل…');
  String get locationDenied => _t(
        'Konum izni reddedildi. İl seçerek devam edebilirsiniz.',
        'Location denied. You can pick a city instead.',
        'تم رفض إذن الموقع. يمكنك اختيار مدينة بدلاً من ذلك.',
      );

  String get tripDistance => _t('Gidilen Yol', 'Distance', 'المسافة');
  String get avgConsumption => _t(
        'Ortalama Yakıt Tüketimi',
        'Avg. fuel consumption',
        'متوسط استهلاك الوقود',
      );
  String get pricePerLitre =>
      _t('Litre Fiyatı', 'Price per litre', 'سعر اللتر');
  String get unitKm => 'km';
  String get unitTry => '₺';
  String get unitLPer100 => 'lt/100km';
  String get calculate => _t('Hesapla', 'Calculate', 'احسب');
  String get reset => _t('Sıfırla', 'Reset', 'إعادة تعيين');
  String get pick => _t('Seç', 'Pick', 'اختر');
  String get clearSelection => _t('Kaldır', 'Clear', 'مسح');
  String get estimatedCost =>
      _t('Toplam Maliyet', 'Total cost', 'التكلفة الإجمالية');
  String get totalFuel => _t(
        'Toplam Harcanan Yakıt',
        'Total fuel used',
        'إجمالي الوقود المستهلك',
      );
  String get costPerKm =>
      _t('Km Başına Maliyet', 'Cost per km', 'التكلفة لكل كم');
  String get selectStation =>
      _t('İstasyon Seç', 'Select station', 'اختر المحطة');
  String get selectStationHint => _t(
        'Litre fiyatı otomatik dolar',
        'Litre price fills automatically',
        'يتم ملء سعر اللتر تلقائياً',
      );
  String get noStationsForCalc => _t(
        'Önce Fiyatlar sekmesinden ilçe seçip istasyonları yükleyin.',
        'Load stations from the Prices tab first.',
        'حمّل المحطات من تبويب الأسعار أولاً.',
      );
  String get fieldRequired => _t(
        'Bu alan boş bırakılamaz',
        'This field is required',
        'هذا الحقل مطلوب',
      );
  String get fieldInvalid => _t(
        'Geçerli bir değer girin',
        'Enter a valid value',
        'أدخل قيمة صالحة',
      );

  String get language => _t('Dil', 'Language', 'اللغة');
  String get theme => _t('Tema', 'Theme', 'المظهر');
  String get themeSystem => _t('Sistem', 'System', 'النظام');
  String get themeLight => _t('Aydınlık', 'Light', 'فاتح');
  String get themeDark => _t('Karanlık', 'Dark', 'داكن');
  String get defaultLocation =>
      _t('Varsayılan konum', 'Default location', 'الموقع الافتراضي');
  String get about => _t('Hakkında', 'About', 'حول');
  String get aboutBody => _t(
        'Yakıtla, Türkiye’deki akaryakıt istasyon fiyatlarını (benzin, motorin) il ve ilçe bazında takip etmenizi sağlar. Fiyatlar bilgilendirme amaçlıdır.',
        'Yakıtla helps you track fuel station prices across Turkey (gasoline, diesel) by city and district. Prices are for information only.',
        'يساعدك ياقِتلا على متابعة أسعار محطات الوقود في تركيا (بنزين وديزل) حسب المدينة والمنطقة. الأسعار لأغراض إعلامية فقط.',
      );
  String get privacy =>
      _t('Gizlilik politikası', 'Privacy policy', 'سياسة الخصوصية');
  String get terms =>
      _t('Kullanım koşulları', 'Terms of use', 'شروط الاستخدام');
  String get helpSupport =>
      _t('Yardım ve destek', 'Help & support', 'المساعدة والدعم');
  String get contactUs => _t('Bize ulaşın', 'Contact us', 'تواصل معنا');
  String get rateApp =>
      _t('Uygulamayı değerlendir', 'Rate the app', 'قيّم التطبيق');
  String get version => _t('Sürüm', 'Version', 'الإصدار');
  String get stationsCount => _t('istasyon', 'stations', 'محطة');

  String get langLabelTr => 'Türkçe';
  String get langLabelEn => 'English';
  String get langLabelAr => 'العربية';
}
