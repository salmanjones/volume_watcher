package com.example.volume_watcher;

import android.app.Activity;
import android.util.Log;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * 系统音量监听
 */
public class VolumeWatcherPlugin implements EventChannel.StreamHandler, VolumeChangeObserver.VolumeChangeListener, MethodChannel.MethodCallHandler {
  private static final String CHANNEL = "volume_watcher";
  private VolumeChangeObserver mVolumeChangeObserver;
  private EventChannel.EventSink eventSink;
  private Activity activity;

  private VolumeWatcherPlugin(Activity activity) {
    this.activity = activity;
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    VolumeWatcherPlugin volumePlugin = new VolumeWatcherPlugin(registrar.activity());

    //method channel
    final MethodChannel methodChannel = new MethodChannel(registrar.messenger(), CHANNEL);
    methodChannel.setMethodCallHandler(volumePlugin);

    //event channel
    final EventChannel eventChannel = new EventChannel(registrar.messenger(), CHANNEL);
    eventChannel.setStreamHandler(volumePlugin);
  }

  @Override
  public void onMethodCall(MethodCall methodCall, Result result) {
    if(methodCall.method.equals("getMaxVolume")){
      result.success(mVolumeChangeObserver.getMaxMusicVolume());
    }else{
      result.notImplemented();
    }
  }

  @Override
  public void onVolumeChanged(int volume) {
    Log.d("VolumePlugin", "onVolumeChanged()--->volume = " + volume);
    if(eventSink!=null){
      eventSink.success(volume);
    }
  }

  @Override
  public void onListen(Object o, EventChannel.EventSink eventSink) {
    Log.d("VolumePlugin", "onListen");
    this.eventSink = eventSink;

    //实例化对象并设置监听器
    mVolumeChangeObserver = new VolumeChangeObserver(activity);
    mVolumeChangeObserver.setVolumeChangeListener(this);
    int initVolume = mVolumeChangeObserver.getCurrentMusicVolume();
    Log.d("VolumePlugin", "initVolume = " + initVolume);
    eventSink.success(initVolume);

    mVolumeChangeObserver.registerReceiver();
  }

  @Override
  public void onCancel(Object o) {}
}
