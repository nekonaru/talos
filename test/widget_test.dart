import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talos/core/format.dart';

void main() {
  group('format helpers', () {
    test('formatBytes scales units', () {
      expect(formatBytes(null), '');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2.0 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(formatBytes(1536 * 1024 * 1024), '1.5 GB');
    });

    test('formatSpeed appends /s', () {
      expect(formatSpeed(null), '');
      expect(formatSpeed(1024 * 1024), '1.0 MB/s');
    });

    test('formatEta formats hours and minutes', () {
      expect(formatEta(null), '');
      expect(formatEta(45), '45s');
      expect(formatEta(125), '2m 05s');
      expect(formatEta(3700), '1h 01m');
    });

    test('formatDuration renders h:mm:ss', () {
      expect(formatDuration(const Duration(seconds: 65)), '1:05');
      expect(formatDuration(const Duration(seconds: 3725)), '1:02:05');
    });
  });

  testWidgets('material app shell builds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Talos')),
        ),
      ),
    );
    expect(find.text('Talos'), findsOneWidget);
  });
}
