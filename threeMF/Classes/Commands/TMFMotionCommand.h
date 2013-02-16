//
//  TMFMotionCommand.h
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

#ifdef threeMF_threeMF_h
#if TARGET_OS_IPHONE
#ifndef __COREMOTION__
#warning Import <CoreMotion.framework> in your project's -Prefix.pch file to use the TMFMotionCommand
#endif
#endif
#endif

// TODO: add filter support
typedef enum {
    TMFMotionDataFilterNone = 0,
//    TMFMotionDataFilterLowPass = 1,
//    TMFMotionDataFilterHighPass = 2
} TMFMotionDataFilter;

typedef enum {
    TMFSensorAccelerometer = 0,
    TMFSensorGyroscope = 1,
    TMFSensorMagnetomenter = 2
} TMFSensor;

enum {
    TMFMotionSensorNone             = 0,
    TMFMotionSensorAccelerometer    = 1 << 0,
    TMFMotionSensorGyroscope        = 1 << 1,
    TMFMotionSensorMagnetometer     = 1 << 2,
    TMFMotionSensorDeviceMotion     = 1 << 3
};
typedef NSUInteger TMFMotionSensor;

/**
 TMFMotionCommand configuration
 */
@interface TMFMotionCommandConfiguration : TMFConfiguration
/**
 The filter used for this subscription.
 */
@property (nonatomic) TMFMotionDataFilter filter;
/**
 The motion sensor used for this subscription.
 */
@property (nonatomic) TMFMotionSensor sensors;
/**
 The motion sensor's update interval in Hz.
 @warning a high refresh rate can flood the network
 */
@property (nonatomic) double updateInterval;
/**
 A minimum threshold value. The provider will not send data below
 this values.
 */
@property (nonatomic) double threshold;
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Command responsible for the delivery of motion (Accelerometer, Gyroscope, Magnetometer) data via CoreMotion.
 The corresponding arguments class is TMFMotionCommandArguments.

 - unique name: tmf_motion
 - unreliable

 ## Default configuration
 - updateInterval = 0.0
 - sensors = TMFMotionSensorNone
 - filter = TMFMotionDataFilterNone
 
 @warning Provide a configuraiton when subscribing.
 
     _tmf = [TMFConnector new];
     _tmf.delegate = self;

     TMFMotionCommandConfiguration *conf = [TMFMotionCommandConfiguration new];
     conf.sensors = TMFMotionSensorAccelerometer | TMFMotionSensorGyroscope;
     conf.updateInterval = 15;
 
     [_tmf subscribe:[TMFMotionCommand class] configuration:conf peer:peer 
        receive:^(TMFMotionCommandArguments *arguments, TMFPeer *peer) {
            TMFLog(@"sensor: %@ {%@, %@, %@}", @(arguments.sensor), @(arguments.x), @(arguments.y), @(arguments.z));
        }
        completion:NULL];


 @warning Make sure you import <CoreMotion/CoreMotion.h> to your project's -Prefix.pch file if you want to provide this command!
 */
@interface TMFMotionCommand : TMFPublishSubscribeCommand
/**
 Configuration for the core motion manager.
 */
@property (nonatomic, strong) TMFMotionCommandConfiguration *configuration;
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Arguments class for TMFMotionCommand.
 */
@interface TMFMotionCommandArguments : TMFArguments
/**
 The x axis value.
 */
@property (nonatomic) double x;

/**
 The y axis value.
 */
@property (nonatomic) double y;

/**
 The z axis value.
 */
@property (nonatomic) double z;

/**
 The sensor providing this value.
 */
@property (nonatomic) TMFSensor sensor;

/**
 Creates a TMFMotionCommandArguments instance with the given parameters.
 @param x The x axis value of the motion.
 @param y The y axis value of the motion.
 @param z The z axis value of the motion.
 @param sensor The sensor creating this arguments object.
 */
+ (TMFMotionCommandArguments *)argumentsWithX:(double)x y:(double)y z:(double)z sensor:(TMFSensor)sensor;
@end
