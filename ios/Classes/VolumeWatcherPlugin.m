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
    // Plug-in instance
    VolumeWatcherPlugin *instance = [VolumeWatcherPlugin pluginWithVolumeView: [[MPVolumeView alloc] init]];
    
    // Method handling
    FlutterMethodChannel* methodChannel = [FlutterMethodChannel methodChannelWithName:@"volume_watcher_method"
                                                                      binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
    // Event handling
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
        // parameter
        NSDictionary *dic = call.arguments;
        NSLog(@"arguments = %@", dic);
        //Maximum volume
        float currMaxValue = 1.0f;
        result(@(currMaxValue));
    } else if ([@"getCurrentVolume" isEqualToString:call.method]) {
        // parameter
        NSDictionary *dic = call.arguments;
        NSLog(@"arguments = %@", dic);
        
        // Get the system volume
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        float currentVol = audioSession.outputVolume;
        result(@(currentVol));
    } else if ([@"setVolume" isEqualToString:call.method]) {
        @autoreleasepool {
            bool success = true;
            @try {
                //parameter
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
        // Hidden volume panel
        [volumeView setFrame:CGRectMake(-100, -100, 40, 40)];
        [volumeView setHidden:NO];
        [[UIApplication sharedApplication].delegate.window.rootViewController.view addSubview:volumeView];
    } else if ([@"showUI" isEqualToString:call.method]) {
        // Restore displaying volume panel
        [volumeView removeFromSuperview];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

/**
 * Set the system volume
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

// This onListen is the callback when the Flutter starts to monitor this Channel. The second parameter EventSink is a carrier used to pass data.
// The arguments here can be converted into the name of ReceiveBroadCastStream ("Init") so that we can listen to multiple methods instances in one event to listen to multiple methods instances
#pragma mark FlutterStreamHandler impl
- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    
    // Initial volume
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    float currentVol = audioSession.outputVolume;
    _eventSink(@(currentVol));
    
    // Registered monitoring event
    NSError *error;
    // Create a singles object and make it set to active state.
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    // Add a monitoring system volume change change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onVolumeChanged:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];
    // You need to open this function to monitor the volume of the system
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    return nil;
}

// Flutter no longer receives
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    _eventSink = nil;
    return nil;
}

/**
 * Monitoring volume changes
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
 * Remove monitoring
 */
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
}

@end
