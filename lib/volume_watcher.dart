import 'dart:async';

import 'package:flutter/services.dart';

class VolumeWatcher {
  static const MethodChannel _channel =
      const MethodChannel('volume_watcher');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
