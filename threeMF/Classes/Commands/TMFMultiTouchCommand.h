//
//  TMFMultiTouchCommand.h
//
// Copyright (c) 2013 Martin Gratzer, http://www.mgratzer.com
// All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// This file is part of 3MF http://threemf.com
//

#import <Foundation/Foundation.h>
#import "TMFPublishSubscribeCommand.h"
#import "TMFViewCommand.h"
#import "TMFMultiTouchView.h"

/**
 Enum representing all multi touch states
 */
typedef enum {
    TMFMultiTouchPhaseUndefined = 0,
    TMFMultiTouchPhaseBegin     = 101,
    TMFMultiTouchPhaseMoved     = 102,
    TMFMultiTouchPhaseEnded     = 103,
    TMFMultiTouchPhaseCancelled = 104
} TMFMultiTouchPhase;

/**
 Command used to send multi touch events.
 The corresponding arguments class is TMFMultiTouchCommandArguments.

 - unique name: tmf_mt
 - reliable
 - real-time

 Use this command as following. The self.view needs to be a subclass of MMMultiTouchView which is
 executing the command on touches.

    self.touchCommand = [TMFMultiTouchCommand new];
    self.touchCommand.view = self.view; // of type MMMultiTouchView
    [self.tmf publishCommand:self.touchCommand];
 */
@interface TMFMultiTouchCommand : TMFPublishSubscribeCommand <TMFViewCommand>
/**
 View catching multi touch events. Provide a subclass of TMFMultiTouchView in order to get commands triggered.
 The view will not get retained.
 */
@property (nonatomic, weak) TMFMultiTouchView *view;
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Arguments class for TMFMultiTouchCommand
 */
@interface TMFMultiTouchCommandArguments : TMFArguments

/**
 Array containing all touches.
 */
@property (nonatomic, strong) NSArray *touches;

/**
 Enum defining the corresponding touch phase.
 */
@property (nonatomic) TMFMultiTouchPhase phase;

@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Serializable object representing a multi touches.
 */
@interface TMFTouch : TMFSerializableObject

/**
 Location of the touch.
 */
@property (nonatomic,assign) CGPoint location;

/**
 Corresponding count of taps.
 */
@property (nonatomic,assign) NSUInteger tapCount;

/**
 The moment a touch was made as time stamp.
 */
@property (nonatomic,assign) NSTimeInterval timestamp;

@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //


