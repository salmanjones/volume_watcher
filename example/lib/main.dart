import 'package:flutter/material.dart';
import 'package:volume_watcher/volume_watcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  num currentVolume = 0;
  num _platformVersion = 0;

  @override
  void initState(){
    super.initState(); 
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    num platformVersion;
    platformVersion = await VolumeWatcher.getCurrentVolume;

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
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
              Text("当前音量=${currentVolume}"),
              Text("当前音量=${_platformVersion}")
            ]),
      ),
    );
  }
}
