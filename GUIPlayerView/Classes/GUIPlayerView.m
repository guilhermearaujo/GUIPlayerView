//
//  GUIPlayerView.m
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 08/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import "GUIPlayerView.h"
#import "GUISlider.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "UIView+UpdateAutoLayoutConstraints.h"

@interface GUIPlayerView () <AVAssetResourceLoaderDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayerItem *currentItem;

@property (strong, nonatomic) UIView *controllersView;
@property (strong, nonatomic) UILabel *airPlayLabel;

@property (strong, nonatomic) UIButton *playButton;
@property (strong, nonatomic) UIButton *fullscreenButton;
@property (strong, nonatomic) MPVolumeView *volumeView;
@property (strong, nonatomic) GUISlider *progressIndicator;
@property (strong, nonatomic) UILabel *currentTimeLabel;
@property (strong, nonatomic) UILabel *remainingTimeLabel;
@property (strong, nonatomic) UILabel *liveLabel;

@property (strong, nonatomic) UIView *spacerView;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSTimer *progressTimer;
@property (strong, nonatomic) NSTimer *controllersTimer;
@property (assign, nonatomic) BOOL seeking;
@property (assign, nonatomic) BOOL fullscreen;
@property (assign, nonatomic) CGRect defaultFrame;

@end

@implementation GUIPlayerView

@synthesize player, playerLayer, currentItem;
@synthesize controllersView, airPlayLabel;
@synthesize playButton, fullscreenButton, volumeView, progressIndicator, currentTimeLabel, remainingTimeLabel, liveLabel, spacerView;
@synthesize activityIndicator, progressTimer, controllersTimer, seeking, fullscreen, defaultFrame;

@synthesize videoURL, controllersTimeoutPeriod, delegate;

#pragma mark - View Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  defaultFrame = frame;
  [self setup];
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  [self setup];
  return self;
}

