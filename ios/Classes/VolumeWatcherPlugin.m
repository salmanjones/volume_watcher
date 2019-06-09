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
    
    //method channel
    FlutterMethodChannel* methodChannel = [FlutterMethodChannel
                                     methodChannelWithName:@"volume_watcher_method"
                                     binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
    
    //event channel
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                     eventChannelWithName:@"volume_watcher_event"
                                     binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

/**
 * flutter方法回调
 */
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getMaxVolume" isEqualToString:call.method]) {
        //参数
        NSDictionary *dic = call.arguments;
        NSLog(@"arguments = %@", dic);
        //最大音量
        float currMaxValue = 1.0;
        result([NSNumber numberWithFloat:currMaxValue]);
    } else if ([@"getCurrentVolume" isEqualToString:call.method]) {
        //参数
        NSDictionary *dic = call.arguments;
        NSLog(@"arguments = %@", dic);
        
        // 获取系统音量
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        float currentVol = audioSession.outputVolume;
        result([NSNumber numberWithFloat:currentVol]);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

/**
 * 监听音量变化
 */
- (void)onVolumeChanged:(NSNotification *)notification {
    if(!_eventSink){
        return;
    }
    
    if ([[notification.userInfo objectForKey:@"AVSystemController_AudioCategoryNotificationParameter"] isEqualToString:@"Audio/Video"]) {
        if ([[notification.userInfo objectForKey:@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"] isEqualToString:@"ExplicitVolumeChange"]) {
            float volume = [[notification.userInfo objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
            _eventSink(@(volume));
            NSLog(@"当前音量%f@", volume);
        }
    }
}

/**
 * 移除监听
 */
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

// 这个onListen是Flutter端开始监听这个channel时的回调，第二个参数 EventSink是用来传数据的载体。
//此处的arguments可以转化为receiveBroadcastStream("init")的名称，这样我们就可以一个event来监听多个方法实例
#pragma mark FlutterStreamHandler impl

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    
    // 获取系统音量
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider *volumeViewSlider = nil;
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
    
    //注册监听事件
    NSError *error;
    // 创建单例对象并且使其设置为活跃状态.
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    // 添加监听系统音量变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onVolumeChanged:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];
    // 需要开启该功能以便监听系统音量
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    return nil;
}

//flutter不再接收
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    NSLog(@"%@", arguments);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
     _eventSink = nil;
    return nil;
}
@end
