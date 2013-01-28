//
//  TMFLocationCommand.m
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

#import "TMFLocationCommand.h"
#import "TMFLog.h"
#import "TMFError.h"

#ifdef __CORELOCATION__
static CLLocationManager *__locationManager;

@interface TMFLocationCommand() <CLLocationManagerDelegate>
@end
#endif

@implementation TMFLocationCommand
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
+ (NSString *)name {
    return @"tmf_loc";
}

+ (BOOL)isReliable {
    return YES;
}

+ (TMFConfiguration *)defaultConfiguration {
    TMFLocationCommandConfiguration *configuration = [TMFLocationCommandConfiguration new];
    configuration.accuracy = TMFLocationAccuracyBest;
    configuration.onLocationChangeOnly = YES;
    return configuration;
}

#ifdef __CORELOCATION__
- (void)start:(startCompletionBlock_t)completionBlock {
    [super start:^(NSError *error){
        __block NSError *localError = error;
        if(!localError) {
            if([CLLocationManager locationServicesEnabled]) {
                if(__locationManager == nil) {
                    __locationManager = [[CLLocationManager alloc] init];
                }
                __locationManager.delegate = self;
                __locationManager.desiredAccuracy = [self convertAccuracy:self.configuration.accuracy];

                if(self.configuration.onLocationChangeOnly) {
                    [__locationManager startMonitoringSignificantLocationChanges];
                }
                else {
                    [__locationManager startUpdatingLocation];
                }

                self.running = YES;
            }
            else {
                localError = [TMFError errorForCode:TMFCommandErrorCode message:@"Could not start location services" userInfo:nil];
                [self stop:nil];
            }
        }

        if(completionBlock) {
            completionBlock(localError);
        }
    }];
}

- (void)stop:(stopCompletionBlock_t)completionBlock {
    [super stop:^{
        [__locationManager stopUpdatingLocation];
        if(completionBlock) {
            completionBlock();
        }
    }];
}
#endif

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................
#pragma mark CLLocationManagerDelegate
#ifdef __CORELOCATION__
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    TMFLocationCommandArguments *args = [TMFLocationCommandArguments new];
    args.latitude = newLocation.coordinate.latitude;
    args.longitude = newLocation.coordinate.longitude;
    args.altitude = newLocation.altitude;
    args.speed = newLocation.speed;
    args.course = newLocation.course;
    args.timestamp = newLocation.timestamp;
    [self sendWithArguments:args];
}
#endif

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
#ifdef __CORELOCATION__
- (CLLocationAccuracy)convertAccuracy:(TMFLocationAccuracy)accuracyIn {
    switch (accuracyIn) {
        case TMFLocationAccuracyBestForNavigation: {
            return kCLLocationAccuracyBestForNavigation;
        }
            break;

        case TMFLocationAccuracyBest: {
            return kCLLocationAccuracyBest;
        }
            break;

        case TMFLocationAccuracyNearestTenMeters: {
            return kCLLocationAccuracyNearestTenMeters;
        }
            break;

        case TMFLocationAccuracyHundredMeters: {
            return kCLLocationAccuracyHundredMeters;
        }
            break;

        case TMFLocationAccuracyKilometer: {
            return kCLLocationAccuracyKilometer;
        }
            break;

        case TMFLocationAccuracyThreeKilometers: {
            return kCLLocationAccuracyThreeKilometers;
        }
            break;

        default:
            return kCLLocationAccuracyBestForNavigation;
            break;
    }
}
#endif

@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

@implementation TMFLocationCommandConfiguration
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

@implementation TMFLocationCommandArguments
@end
