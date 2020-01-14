#import <Flutter/Flutter.h>

@class MPVolumeView;

@interface VolumeWatcherPlugin : NSObject<FlutterPlugin>
- (instancetype)initWithVolumeView:(MPVolumeView *)aVolumeView;

+ (instancetype)pluginWithVolumeView:(MPVolumeView *)aVolumeView;

@end
