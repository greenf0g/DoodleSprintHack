// Logos by Dustin Howett
// See http://iphonedevwiki.net/index.php/Logos

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface GameSceneLayer : NSObject {}
@property(retain, nonatomic) NSMutableArray *spikes;
@property(retain, nonatomic) NSMutableArray *Platforms;
@end

@interface Platform : NSObject {}
- (void)MoveTo:(CGPoint)point level:(int)level;
@end

@interface CCDirector : NSObject {}
+ (id)sharedDirector;
- (id)openGLView;
@end

static BOOL runMode = NO;
static NSTimer *runModeTimer = nil;

static UIButton *button = nil;

%hook GameSceneLayer

- (void)hasLoaded:(id)loaded {
    %orig;
    
    if(button) {
        [button removeFromSuperview];
        button = nil;
    }
       
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Run!" forState:UIControlStateNormal];
    [button setFrame:CGRectMake(-53, 270, 160, 40) ];
    button.transform = CGAffineTransformMakeRotation(-M_PI/2);
    [button addTarget:self action:@selector(hackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [[[(CCDirector *)[%c(CCDirector) sharedDirector] openGLView] window] addSubview:button];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeExpired) userInfo:nil repeats:NO];
}

- (void)gameOver {
    %orig;
    
    if(button) {
        [button removeFromSuperview];
        button = nil;
    }
}

%new(v@:)
- (void)timeExpired {
    if([[[button titleLabel] text] isEqualToString:@"Run!"]) {
        [button setEnabled:NO];
        [button setTitle:@"Too late!" forState:UIControlStateDisabled];
        NSOperationQueue *operation = [[NSOperationQueue alloc] init];
        [operation addOperationWithBlock:^{
            sleep(2);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [button removeFromSuperview];
                button = nil;
                [operation release];
            }];
        }];
    }
}

%new(v@:@)
- (void)hackButtonPressed:(UIButton *)sender {
    [button setTitle:@"Die!" forState:UIControlStateNormal];
    if(runMode) {
        [runModeTimer invalidate];
        float &speed = MSHookIvar<float>(self, "mapSpeed");
        speed = 1.0f;
        [button removeFromSuperview];
        button = nil;
    } else {
        runModeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updatePlatform) userInfo:nil repeats:YES];
    }
    runMode = !runMode;
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