//
//  TMFMotionCommand.m
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

#import "TMFMotionCommand.h"
#import "TMFError.h"
#import "TMFLog.h"

#ifdef __COREMOTION__
static CMMotionManager *__motionManager;

@interface TMFMotionCommand() {
    NSOperationQueue *_accelerometerQueue;
    NSOperationQueue *_gyroscopeQueue;
    NSOperationQueue *_magnetometerQueue;
    NSOperationQueue *_deviceMotionQueue;
}
@end
#endif

@implementation TMFMotionCommand
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    self = [super init];
    if(self) {
#if TARGET_OS_IPHONE
#ifdef __COREMOTION__
        _accelerometerQueue = [NSOperationQueue new];
        _gyroscopeQueue     = [NSOperationQueue new];
        _magnetometerQueue  = [NSOperationQueue new];
        _deviceMotionQueue  = [NSOperationQueue new];
#endif
#endif
    }
    return self;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
+ (NSString *)name {
    return @"tmf_motion";
}

+ (TMFConfiguration *)defaultConfiguration {
    TMFMotionCommandConfiguration *configuration = [TMFMotionCommandConfiguration new];
    configuration.updateInterval = 0.0;
    configuration.sensors = TMFMotionSensorNone;
    configuration.filter = TMFMotionDataFilterNone;
    return configuration;
}

#ifdef __COREMOTION__
- (void)start:(startCompletionBlock_t)completionBlock {
    [super start:^(NSError *error){
        __block NSError *localError = error;
        if(!localError) {
            TMFMotionCommandConfiguration *conf = self.configuration;
            if(![self isRunning] && conf) {

                if(conf.updateInterval > 0.0f) {
                    if(!__motionManager) {
                        __motionManager = [CMMotionManager new];
                    }

                    // -------------------------------
                    // Accelerometer
                    // -------------------------------
                    if(__motionManager.isAccelerometerAvailable && (conf.sensors & TMFMotionSensorAccelerometer)) {
                        __motionManager.accelerometerUpdateInterval = 1 / conf.updateInterval;
                        [__motionManager startAccelerometerUpdatesToQueue:_accelerometerQueue withHandler:^(CMAccelerometerData *data, NSError *error) {
                            if(fabs(data.acceleration.x) > conf.threshold || fabs(data.acceleration.y) > conf.threshold || fabs(data.acceleration.z) > conf.threshold) {
                                [self sendWithArguments:[TMFMotionCommandArguments argumentsWithX:data.acceleration.x y:data.acceleration.y z:data.acceleration.z sensor:TMFSensorAccelerometer]];
                            }
                        }];
                    }
                    else if (!__motionManager.isAccelerometerAvailable && (conf.sensors & TMFMotionSensorGyroscope)) {
                        TMFLogError(@"No Accelerometer available.");
                    }

                    // -------------------------------
                    // Gyroscope
                    // -------------------------------
                    if(__motionManager.isGyroAvailable && (conf.sensors & TMFMotionSensorGyroscope)) {
                        __motionManager.gyroUpdateInterval = 1 / conf.updateInterval;
                        [__motionManager startGyroUpdatesToQueue:_gyroscopeQueue withHandler:^(CMGyroData *gyroData, NSError *error) {
                            if(fabs(gyroData.rotationRate.x) > conf.threshold || fabs(gyroData.rotationRate.y) > conf.threshold || fabs(gyroData.rotationRate.z) > conf.threshold) {
                                [self sendWithArguments:[TMFMotionCommandArguments argumentsWithX:gyroData.rotationRate.x y:gyroData.rotationRate.y z:gyroData.rotationRate.z sensor:TMFSensorGyroscope]];
                            }
                        }];
                    }
                    else if (!__motionManager.isGyroAvailable && (conf.sensors & TMFMotionSensorGyroscope)) {
                        TMFLogError(@"No Gyroscope available.");
                    }

                    // -------------------------------
                    // Magetometer
                    // -------------------------------
                    if(__motionManager.isMagnetometerAvailable && (conf.sensors & TMFMotionSensorMagnetometer)) {

                        __motionManager.magnetometerUpdateInterval = 1 / conf.updateInterval;
                        [__motionManager startMagnetometerUpdatesToQueue:_magnetometerQueue withHandler:^(CMMagnetometerData *magnetoData, NSError *error) {
                            if(fabs(magnetoData.magneticField.x) > conf.threshold || fabs(magnetoData.magneticField.y) > conf.threshold || fabs(magnetoData.magneticField.z) > conf.threshold) {
                                [self sendWithArguments:[TMFMotionCommandArguments argumentsWithX:magnetoData.magneticField.x y:magnetoData.magneticField.y z:magnetoData.magneticField.z sensor:TMFSensorMagnetomenter]];
                            }
                        }];
                    }
                    else if (!__motionManager.isMagnetometerAvailable && (conf.sensors & TMFMotionSensorMagnetometer)) {
                        TMFLogError(@"No Magenetometer available.");
                    }

                    // -------------------------------
                    // Device Motion
                    // -------------------------------
                    if(__motionManager.isDeviceMotionAvailable && (conf.sensors & TMFMotionSensorDeviceMotion)) {
                        __motionManager.deviceMotionUpdateInterval = 1 / conf.updateInterval;
                        [__motionManager startDeviceMotionUpdatesToQueue:_deviceMotionQueue withHandler:^(CMDeviceMotion *motion, NSError *error){
                            // TODO: compose arguments and send
                            
                        }];
                    }
                    else if(!__motionManager.isDeviceMotionAvailable && (conf.sensors & TMFMotionSensorDeviceMotion))  {
                        TMFLogError(@"DeviceMotion not available.");
                    }

                    self.running = __motionManager.accelerometerActive || __motionManager.gyroActive || __motionManager.magnetometerActive || __motionManager.deviceMotionActive;
                }
                else {
                    localError = [TMFError errorForCode:TMFCommandErrorCode message:@"Could not start motion service with update intervall <= 0.0." userInfo:nil];
                }
            }
        }

        if(completionBlock) {
            completionBlock(localError);
        }
    }];
}

- (void)stop:(stopCompletionBlock_t)completionBlock {
    [super stop:^{
        if(__motionManager.accelerometerActive) {
            [__motionManager stopAccelerometerUpdates];
        }

        if(__motionManager.gyroActive) {
            [__motionManager stopGyroUpdates];
        }

        if(__motionManager.magnetometerActive) {
            [__motionManager stopMagnetometerUpdates];
        }

        if(__motionManager.deviceMotionActive) {
            [__motionManager stopDeviceMotionUpdates];
        }

        __motionManager = nil;
        self.running = NO;

        if(completionBlock) {
            completionBlock();
        }
    }];
}
#endif

- (BOOL)shouldRestartOnConfigurationUpdate {
    return YES;
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
@end


// ------------------------------------------------------------------------------------------------------------------------------------------------- //

@implementation TMFMotionCommandConfiguration
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

@implementation TMFMotionCommandArguments
+ (TMFMotionCommandArguments *)argumentsWithX:(double)x y:(double)y z:(double)z sensor:(TMFSensor)sensor {
    TMFMotionCommandArguments *arguments = [TMFMotionCommandArguments new];
    arguments.x = x;
    arguments.y = y;
    arguments.z = z;
    arguments.sensor = sensor;
    return arguments;
}
@end
