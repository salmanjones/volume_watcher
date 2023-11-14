Language: [English](README.md) | [中文简体](README-ZH.md)

# volume_watcher
* 支持iOS和Android实时返回系统音量值，最大音量，初始音量，支持集卷。

## 入门
```
dependencies:
  volume_watcher: ^1.3.0
```

## 对外提供如下方法：
```
VolumeWatcher.platformVersion
VolumeWatcher.getMaxVolume
VolumeWatcher.getCurrentVolume
VolumeWatcher.setVolume(0.0)
VolumeWatcher.addListener((double volume) {});
VolumeWatcher.removeListener(listenerId);
//仅对IOS生效
VolumeWatcher.hideVolumeView = true;
```

## 对外提供监听：
```
VolumeWatcher(
  onVolumeChangeListener: (double volume) {
    ///do sth.
  },
)
```

或者

```
final listenerId = VolumeWatcher.addListener((double volume) {});

// You can also cancel the listener with
VolumeWatcher.removeListener(listenerId);
```

## 使用示例：
```
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

    double initVolume = 0;
    double maxVolume = 0;
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
          title: const Text('Plugin Example App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              VolumeWatcher(
                onVolumeChangeListener: (double volume) {
                  setState(() {
                    currentVolume = volume;
                  });
                },
              ),
              Text("System Version=$_platformVersion"),
              Text("Maximum Volume=$maxVolume"),
              Text("Initial Volume=$initVolume"),
              Text("Current Volume=$currentVolume"),
              ElevatedButton(
                onPressed: () {
                  VolumeWatcher.setVolume(maxVolume * 0.5);
                },
                child: Text("Set the volume to: ${maxVolume * 0.5}"),
              ),
              ElevatedButton(
                onPressed: () {
                  VolumeWatcher.setVolume(maxVolume * 0.0);
                },
                child: Text("Set the volume to: ${maxVolume * 0.0}"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
```