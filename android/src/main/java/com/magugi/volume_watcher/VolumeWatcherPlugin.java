package com.magugi.volume_watcher;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/*
 * System volume monitoring
 */
public class VolumeWatcherPlugin implements FlutterPlugin, StreamHandler, MethodCallHandler, VolumeChangeObserver.VolumeChangeListener {
    private VolumeChangeObserver mVolumeChangeObserver;
    private EventChannel.EventSink eventSink;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;
    private static final String CHANNEL = "volume_watcher";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.onAttachedToEngine(flutterPluginBinding.getApplicationContext(), flutterPluginBinding.getBinaryMessenger());
    }

    private void onAttachedToEngine(Context applicationContext, BinaryMessenger messenger) {
        mVolumeChangeObserver = new VolumeChangeObserver(applicationContext);

        //method chanel
        methodChannel = new MethodChannel(messenger, CHANNEL + "_method");
        methodChannel.setMethodCallHandler(this);

        //event channel
        eventChannel = new EventChannel(messenger, CHANNEL + "_event");
        eventChannel.setStreamHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;

        eventChannel.setStreamHandler(null);
        eventChannel = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("getMaxVolume")) {
            result.success(mVolumeChangeObserver.getMaxMusicVolume());
        } else if (call.method.equals("getCurrentVolume")) {
            result.success(mVolumeChangeObserver.getCurrentMusicVolume());
        } else if (call.method.equals("setVolume")) {
            boolean success = true;
            try {
                double volumeValue = Double.parseDouble(call.argument("volume").toString());
                mVolumeChangeObserver.setVolume(volumeValue);
            } catch (Exception ex) {
                success = false;
            }
            result.success(success);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink eventSink) {
        // Initialization notice
        this.eventSink = eventSink;
        // Binding monitoring
        mVolumeChangeObserver.setVolumeChangeListener(this);

        // Initialization Return to the current volume
        if (eventSink != null) {
            double volume = mVolumeChangeObserver.getCurrentMusicVolume();
            eventSink.success(volume);
        }

        // Registered monitor
        mVolumeChangeObserver.registerReceiver();
    }

    @Override
    public void onVolumeChanged(double volume) {
        if (eventSink != null) {
            eventSink.success(volume);
        }
    }

    @Override
    public void onCancel(Object arguments) {
        mVolumeChangeObserver.unregisterReceiver();
        eventSink = null;
    }
}
