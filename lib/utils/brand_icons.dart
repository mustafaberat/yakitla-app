library;

String brandAssetPath(String brand) {
  final name = brand.trim();
  final rules = <RegExp, String>{
    RegExp(r'^shell\b', caseSensitive: false): 'shell.svg',
    RegExp(r'^opet\b', caseSensitive: false): 'opet.svg',
    RegExp(r'petrol\s*ofis', caseSensitive: false): 'petrol-ofisi.svg',
    RegExp(r'^go\b|güzel\s*enerji|guzel\s*enerji', caseSensitive: false):
        'go.svg',
    RegExp(r'aytemiz', caseSensitive: false): 'aytemiz.svg',
    RegExp(r'socar', caseSensitive: false): 'socar.svg',
    RegExp(r'^bp\b', caseSensitive: false): 'bp.svg',
    RegExp(r'total', caseSensitive: false): 'total.svg',
    RegExp(r'kadoil|kadooğlu|kadooglu', caseSensitive: false): 'kadoil.png',
    RegExp(r'alpet', caseSensitive: false): 'alpet.svg',
    RegExp(r'lukoil', caseSensitive: false): 'lukoil.svg',
    RegExp(r'^tp\b|türkiye\s*petroller|turkiye\s*petroller',
        caseSensitive: false): 'tp.svg',
  };
  for (final entry in rules.entries) {
    if (entry.key.hasMatch(name)) {
      return 'assets/brands/${entry.value}';
    }
  }
  return 'assets/brands/default.svg';
}
