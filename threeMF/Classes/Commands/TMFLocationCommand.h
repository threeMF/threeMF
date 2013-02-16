//
//  TMFLocationCommand.h
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
#ifndef __CORELOCATION__
#warning Import <CoreLocation.framework> in your project's -Prefix.pch file to use the TMFLocationCommand
#endif
#endif

/**
 Enum mapping CoreLocation accuracy values
 */
typedef enum TMFLocationAccuracy {
    TMFLocationAccuracyBestForNavigation,
    TMFLocationAccuracyBest,
    TMFLocationAccuracyNearestTenMeters,
    TMFLocationAccuracyHundredMeters,
    TMFLocationAccuracyKilometer,
    TMFLocationAccuracyThreeKilometers
} TMFLocationAccuracy;

/**
 Configuration class setting up the TMFLocationCommand
 */
@interface TMFLocationCommandConfiguration : TMFConfiguration

/**
 Accuracy setting for the core location manager.
 */
@property (nonatomic) TMFLocationAccuracy accuracy;

/**
 Defines if updates should only be recorded if the location is changed.
 Otherwise the location will get reported frequently.
 */
@property (nonatomic) BOOL onLocationChangeOnly;

@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Command pushing location information from mobile devices via CoreLocation.
 The corresponding arguments class is TMFLocationCommandArguments.

 - unique name: tmf_loc
 - reliable

 ##Default configuration
 - accuracy: TMFLocationAccuracyBest
 - onLocationChangeOnly: YES

 @warning Make sure you import <CoreLocation/CoreLocation.h> to your project's -Prefix.pch file if you want to provide this command!
 */
@interface TMFLocationCommand : TMFPublishSubscribeCommand

/**
 The configuration used for core location.
 */
@property (nonatomic, strong) TMFLocationCommandConfiguration *configuration;

@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Arguments class for TMFLocationCommand
 */
@interface TMFLocationCommandArguments : TMFArguments
/**
 Latitude of the location.
 */
@property (nonatomic) double latitude;

/**
 Longitude of the location.
 */
@property (nonatomic) double longitude;

/**
 Altitude of the location.
 */
@property (nonatomic) double altitude;

/**
 Current movement speed.
 */
@property (nonatomic) double speed;

/**
 Current movement course.
 */
@property (nonatomic) double course;

/**
 Corresponding time stamp for the location record.
 */
@property (nonatomic, strong) NSDate *timestamp;

@end
