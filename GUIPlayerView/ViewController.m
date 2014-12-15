//
//  ViewController.m
//  GUIPlayerView
//
//  Created by Guilherme Araújo on 09/12/14.
//  Copyright (c) 2014 Guilherme Araújo. All rights reserved.
//

#import "ViewController.h"

#import "GUIPlayerView.h"

@interface ViewController () <GUIPlayerViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addPlayerButton;
@property (weak, nonatomic) IBOutlet UIButton *removePlayerButton;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;

- (IBAction)addPlayer:(UIButton *)sender;
- (IBAction)removePlayer:(UIButton *)sender;

@property (strong, nonatomic) GUIPlayerView *playerView;

@end

@implementation ViewController

@synthesize addPlayerButton, removePlayerButton, copyrightLabel, playerView;

#pragma mark - Interface Builder Actions

- (IBAction)addPlayer:(UIButton *)sender {
  [copyrightLabel setHidden:NO];
  playerView = [[GUIPlayerView alloc] initWithFrame:CGRectMake(0, 64, 320, 180)];
  [playerView setDelegate:self];

  [[self view] addSubview:playerView];
  
  NSString *path = [[NSBundle mainBundle] pathForResource:@"BigBuckBunny" ofType:@"mp4"];
  NSURL *URL = [[NSURL alloc] initFileURLWithPath:path];

  [playerView setVideoURL:URL];
  [playerView prepareAndPlayAutomatically:YES];
  
  [addPlayerButton setEnabled:NO];
  [removePlayerButton setEnabled:YES];
}

- (IBAction)removePlayer:(UIButton *)sender {
  [copyrightLabel setHidden:YES];
  
  [playerView clean];
  
  [addPlayerButton setEnabled:YES];
  [removePlayerButton setEnabled:NO];
}

#pragma mark - GUI Player View Delegate Methods

- (void)playerWillEnterFullscreen {
  [[self navigationController] setNavigationBarHidden:YES];
  [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)playerWillLeaveFullscreen {
  [[self navigationController] setNavigationBarHidden:NO];
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)playerDidEndPlaying {
  [copyrightLabel setHidden:YES];
  
  [playerView clean];
  
  [addPlayerButton setEnabled:YES];
  [removePlayerButton setEnabled:NO];
}

- (void)playerFailedToPlayToEnd {
  NSLog(@"Error: could not play video");
  [playerView clean];
}

@end
