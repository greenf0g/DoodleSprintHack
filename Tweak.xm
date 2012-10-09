// Logos by Dustin Howett
// See http://iphonedevwiki.net/index.php/Logos

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <substrate.h>
#import <objc/runtime.h>

@interface GameSceneLayer : NSObject {}
@property(retain, nonatomic) NSMutableArray *spikes;
@property(retain, nonatomic) NSMutableArray *Platforms;
@end

@interface Platform : NSObject {}
- (void)MoveTo:(CGPoint)point level:(int)level;
@end

static BOOL doubleTap = NO;
static NSTimer *doubleTapTimer = nil;

static BOOL runMode = NO;
static NSTimer *runModeTimer = nil;

%hook GameSceneLayer

- (void)ccTouchesBegan:(id)began withEvent:(id)event {
    %orig;
    
    if(doubleTap) {
        if(runMode) {
            [runModeTimer invalidate];
            float &speed = MSHookIvar<float>(self, "mapSpeed");
            speed = 1.0f;
        } else {
            runModeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatePlatform) userInfo:nil repeats:YES];
        runMode = !runMode;
        }
    } else {
        doubleTapTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkDoubleTap) userInfo:nil repeats:NO];
        doubleTap = YES;
    }
}

%new(v@:)
- (void)checkDoubleTap {
    doubleTap = NO;
}

%new(v@:)
- (void)updatePlatform {
    float &speed = MSHookIvar<float>(self, "mapSpeed");
    speed = 40.0f;
    [self setSpikes:[@[] mutableCopy]];

    for (Platform *tmpPlatform in [self Platforms]) {
        Platform *platform = tmpPlatform;
        [platform MoveTo:CGPointMake(50, 0) level:MSHookIvar<int>(platform, "level")];
        [self setPlatforms:[@[platform] mutableCopy]];
        return;
    }
}
%end