import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snake/level_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('campaign data and local art are bundled', () async {
    expect(campaignLevels, hasLength(20));
    expect(campaignLevels.first['name'], 'THE CANOPY ROOTS');
    expect(campaignLevels.last['id'], 20);
    expect(await rootBundle.load('assets/images/area_01_bg.webp'), isNotNull);
    expect(
      await rootBundle.load('assets/images/vexa_motion_a-transparent.webp'),
      isNotNull,
    );
  });
}
