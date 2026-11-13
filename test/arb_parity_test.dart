import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('EN and ID arb files have the same set of user-facing keys', () {
    final en = _readArb('lib/l10n/app_en.arb');
    final id = _readArb('lib/l10n/app_id.arb');
    final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
    final idKeys = id.keys.where((k) => !k.startsWith('@')).toSet();
    final missingInId = enKeys.difference(idKeys);
    final missingInEn = idKeys.difference(enKeys);
    expect(missingInId, isEmpty, reason: 'keys in app_en.arb but missing in app_id.arb');
    expect(missingInEn, isEmpty, reason: 'keys in app_id.arb but missing in app_en.arb');
  });

  test('ARB placeholder metadata matches keys that contain a placeholder', () {
    final path = 'lib/l10n/app_en.arb';
    final arb = _readArb(path);
    for (final entry in arb.entries) {
      final key = entry.key;
      if (key.startsWith('@')) continue;
      final value = entry.value;
      if (value is! String) continue;
      final placeholders = RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}').allMatches(value).map((m) => m.group(1)!).toSet();
      if (placeholders.isEmpty) continue;
      final meta = arb['@$key'];
      expect(meta, isNotNull, reason: '$key in $path has placeholders but no @$key metadata');
      expect(meta, isA<Map>(), reason: '$key @$key metadata must be an object');
      final defined = (meta as Map)['placeholders'] as Map?;
      expect(defined, isNotNull, reason: '$key @$key.placeholders missing in $path');
      expect(defined!.keys.toSet(), placeholders, reason: '$key placeholder names mismatch in $path');
    }
  });
}
