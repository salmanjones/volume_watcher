#import <Flutter/Flutter.h>
#import <MediaPlayer/MediaPlayer.h>

@interface VolumeWatcherPlugin : NSObject<FlutterPlugin>
- (instancetype)initWithVolumeView:(MPVolumeView *)aVolumeView;
+ (instancetype)pluginWithVolumeView:(MPVolumeView *)aVolumeView;
@end
