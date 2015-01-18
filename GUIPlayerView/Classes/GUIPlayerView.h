//
//  GUIPlayerView.h
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GUIPlayerView;

@protocol GUIPlayerViewDelegate <NSObject>

@optional
- (void)playerDidPause;
- (void)playerDidResume;
- (void)playerDidEndPlaying;
- (void)playerWillEnterFullscreen;
- (void)playerDidEnterFullscreen;
- (void)playerWillLeaveFullscreen;
- (void)playerDidLeaveFullscreen;

- (void)playerFailedToPlayToEnd;
- (void)playerStalled;

@end

@interface GUIPlayerView : UIView

@property (strong, nonatomic) NSURL *videoURL;
@property (assign, nonatomic) NSInteger controllersTimeoutPeriod;
@property (weak, nonatomic) id<GUIPlayerViewDelegate> delegate;

- (void)prepareAndPlayAutomatically:(BOOL)playAutomatically;
- (void)clean;
- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)isPlaying;

- (void)setBufferTintColor:(UIColor *)tintColor;

- (void)setLiveStreamText:(NSString *)text;

- (void)setAirPlayText:(NSString *)text;

@end
