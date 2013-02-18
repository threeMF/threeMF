//
//  CADGyroMouseCommand.m
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

#import "CADGyroMouseCommand.h"

#if TARGET_OS_IPHONE
#import <CoreMotion/CoreMotion.h>
static CMMotionManager *__motionManager;
#endif

#define MIN_SAMPLE_CHANGE 0.2f

@interface CADGyroMouseCommand() {
    NSOperationQueue *_deviceMotionQueue;
    __block CGFloat _x;
    __block CGFloat _y;

    CGFloat _lastSentX;
    CGFloat _lastSentY;
}
@end

@implementation CADGyroMouseCommand

//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
#if TARGET_OS_IPHONE    
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __motionManager = [CMMotionManager new];
    });
}
#endif

- (id)init {
    self = [super init];
    if (self) {
        _deviceMotionQueue = [[NSOperationQueue alloc] init];
        _x = 0.0f;
        _y = 0.0f;
    }
    return self;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)center {
    _x = 0.0f;
    _y = 0.0f;
}

+ (BOOL)isGyroscopeAvailable {
#if TARGET_OS_IPHONE    
    return [__motionManager isDeviceMotionAvailable] && [__motionManager isGyroAvailable];
#endif
    return NO;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
+ (NSString *)name {
    return @"cad_gyro";
}

+ (TMFConfiguration *)defaultConfiguration {
    CADGyroMouseCommandConfiguration *configuration = [CADGyroMouseCommandConfiguration new];
    configuration.updateInterval = 30.0f;
    return configuration;
}

#if TARGET_OS_IPHONE    
- (void)start:(startCompletionBlock_t)completionBlock {
    NSParameterAssert(completionBlock!=nil);
    [super start:^(NSError *error){
        __block NSError *localError = error;
        if(!localError) {
            if(self.configuration.updateInterval > 0.0f) {
                if([CADGyroMouseCommand isGyroscopeAvailable]) {
                    __motionManager.deviceMotionUpdateInterval = 1 / self.configuration.updateInterval;
                    [__motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical
                        toQueue:_deviceMotionQueue
                    withHandler:^(CMDeviceMotion *motion, NSError *error) {
                        _x -= motion.rotationRate.z;
                        _y += motion.rotationRate.x;

                        if( fabsf(_x - _lastSentX) > MIN_SAMPLE_CHANGE ||
                           fabsf(_y - _lastSentY) > MIN_SAMPLE_CHANGE ) {
                            _lastSentX = _x;
                            _lastSentY = _y;

                            CADGyroMouseCommandArguments *args = [CADGyroMouseCommandArguments new];
                            args.x = _x;
                            args.y = _y;
                            [self sendWithArguments:args];
                        }
                    }];

                    self.running = __motionManager.deviceMotionActive || __motionManager.isGyroActive;
                }
                else {
                    localError = [NSError errorWithDomain:@"com.mgratzer.aridraw" code:100 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"No Gyroscope available.", @"Error message") }];
                    NSLog(@"%@", localError);
                }
            }
        }

        if(completionBlock != nil) {
            completionBlock(localError);
        }
    }];
}

- (void)stop:(stopCompletionBlock_t)completionBlock {
    [super stop:^{
        [__motionManager stopGyroUpdates];
        self.running = NO;
    }];
}
#endif

- (BOOL)isReliable {
    return NO;
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

@end
