# volume_watcher
```
支持ios 与 android 以下功能：
  1.实时监听返回系统音量值的改变，并返回音量值。 
  2.返回系统支持的最大音量，Android｜iOS统一返回 0.0 - 1.0。 
  3.返回系统改变音量前的初始值。
  4.支持设置媒体音量
  5.返回系统版本: Android 10 || iOS 13.5.1
  6.支持隐藏iOS音量图标
  
对外提供如下方法：
VolumeWatcher.platformVersion
VolumeWatcher.getMaxVolume
VolumeWatcher.getCurrentVolume
VolumeWatcher.setVolume(0.0)
//仅对IOS生效
VolumeWatcher.hideVolumeView = true;

对外提供监听：
VolumeWatcher(
  onVolumeChangeListener: (double volume) {
    ///do sth.
  },
)

使用示例：
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:volume_watcher/volume_watcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  double currentVolume = 0;
  double initVolume = 0;
  double maxVolume = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      VolumeWatcher.hideVolumeView = true;
      platformVersion = await VolumeWatcher.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    double initVolume;
    double maxVolume;
    try {
      initVolume = await VolumeWatcher.getCurrentVolume;
      maxVolume = await VolumeWatcher.getMaxVolume;
    } on PlatformException {
      platformVersion = 'Failed to get volume.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      this.initVolume = initVolume;
      this.maxVolume = maxVolume;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                VolumeWatcher(
                  onVolumeChangeListener: (num volume) {
                    setState(() {
                      currentVolume = volume;
                    });
                  },
                ),
                Text("系统版本=${_platformVersion}"),
                Text("最大音量=${maxVolume}"),
                Text("初始音量=${initVolume}"),
                Text("当前音量=${currentVolume}"),
                RaisedButton(
                  onPressed: (){
                    VolumeWatcher.setVolume(maxVolume*0.5);
                  },
                  child: Text("设置音量为${maxVolume*0.5}"),
                ),
                RaisedButton(
                  onPressed: (){
                    VolumeWatcher.setVolume(maxVolume*0.0);
                  },
                  child: Text("设置音量为${maxVolume*0.0}"),
                )
              ]),
        ),
      ),
    );
  }
}
```

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
