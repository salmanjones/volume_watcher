import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class VolumeWatcher extends StatefulWidget {
  final Function(double) onVolumeChangeListener;
  final Widget? child;

  VolumeWatcher({
    Key? key,
    required this.onVolumeChangeListener,
    this.child,
  }) : super(key: key);

  static const MethodChannel methodChannel =
      const MethodChannel('volume_watcher_method');
  static const EventChannel eventChannel =
      const EventChannel('volume_watcher_event');
  static StreamSubscription? _subscription;
  static Map<int, Function> _events = {};

  /*
   * Event Channel callback
   */
  static void _onEvent(dynamic event) {
    _events.values.forEach((Function? item) {
      item?.call(event);
    });
  }

  /*
   * Event Channel's callback failure
   */
  static void _onError(Object error) {
    print('Volume status: unknown.' + error.toString());
  }

  /// Add a monitor
  /// Returns the id, used to delete the listener
  static int? addListener(Function? onEvent) {
    // Event Channel registration
    _subscription ??= eventChannel
        .receiveBroadcastStream('init')
        .listen(_onEvent, onError: _onError);

    if (onEvent != null) {
      _events[onEvent.hashCode] = onEvent;
      getCurrentVolume.then((value) {
        onEvent(value);
      });
      return onEvent.hashCode;
    }
    return null;
  }

  /// Delete monitor
  static void removeListener(int? id) {
    if (id != null) {
      _events.remove(id);
    }
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  State<StatefulWidget> createState() {
    return VolumeState();
  }

  static Future<String> get platformVersion async {
    final String version =
        await methodChannel.invokeMethod('getPlatformVersion');
    return version;
  }

  /*
   * Get the maximum volume of the current system
   */
  static Future<double> get getMaxVolume async {
    final double maxVolume =
        await methodChannel.invokeMethod('getMaxVolume', {});
    return maxVolume;
  }

  /*
   * Get the current system volume
   */
  static Future<double> get getCurrentVolume async {
    final double currentVolume =
        await methodChannel.invokeMethod('getCurrentVolume', {});
    return currentVolume;
  }

  /*
   * Set the system volume
   */
  static Future<bool> setVolume(double volume) async {
    final bool success =
        await methodChannel.invokeMethod('setVolume', {'volume': volume});
    return success;
  }

  /// Hidden volume panel
  /// Only works with iOS
  static set hideVolumeView(bool value) {
    if (!Platform.isIOS) return;
    if (value == true) {
      methodChannel.invokeMethod('hideUI');
    } else {
      methodChannel.invokeMethod('showUI');
    }
  }
}

class VolumeState extends State<VolumeWatcher> {
  int? _listenerId;

  @override
  void initState() {
    super.initState();
    _listenerId = VolumeWatcher.addListener(widget.onVolumeChangeListener);
  }

  @override
  void dispose() {
    VolumeWatcher.removeListener(_listenerId!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? SizedBox();
  }
}
