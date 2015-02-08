# GUIPlayerView
`GUIPlayerView` implements a simple video player using `AVPlayer`.

<img src="portrait.png" alt="Portrait screenshot" style="height:150px">

<img src="landscape.png" alt="Landscape screenshot" style="width:200px">

## Features
* Stream online and local files
* Progress bar also shows the buffer load progress
* Customizable progress bar tint colors
* Automatically detect whether the stream is a fixed-length or undefined (as in a live stream) and adjusts the UI accordingly
* AirPlay integration

## Installation
**CocoaPods** (recommended)  
Add the following line to your `Podfile`:  
`pod 'GUIPlayerView', '~> 0.0.4'`  
And then add `#import <GUIPlayerView.h>` to your view controller.

**Manual**  
Copy the folders `Classes` and `Resources` to your project, then add `#import "GUIPlayerView.h"` to your view controller.
## Usage
To use it, you must create a `GUIPlayerView` object and add it as a subview to your desired view.
Then set the property `videoURL` and call `prepareAndPlayAutomatically:`.

If you decide not to play automatically, you can leave for the user to press Play, or you can do it programmatically by calling `play`.

Once you're done playing the video, you may want to remove it from your view. To do so, just call the method `clean` and everything will be released, and the player view will be removed from its superview.

### Playback Control
There are a few methods to control the video playback:
```obj-c
- (void)play;
- (void)pause;
- (void)stop;
- (BOOL)isPlaying;
```

### UI Customization
You can change the tint color of the progress indicator.  
When the tint color is set, the buffer tint color will automatically be set to a desaturated version of the same color. If you desire a different color for it, remember to set the buffer tint color **after** setting the main tint color.
```obj-c
- (void)setTintColor:(UIColor *)tintColor;
- (void)setBufferTintColor:(UIColor *)tintColor;
- (void)setLiveStreamText:(NSString *)text;
- (void)setAirPlayText:(NSString *)text;
```
### Delegate Methods
There are several optional delegate methods you can use:
```obj-c
- (void)playerDidPause;
- (void)playerDidResume;
- (void)playerDidEndPlaying;
- (void)playerWillEnterFullscreen;
- (void)playerDidEnterFullscreen;
- (void)playerWillLeaveFullscreen;
- (void)playerDidLeaveFullscreen;
- (void)playerFailedToPlayToEnd;
- (void)playerStalled;
```

## Issues
As of this release, there are some issues that need to be worked on:

* **It only behaves nicely on fixed-orientation apps**  
It currently does not handle the orientation change events.

* **Playlist or multiple streams not supported**  
Only one video can be played and there are no interface buttons to skip/go back. You can still use the `playerDidEndPlaying` delegate method, reset `videoURL` and call `prepareAndPlayAutomatically`again to play another stream.
