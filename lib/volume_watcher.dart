import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class VolumeWatcher extends StatefulWidget {
  final ValueChanged<num> onVolumeChangeListener;
  VolumeWatcher({Key key, this.onVolumeChangeListener}) : super(key: key);

  static const MethodChannel methodChannel =
      const MethodChannel('volume_watcher_method');
  static const EventChannel eventChannel =
      const EventChannel('volume_watcher_event');

  @override
  State<StatefulWidget> createState() {
    return VolumeState();
  }

  /*
   * 获取当前系统最大音量
   */
  static Future<num> get getMaxVolume async {
    final num maxVolume = await methodChannel.invokeMethod('getMaxVolume', {});
    return maxVolume;
  }

  /*
   * 获取当前系统音量
   */
  static Future<num> get getCurrentVolume async {
    final num currentVolume =
        await methodChannel.invokeMethod('getCurrentVolume', {});
    return currentVolume;
  }

  /*
   * 设置系统音量
   */
  static Future<bool> setVolume(double volume) async {
    final bool success =
        await methodChannel.invokeMethod('setVolume', {'volume':volume});
    return success;
  }
}

class VolumeState extends State<VolumeWatcher> {
  StreamSubscription _subscription;
  num currentVolume = 0;

  @override
  void initState() {
    super.initState();
    if (_subscription == null) {
      //event channel 注册
      _subscription = VolumeWatcher.eventChannel
          .receiveBroadcastStream("init")
          .listen(_onEvent, onError: _onError);
    }
  }

  /*
   * event channel回调
   */
  void _onEvent(Object event) {
    if (mounted) {
      if (widget.onVolumeChangeListener != null) {
        widget.onVolumeChangeListener(event);
      }
      setState(() {
        currentVolume = event;
      });
    }
  }

  /*
   * event channel回调失败
   */
  void _onError(Object error) {
    print('Battery status: unknown.' + error.toString());
  }

  @override
  void dispose() {
    if (_subscription != null) {
      _subscription.cancel();
    }
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_subscription != null) {
      _subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
