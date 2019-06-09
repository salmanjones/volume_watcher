import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class VolumeWatcher extends StatefulWidget{
  final ValueChanged<num> onVolumeChangeListener;
  VolumeWatcher({Key key, this.onVolumeChangeListener}) : super(key: key);

  static const MethodChannel methodChannel = const MethodChannel('volume_watcher_method');
  static const EventChannel eventChannel = const EventChannel('volume_watcher_event');

  @override
  State<StatefulWidget> createState() {
    return VolumeState();
  }

  /*
   * 获取当前系统最大音量
   */
  static Future<num> get getMaxVolume async {
    final num maxVolume = await methodChannel.invokeMethod('getMaxVolume',{});
    return maxVolume;
  }

  /*
   * 获取当前系统音量
   */
  static Future<num> get getCurrentVolume async {
    final num currentVolume = await methodChannel.invokeMethod('getCurrentVolume',{});
    return currentVolume;
  }
}

class VolumeState extends State<VolumeWatcher>{
  StreamSubscription _subscription;
  num currentVolume = 0;

  @override
  void initState() {
    super.initState();
    if (_subscription == null) {
      //event channel 注册
      _subscription = VolumeWatcher.eventChannel.receiveBroadcastStream("init").listen(_onEvent, onError:_onError);
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


  void setVolume(num volume) {
    if (mounted) {
      setState(() {
        currentVolume = volume;
      });
    }
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
    return GestureDetector(
      onTap: () {
        if (currentVolume == 0) {
          setVolume(0.5);
        } else {
          setVolume(0);
        }
      },
      child: Container(
        color: Theme.of(context).dialogBackgroundColor,
        padding: const EdgeInsets.only(
          left: 0.0,
          right: 8.0,
        ),
        child: Icon(
          (currentVolume > 0) ? Icons.volume_up : Icons.volume_off,
        ),
      ),
    );
  }
}
