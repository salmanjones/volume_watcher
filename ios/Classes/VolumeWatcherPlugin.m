#import "VolumeWatcherPlugin.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@interface VolumeWatcherPlugin () <FlutterStreamHandler>
@end

@implementation VolumeWatcherPlugin {
    FlutterEventSink _eventSink;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    VolumeWatcherPlugin* instance = [[VolumeWatcherPlugin alloc] init];
    FlutterMethodChannel* methodChannel = [FlutterMethodChannel
                                     methodChannelWithName:@"volume_watcher_method"
                                     binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
    
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                     eventChannelWithName:@"volume_watcher_event"
                                     binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

/**
 * 监听音量变化
 */
- (void)volumeChanged:(NSNotification *)notification
{
    float volume =  [notification.userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    _eventSink(@(volume));
    NSLog(@"当前音量%f@", volume);
}

/**
 * flutter方法回调
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getMaxVolume" isEqualToString:call.method]) {
        //最大音量
        float currMaxValue = 1.0;
        result([NSNumber numberWithFloat:currMaxValue]);
    } else if ([@"getCurrentVolume" isEqualToString:call.method]) {
        // 获取系统音量
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        float currentVol = audioSession.outputVolume;
        result([NSNumber numberWithFloat:currentVol]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

// // 这个onListen是Flutter端开始监听这个channel时的回调，第二个参数 EventSink是用来传数据的载体。
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    
    // 获取系统音量
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider *volumeViewSlider= nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    float currentVol = audioSession.outputVolume;
    
    NSLog(@"当前初始化音量%f@", currentVol);
    _eventSink(@(currentVol));
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    // arguments flutter给native的参数
    // 回调给flutter， 建议使用实例指向，因为该block可以使用多次
    return nil;
}

/// flutter不再接收
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    // arguments flutter给native的参数
    NSLog(@"%@", arguments);
    return nil;
}

@end
