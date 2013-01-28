//
//  TMFMultiTouchView.m
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

#import "TMFMultiTouchView.h"
#import "TMFMultiTouchCommand.h"

@implementation TMFMultiTouchView
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
#if TARGET_OS_IPHONE
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sendTouches:touches phase:TMFMultiTouchPhaseBegin];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sendTouches:touches phase:TMFMultiTouchPhaseMoved];
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sendTouches:touches phase:TMFMultiTouchPhaseEnded];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self sendTouches:touches phase:TMFMultiTouchPhaseCancelled];
    [super touchesCancelled:touches withEvent:event];
}
#endif

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
#if TARGET_OS_IPHONE
- (TMFMultiTouchCommandArguments *)argumentsWith:(NSSet *)touches phase:(TMFMultiTouchPhase)phase {
    NSMutableArray *transformedTouches = [[NSMutableArray alloc] initWithCapacity:[touches count]];
    TMFTouch *touch = nil;
    CGPoint p = CGPointZero;
    for(UITouch *t in [touches allObjects]) {
        p = [t locationInView:self];
        touch = [TMFTouch new];
        touch.location = CGPointMake(p.x / CGRectGetWidth(self.bounds), p.y / CGRectGetHeight(self.bounds));
        touch.tapCount = t.tapCount;
        touch.timestamp = t.timestamp;
        [transformedTouches addObject:touch];
    }
    
    TMFMultiTouchCommandArguments *args = [TMFMultiTouchCommandArguments new];;
    args.touches = transformedTouches;
    args.phase = phase;
    return args;
}

- (void)sendTouches:(NSSet *)touches phase:(TMFMultiTouchPhase)phase {
    TMFArguments *args = [self argumentsWith:touches phase:phase];
    [((TMFPublishSubscribeCommand *)self.command) sendWithArguments:args];
}
#endif

@end
