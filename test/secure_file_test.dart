import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talos/core/secure_file.dart';

void main() {
  group('writeFileAtomic', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('talos_atomic_test');
    });

    tearDown(() {
      try {
        root.deleteSync(recursive: true);
      } catch (_) {
        // Temp cleanup is best effort.
      }
    });

    test('writes the contents and leaves no temp file behind', () async {
      final target = File('${root.path}${Platform.pathSeparator}settings.json');
      await writeFileAtomic(target, '{"a":1}');
      expect(await target.readAsString(), '{"a":1}');
      expect(File('${target.path}.tmp').existsSync(), false);
    });

    test('overwrites an existing file', () async {
      final target = File('${root.path}${Platform.pathSeparator}settings.json');
      await target.writeAsString('old');
      await writeFileAtomic(target, 'new');
      expect(await target.readAsString(), 'new');
    });
  });
}
