//
//  MACCamera.h
//  MultiAirCam
//
//  Created by Martin Gratzer on 11.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 Adapted from https://developer.apple.com/library/ios/#samplecode/AVCam/Introduction/Intro.html#//apple_ref/doc/uid/DTS40010112
 */

@class MACCamera;

@protocol MACCameraDelegate <NSObject>
@required
- (void)cameraStillImageCaptured:(MACCamera *)captureManager image:(UIImage *)image;
- (void)cameraPreviewImageCaptured:(MACCamera *)captureManager image:(UIImage *)image;
- (void)camera:(MACCamera *)captureManager didFailWithError:(NSError *)error;
@end

@interface MACCamera : NSObject

@property (nonatomic, weak) NSObject<MACCameraDelegate> *delegate;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, assign) AVCaptureVideoOrientation orientation;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

- (BOOL)setupSession;
- (void)captureStillImage;
- (void)capturePreviewImage;
- (BOOL)toggleCamera;
- (NSUInteger)cameraCount;

- (void)toggleFlash;
- (void)toggleTorch;

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
+ (BOOL)hasCamera;
@end
