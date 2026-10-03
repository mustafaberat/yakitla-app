import 'package:flutter_test/flutter_test.dart';
import 'package:yakitla/utils/brand_icons.dart';

void main() {
  test('brand icons resolve known brands', () {
    expect(brandAssetPath('Opet'), contains('opet.svg'));
    expect(brandAssetPath('Unknown Co'), contains('default.svg'));
  });
}
