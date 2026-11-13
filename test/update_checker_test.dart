import 'package:flutter_test/flutter_test.dart';
import 'package:talos/core/update_checker.dart';

void main() {
  group('UpdateChecker.isNewer', () {
    test('0.4.0 > 0.3.9', () {
      expect(UpdateChecker.isNewer('0.4.0', '0.3.9'), isTrue);
    });

    test('0.3.9 < 0.4.0', () {
      expect(UpdateChecker.isNewer('0.3.9', '0.4.0'), isFalse);
    });

    test('1.0.0 > 0.4.0', () {
      expect(UpdateChecker.isNewer('1.0.0', '0.4.0'), isTrue);
    });

    test('equal versions are not newer', () {
      expect(UpdateChecker.isNewer('0.4.0', '0.4.0'), isFalse);
    });

    test('0.5.0 > 0.4.9', () {
      expect(UpdateChecker.isNewer('0.5.0', '0.4.9'), isTrue);
    });

    test('0.4.1 > 0.4.0', () {
      expect(UpdateChecker.isNewer('0.4.1', '0.4.0'), isTrue);
    });

    test('0.4.0 not newer than 0.4.1', () {
      expect(UpdateChecker.isNewer('0.4.0', '0.4.1'), isFalse);
    });

    test('pre-release tag 1.0.0-rc1 handled by numeric prefix', () {
      expect(UpdateChecker.isNewer('1.0.0-rc1', '0.4.0'), isTrue);
    });

    test('trailing build metadata ignored', () {
      expect(UpdateChecker.isNewer('0.4.0+42', '0.3.9'), isTrue);
    });
  });

  group('UpdateChecker.parseCore', () {
    test('extracts dotted numeric prefix', () {
      expect(UpdateChecker.parseCore('1.2.3'), [1, 2, 3]);
      expect(UpdateChecker.parseCore('1.2'), [1, 2, 0]);
      expect(UpdateChecker.parseCore('1'), [1, 0, 0]);
    });

    test('ignores pre-release and build metadata', () {
      expect(UpdateChecker.parseCore('1.2.3-rc1'), [1, 2, 3]);
      expect(UpdateChecker.parseCore('1.2.3+build.42'), [1, 2, 3]);
    });

    test('non-numeric segments fall back to zero', () {
      expect(UpdateChecker.parseCore('1.x.3'), [1, 0, 3]);
    });
  });

  group('UpdateChecker.stripV', () {
    test('strips leading lowercase v', () {
      expect(UpdateChecker.stripV('v0.4.0'), '0.4.0');
    });

    test('strips leading uppercase V', () {
      expect(UpdateChecker.stripV('V0.4.0'), '0.4.0');
    });

    test('leaves plain version unchanged', () {
      expect(UpdateChecker.stripV('0.4.0'), '0.4.0');
    });
  });
}
