import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talos/core/app_info.dart';

void main() {
  test('TalosInfo version constants match pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml must carry a version like 1.2.3+4');
    expect(TalosInfo.appVersion, match!.group(1));
    expect(TalosInfo.buildNumber, match.group(2));
  });
}
