Pod::Spec.new do |s|

  s.name          = "GUIPlayerView"
  s.version       = "0.0.3"
  s.summary       = "GUIPlayerView is a simple video player embedded into a UIView."
  s.homepage      = "https://github.com/guilhermearaujo/GUIPlayerView"
  s.license       = { :type => "MIT", :file => "LICENSE" }
  s.author        = { "Guilherme Araújo" => "guilhermeama@gmail.com" }
  s.platform      = :ios, "7.0"
  s.source        = { :git => "https://github.com/guilhermearaujo/GUIPlayerView.git", :tag => "0.0.4" }
  s.source_files  = "GUIPlayerView/Classes", "GUIPlayerView/Classes/**/*.{h,m}"
  s.exclude_files = "GUIPlayerView/Classes/Exclude"
  s.resources     = "GUIPlayerView/Resources/*.png"
  s.framework     = "AVFoundation"
  s.requires_arc  = true
  s.description   = <<-DESC
                    GUIPlayerView implements a simple video player using AVPlayer.

                    To use it, you must create a GUIPlayerView object and add it as a subview to your desired view.
                    Then set the property `videoURL` and call `prepareAndPlayAutomatically:`.

                    If you decide not to play automatically, you can leave for the user to press Play, or you can do it programmatically by calling `play`.

                    Once you're done playing the video, you may want to remove it from your view. To do so, just call the method `clean` and everything will be released, and the player view will be removed from its superview.

                    There are several optional delegate methods you can use:

                    * `- (void)playerDidPause;`
                    * `- (void)playerDidResume;`
                    * `- (void)playerDidEndPlaying;`
                    * `- (void)playerWillEnterFullscreen;`
                    * `- (void)playerDidEnterFullscreen;`
                    * `- (void)playerWillLeaveFullscreen;`
                    * `- (void)playerDidLeaveFullscreen;`
                    * `- (void)playerFailedToPlayToEnd;`
                    * `- (void)playerStalled;`
                    DESC

end
