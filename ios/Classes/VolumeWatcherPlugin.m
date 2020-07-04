#import "VolumeWatcherPlugin.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface VolumeWatcherPlugin () <FlutterStreamHandler>
@end

@implementation VolumeWatcherPlugin {
    FlutterEventSink _eventSink;
    MPVolumeView *volumeView;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    //插件实例
    VolumeWatcherPlugin *instance = [VolumeWatcherPlugin pluginWithVolumeView: [[MPVolumeView alloc] init]];
    
    //方法处理
    FlutterMethodChannel* methodChannel = [FlutterMethodChannel methodChannelWithName:@"volume_watcher_method"
                                                                      binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
    //事件处理
    FlutterEventChannel* eventChannel = [FlutterEventChannel eventChannelWithName:@"volume_watcher_event"
                                                                  binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

- (instancetype)initWithVolumeView:(MPVolumeView *)aVolumeView {
    self = [super init];
    if (self) {
        volumeView = aVolumeView;
    }
    return self;
}

+ (instancetype)pluginWithVolumeView:(MPVolumeView *)aVolumeView {
    return [[self alloc] initWithVolumeView:aVolumeView];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }else if ([@"getMaxVolume" isEqualToString:call.method]) {
        //参数
        NSDictionary *dic = call.arguments;
        NSLog(@"arguments = %@", dic);
        //最大音量
        float currMaxValue = 1.0f;
        result(@(currMaxValue));
    } else if ([@"getCurrentVolume" isEqualToString:call.method]) {
        //参数
        NSDictionary *dic = call.arguments;
        NSLog(@"arguments = %@", dic);
        
        // 获取系统音量
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        float currentVol = audioSession.outputVolume;
        result(@(currentVol));
    } else if ([@"setVolume" isEqualToString:call.method]) {
        @autoreleasepool {
            bool success = true;
            @try {
                //参数
                NSDictionary *dic = call.arguments;
                NSLog(@"arguments = %@", dic);
                NSNumber* volumeNumber = dic[@"volume"];
                float volumeValue = volumeNumber.floatValue;
                
                [self setVolume:(volumeValue)];
            } @catch (NSException *exception) {
                NSLog(@"%@", exception);
                success = false;
            }
            result(@(success));
        }
    } else if ([@"hideUI" isEqualToString:call.method]) {
        // 隐藏音量面板
        [volumeView setFrame:CGRectMake(-100, -100, 40, 40)];
        [volumeView setHidden:NO];
        [[UIApplication sharedApplication].delegate.window.rootViewController.view addSubview:volumeView];
    } else if ([@"showUI" isEqualToString:call.method]) {
        // 恢复显示音量面板
        [volumeView removeFromSuperview];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

/**
 * 设置系统音量
 */
- (void)setVolume: (float)value {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider *volumeViewSlider = nil;
    
    for (UIView *view in volumeView.subviews) {
        if ([view isKindOfClass:[UISlider class]]) {
            volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        volumeViewSlider.value = value;
    });
}

// 这个onListen是Flutter端开始监听这个channel时的回调，第二个参数 EventSink是用来传数据的载体。
//此处的arguments可以转化为receiveBroadcastStream("init")的名称，这样我们就可以一个event来监听多个方法实例
#pragma mark FlutterStreamHandler impl
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    
    //初始音量
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    float currentVol = audioSession.outputVolume;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    _eventSink = nil;
    return nil;
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
        }
    }
}

/**
 * 移除监听
 */
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

@end
