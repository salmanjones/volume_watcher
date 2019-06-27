import 'package:flutter/material.dart';
import 'package:volume_watcher/volume_watcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  num currentVolume = 0;
  num initVolume = 0;
  num maxVolume = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    num initVolume = await VolumeWatcher.getCurrentVolume;
    num maxVolume = await VolumeWatcher.getMaxVolume;

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
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
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              VolumeWatcher(
                onVolumeChangeListener: (num volume) {
                  setState(() {
                    currentVolume = volume;
                  });
                },
              ),
              Text("最大音量=${maxVolume}"),
              Text("初始音量=${initVolume}"),
              Text("当前音量=${currentVolume}")
            ]),
      ),
    );
  }
}
