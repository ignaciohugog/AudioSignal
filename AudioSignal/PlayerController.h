//
//  PlayerController.h
//  AudioSignal
//
//  Created by Ignacio H. Gomez on 6/17/16.
//  Copyright © 2016 Ignacio H. Gomez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Header.h"
#import "AudioPlayer.h"

@interface PlayerController : NSObject

+ (AudioQueueOutputCallback) callBack;
+ (void)setupAudioFormat:(AQPlayState *) playState;
+ (void)encodeMessage:(NSString *)message forState:(AQPlayState *) state;
+ (void)deriveBufferSize:(Float64)seconds forState:(AQPlayState *) state;

@end