- (void)setup {
  // Set up notification observers
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFailedToPlayToEnd:)
                                               name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStalled:)
                                               name:AVPlayerItemPlaybackStalledNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airPlayAvailabilityChanged:)
                                               name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(airPlayActivityChanged:)
                                               name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:nil];
  
  [self setBackgroundColor:[UIColor blackColor]];
  
  NSArray *horizontalConstraints;
  NSArray *verticalConstraints;
  
  
  /** Container View **************************************************************************************************/
  controllersView = [UIView new];
  [controllersView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [controllersView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.45f]];
  
  [self addSubview:controllersView];
  
  horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[CV]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"CV" : controllersView}];
  
  verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[CV(40)]|"
                                                                options:0
                                                                metrics:nil
                                                                  views:@{@"CV" : controllersView}];
  [self addConstraints:horizontalConstraints];
  [self addConstraints:verticalConstraints];
  
  
  /** AirPlay View ****************************************************************************************************/
  
  airPlayLabel = [UILabel new];
  [airPlayLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [airPlayLabel setText:@"AirPlay is enabled"];
  [airPlayLabel setTextColor:[UIColor lightGrayColor]];
  [airPlayLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
  [airPlayLabel setTextAlignment:NSTextAlignmentCenter];
  [airPlayLabel setNumberOfLines:0];
  [airPlayLabel setHidden:YES];
  
  [self addSubview:airPlayLabel];
  
  horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[AP]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"AP" : airPlayLabel}];
  
  verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[AP]-40-|"
                                                                options:0
                                                                metrics:nil
                                                                  views:@{@"AP" : airPlayLabel}];
  [self addConstraints:horizontalConstraints];
  [self addConstraints:verticalConstraints];
  
  /** UI Controllers **************************************************************************************************/
  playButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [playButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [playButton setImage:[UIImage imageNamed:@"gui_play"] forState:UIControlStateNormal];
  [playButton setImage:[UIImage imageNamed:@"gui_pause"] forState:UIControlStateSelected];
  
  volumeView = [MPVolumeView new];
  [volumeView setTranslatesAutoresizingMaskIntoConstraints:NO];
  [volumeView setShowsRouteButton:YES];
  [volumeView setShowsVolumeSlider:NO];
  [volumeView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
  
  fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [fullscreenButton setTranslatesAutoresizingMaskIntoConstraints:NO];
  [fullscreenButton setImage:[UIImage imageNamed:@"gui_expand"] forState:UIControlStateNormal];
  [fullscreenButton setImage:[UIImage imageNamed:@"gui_shrink"] forState:UIControlStateSelected];
  
  currentTimeLabel = [UILabel new];
  [currentTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [currentTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
  [currentTimeLabel setTextAlignment:NSTextAlignmentCenter];
  [currentTimeLabel setTextColor:[UIColor whiteColor]];
  
  remainingTimeLabel = [UILabel new];
  [remainingTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [remainingTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
  [remainingTimeLabel setTextAlignment:NSTextAlignmentCenter];
  [remainingTimeLabel setTextColor:[UIColor whiteColor]];
  
  progressIndicator = [GUISlider new];
  [progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
  [progressIndicator setContinuous:YES];
  
  liveLabel = [UILabel new];
  [liveLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
  [liveLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
  [liveLabel setTextAlignment:NSTextAlignmentCenter];
  [liveLabel setTextColor:[UIColor whiteColor]];
  [liveLabel setText:@"Live"];
  [liveLabel setHidden:YES];
  
  spacerView = [UIView new];
  [spacerView setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  [controllersView addSubview:playButton];
  [controllersView addSubview:fullscreenButton];
  [controllersView addSubview:volumeView];
  [controllersView addSubview:currentTimeLabel];
  [controllersView addSubview:progressIndicator];
  [controllersView addSubview:remainingTimeLabel];
  [controllersView addSubview:liveLabel];
  [controllersView addSubview:spacerView];
  
  horizontalConstraints = [NSLayoutConstraint
                           constraintsWithVisualFormat:@"H:|[P(40)][S(10)][C]-5-[I]-5-[R][F(40)][V(40)]|"
                           options:0
                           metrics:nil
                           views:@{@"P" : playButton,
                                   @"S" : spacerView,
                                   @"C" : currentTimeLabel,
                                   @"I" : progressIndicator,
                                   @"R" : remainingTimeLabel,
                                   @"V" : volumeView,
                                   @"F" : fullscreenButton}];
  
  [controllersView addConstraints:horizontalConstraints];
  
  [volumeView hideByWidth:YES];
  [spacerView hideByWidth:YES];
  
  horizontalConstraints = [NSLayoutConstraint
                           constraintsWithVisualFormat:@"H:|-5-[L]-5-|"
                           options:0
                           metrics:nil
                           views:@{@"L" : liveLabel}];
  
  [controllersView addConstraints:horizontalConstraints];
  
  for (UIView *view in [controllersView subviews]) {
    verticalConstraints = [NSLayoutConstraint
                           constraintsWithVisualFormat:@"V:|-0-[V(40)]"
                           options:NSLayoutFormatAlignAllCenterY
                           metrics:nil
                           views:@{@"V" : view}];
    [controllersView addConstraints:verticalConstraints];
  }
  
  
  /** Loading Indicator ***********************************************************************************************/
  activityIndicator = [UIActivityIndicatorView new];
  [activityIndicator stopAnimating];
  
  CGRect frame = self.frame;
  frame.origin = CGPointZero;
  [activityIndicator setFrame:frame];
  
  [self addSubview:activityIndicator];
  
  
  /** Actions Setup ***************************************************************************************************/
  
  [playButton addTarget:self action:@selector(togglePlay:) forControlEvents:UIControlEventTouchUpInside];
  [fullscreenButton addTarget:self action:@selector(toggleFullscreen:) forControlEvents:UIControlEventTouchUpInside];
  
  [progressIndicator addTarget:self action:@selector(seek:) forControlEvents:UIControlEventValueChanged];
  [progressIndicator addTarget:self action:@selector(pauseRefreshing) forControlEvents:UIControlEventTouchDown];
  [progressIndicator addTarget:self action:@selector(resumeRefreshing) forControlEvents:UIControlEventTouchUpInside|
   UIControlEventTouchUpOutside];
  
  [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControllers)]];
  [self showControllers];
  
  controllersTimeoutPeriod = 3;
}

#pragma mark - UI Customization

- (void)setTintColor:(UIColor *)tintColor {
  [super setTintColor:tintColor];
  
  [progressIndicator setTintColor:tintColor];
}

- (void)setBufferTintColor:(UIColor *)tintColor {
  [progressIndicator setSecondaryTintColor:tintColor];
}

- (void)setLiveStreamText:(NSString *)text {
  [liveLabel setText:text];
}

- (void)setAirPlayText:(NSString *)text {
  [airPlayLabel setText:text];
}

#pragma mark - Actions

- (void)togglePlay:(UIButton *)button {
  if ([button isSelected]) {
    [button setSelected:NO];
    [player pause];
    
    if ([delegate respondsToSelector:@selector(playerDidPause)]) {
      [delegate playerDidPause];
    }
  } else {
    [button setSelected:YES];
    [self play];
    
    if ([delegate respondsToSelector:@selector(playerDidResume)]) {
      [delegate playerDidResume];
    }
  }
  
  [self showControllers];
}

- (void)toggleFullscreen:(UIButton *)button {
  if (fullscreen) {
    if ([delegate respondsToSelector:@selector(playerWillLeaveFullscreen)]) {
      [delegate playerWillLeaveFullscreen];
    }
    
    [UIView animateWithDuration:0.2f animations:^{
      [self setTransform:CGAffineTransformMakeRotation(0)];
      [self setFrame:defaultFrame];
      
      CGRect frame = defaultFrame;
      frame.origin = CGPointZero;
      [playerLayer setFrame:frame];
      [activityIndicator setFrame:frame];
    } completion:^(BOOL finished) {
      fullscreen = NO;
      
      if ([delegate respondsToSelector:@selector(playerDidLeaveFullscreen)]) {
        [delegate playerDidLeaveFullscreen];
      }
    }];
    
    [button setSelected:NO];
  } else {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame;
    
    if (UIInterfaceOrientationIsPortrait(orientation)) {
      CGFloat aux = width;
      width = height;
      height = aux;
      frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
    } else {
      frame = CGRectMake(0, 0, width, height);
    }
    
    if ([delegate respondsToSelector:@selector(playerWillEnterFullscreen)]) {
      [delegate playerWillEnterFullscreen];
    }
    
    [UIView animateWithDuration:0.2f animations:^{
      [self setFrame:frame];
      [playerLayer setFrame:CGRectMake(0, 0, width, height)];
      
      [activityIndicator setFrame:CGRectMake(0, 0, width, height)];
      if (UIInterfaceOrientationIsPortrait(orientation)) {
        [self setTransform:CGAffineTransformMakeRotation(M_PI_2)];
        [activityIndicator setTransform:CGAffineTransformMakeRotation(M_PI_2)];
      }
      
    } completion:^(BOOL finished) {
      fullscreen = YES;
      
      if ([delegate respondsToSelector:@selector(playerDidEnterFullscreen)]) {
        [delegate playerDidEnterFullscreen];
      }
    }];
    
    [button setSelected:YES];
  }
  
  [self showControllers];
}

- (void)seek:(UISlider *)slider {
  int timescale = currentItem.asset.duration.timescale;
  float time = slider.value * (currentItem.asset.duration.value / timescale);
  [player seekToTime:CMTimeMakeWithSeconds(time, timescale)];
  
  [self showControllers];
}

- (void)pauseRefreshing {
  seeking = YES;
}

- (void)resumeRefreshing {
  seeking = NO;
}

- (NSTimeInterval)availableDuration {
  NSTimeInterval result = 0;
  NSArray *loadedTimeRanges = player.currentItem.loadedTimeRanges;
  
  if ([loadedTimeRanges count] > 0) {
    CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
    Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
    Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
    result = startSeconds + durationSeconds;
  }
  
  return result;
}

- (void)refreshProgressIndicator {
  CGFloat duration = CMTimeGetSeconds(currentItem.asset.duration);
  
  if (duration == 0 || isnan(duration)) {
    // Video is a live stream
    [currentTimeLabel setText:nil];
    [remainingTimeLabel setText:nil];
    [progressIndicator setHidden:YES];
    [liveLabel setHidden:NO];
  }
  
  else {
    CGFloat current = seeking ?
    progressIndicator.value * duration :         // If seeking, reflects the position of the slider
    CMTimeGetSeconds(player.currentTime); // Otherwise, use the actual video position
    
    [progressIndicator setValue:(current / duration)];
    [progressIndicator setSecondaryValue:([self availableDuration] / duration)];
    
    // Set time labels
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:(duration >= 3600 ? @"hh:mm:ss": @"mm:ss")];
    
    NSDate *currentTime = [NSDate dateWithTimeIntervalSince1970:current];
    NSDate *remainingTime = [NSDate dateWithTimeIntervalSince1970:(duration - current)];
    
    [currentTimeLabel setText:[formatter stringFromDate:currentTime]];
    [remainingTimeLabel setText:[NSString stringWithFormat:@"-%@", [formatter stringFromDate:remainingTime]]];
    
    [progressIndicator setHidden:NO];
    [liveLabel setHidden:YES];
  }
}

- (void)showControllers {
  [UIView animateWithDuration:0.2f animations:^{
    [controllersView setAlpha:1.0f];
  } completion:^(BOOL finished) {
    [controllersTimer invalidate];
    
    if (controllersTimeoutPeriod > 0) {
      controllersTimer = [NSTimer scheduledTimerWithTimeInterval:controllersTimeoutPeriod
                                                          target:self
                                                        selector:@selector(hideControllers)
                                                        userInfo:nil
                                                         repeats:NO];
    }
  }];
}

- (void)hideControllers {
  [UIView animateWithDuration:0.5f animations:^{
    [controllersView setAlpha:0.0f];
  }];
}

#pragma mark - Public Methods

- (void)prepareAndPlayAutomatically:(BOOL)playAutomatically {
  if (player) {
    [self stop];
  }
  
  player = [[AVPlayer alloc] initWithPlayerItem:nil];
  
  AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
  NSArray *keys = [NSArray arrayWithObject:@"playable"];
  
  [asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
    currentItem = [AVPlayerItem playerItemWithAsset:asset];
    [player replaceCurrentItemWithPlayerItem:currentItem];
    
    if (playAutomatically) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        [self play];
      });
    }
  }];
  
  [player setAllowsExternalPlayback:YES];
  playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
  [self.layer addSublayer:playerLayer];
  
  defaultFrame = self.frame;
  
  CGRect frame = self.frame;
  frame.origin = CGPointZero;
  [playerLayer setFrame:frame];
  
  [self bringSubviewToFront:controllersView];
  
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
  
  [player addObserver:self forKeyPath:@"rate" options:0 context:nil];
  [currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];
  
  [player seekToTime:kCMTimeZero];
  [player setRate:0.0f];
  [playButton setSelected:YES];
  
  if (playAutomatically) {
    [activityIndicator startAnimating];
  }
}

- (void)clean {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:MPVolumeViewWirelessRouteActiveDidChangeNotification object:nil];
  
  [player setAllowsExternalPlayback:NO];
  [self stop];
  [player removeObserver:self forKeyPath:@"rate"];
  [self setPlayer:nil];
  [self setPlayerLayer:nil];
  [self removeFromSuperview];
}

- (void)play {
  [player play];
  
  [playButton setSelected:YES];
  
  progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                   target:self
                                                 selector:@selector(refreshProgressIndicator)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)pause {
  [player pause];
  [playButton setSelected:NO];
  
  if ([delegate respondsToSelector:@selector(playerDidPause)]) {
    [delegate playerDidPause];
  }
}

- (void)stop {
  if (player) {
    [player pause];
    [player seekToTime:kCMTimeZero];
    
    [playButton setSelected:NO];
  }
}

- (BOOL)isPlaying {
  return [player rate] > 0.0f;
}

#pragma mark - AV Player Notifications and Observers

- (void)playerDidFinishPlaying:(NSNotification *)notification {
  [self stop];
  
  if (fullscreen) {
    [self toggleFullscreen:fullscreenButton];
  }
  
  if ([delegate respondsToSelector:@selector(playerDidEndPlaying)]) {
    [delegate playerDidEndPlaying];
  }
}

- (void)playerFailedToPlayToEnd:(NSNotification *)notification {
  [self stop];
  
  if ([delegate respondsToSelector:@selector(playerFailedToPlayToEnd)]) {
    [delegate playerFailedToPlayToEnd];
  }
}

- (void)playerStalled:(NSNotification *)notification {
  [self togglePlay:playButton];
  
  if ([delegate respondsToSelector:@selector(playerStalled)]) {
    [delegate playerStalled];
  }
}


- (void)airPlayAvailabilityChanged:(NSNotification *)notification {
  [UIView animateWithDuration:0.4f
                   animations:^{
                     if ([volumeView areWirelessRoutesAvailable]) {
                       [volumeView hideByWidth:NO];
                     } else if (! [volumeView isWirelessRouteActive]) {
                       [volumeView hideByWidth:YES];
                     }
                     [self layoutIfNeeded];
                   }];
}


- (void)airPlayActivityChanged:(NSNotification *)notification {
  [UIView animateWithDuration:0.4f
                   animations:^{
                     if ([volumeView isWirelessRouteActive]) {
                       if (fullscreen)
                         [self toggleFullscreen:fullscreenButton];
                       
                       [playButton hideByWidth:YES];
                       [fullscreenButton hideByWidth:YES];
                       [spacerView hideByWidth:NO];
                       
                       [airPlayLabel setHidden:NO];
                       
                       controllersTimeoutPeriod = 0;
                       [self showControllers];
                     } else {
                       [playButton hideByWidth:NO];
                       [fullscreenButton hideByWidth:NO];
                       [spacerView hideByWidth:YES];
                       
                       [airPlayLabel setHidden:YES];
                       
                       controllersTimeoutPeriod = 3;
                       [self showControllers];
                     }
                     [self layoutIfNeeded];
                   }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"status"]) {
    if (currentItem.status == AVPlayerItemStatusFailed) {
      if ([delegate respondsToSelector:@selector(playerFailedToPlayToEnd)]) {
        [delegate playerFailedToPlayToEnd];
      }
    }
  }
  
  if ([keyPath isEqualToString:@"rate"]) {
    CGFloat rate = [player rate];
    if (rate > 0) {
      [activityIndicator stopAnimating];
    }
  }
}

@end
