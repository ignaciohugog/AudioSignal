//
//  AudioPlayer.h
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/15/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//
//INFO: https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioQueueProgrammingGuide/AQPlayback/PlayingAudio.html

#import "Header.h"
#import "PlayerController.h"

@interface AudioPlayer : NSObject
@property (nonatomic, assign) AQPlayState playState;
- (void) playMessage:(NSString *)msg;
@end
