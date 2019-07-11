import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volume_watcher/volume_watcher.dart';

void main() {
  const MethodChannel channel = MethodChannel('volume_watcher');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await VolumeWatcher.getMaxVolume, 30);
  });
}
