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

    public VolumeWatcherPlugin(Activity activity) {
        mVolumeChangeObserver = new VolumeChangeObserver(activity);
        mVolumeChangeObserver.setVolumeChangeListener(this);
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        VolumeWatcherPlugin volumePlugin = new VolumeWatcherPlugin(registrar.activity());

        //method chanel
        final MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL + "_method");
        channel.setMethodCallHandler(volumePlugin);

        //event channel
        final EventChannel eventChannel = new EventChannel(registrar.messenger(), CHANNEL + "_event");
        eventChannel.setStreamHandler(volumePlugin);
    }

    /**
     * method channel
     * @param methodCall
     * @param result
     */
    @Override
    public void onMethodCall(MethodCall methodCall, Result result) {
        if (methodCall.method.equals("getMaxVolume")) {
            result.success(mVolumeChangeObserver.getMaxMusicVolume());
        } else if (methodCall.method.equals("getCurrentVolume")) {
            result.success(mVolumeChangeObserver.getCurrentMusicVolume());
        } else {
            result.notImplemented();
        }
    }

    /**
     * event channel listener
     * @param o
     * @param eventSink
     */
    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        if(BuildConfig.DEBUG){
            Log.d(VolumeChangeObserver.TAG, "onListen");
        }
        this.eventSink = eventSink;

        //实例化对象并设置监听器
        int initVolume = mVolumeChangeObserver.getCurrentMusicVolume();
        if(BuildConfig.DEBUG){
            Log.d(VolumeChangeObserver.TAG, "initVolume = " + initVolume);
        }
        eventSink.success(initVolume);

        //注册监听器
        mVolumeChangeObserver.registerReceiver();
    }

    @Override
    public void onVolumeChanged(int volume) {
        if(BuildConfig.DEBUG){
            Log.d(VolumeChangeObserver.TAG, "onVolumeChanged()--->volume = " + volume);
        }

        if (eventSink != null) {
            eventSink.success(volume);
        }
    }

    @Override
    public void onCancel(Object o) {
        mVolumeChangeObserver.unregisterReceiver();
    }
}
