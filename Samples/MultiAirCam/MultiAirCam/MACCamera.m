//
//  MACCamera.m
//  MultiAirCam
//
//  Created by Martin Gratzer on 11.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import "MACCamera.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>

#define radians(degrees) (degrees * M_PI / 180)

static NSString * __previewQuality;
static NSString * __stillQuality;

@interface MACCamera() <AVCaptureVideoDataOutputSampleBufferDelegate> {
    __weak id _deviceConnectedObserver;
    __weak id _deviceDisconnectedObserver;
    UIBackgroundTaskIdentifier _backgroundRecordingID;
    UIImage *_preview;
}

@end

@implementation MACCamera
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __previewQuality = AVCaptureSessionPresetLow;
        __stillQuality = AVCaptureSessionPresetHigh;
    });
}

- (id) init {
    self = [super init];
    if (self) {
		__block id weakSelf = self;
        void (^deviceConnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];

			BOOL sessionHasDeviceWithMatchingMediaType = NO;
			NSString *deviceMediaType = nil;
			if ([device hasMediaType:AVMediaTypeVideo])
                deviceMediaType = AVMediaTypeVideo;

			if (deviceMediaType != nil) {
				for (AVCaptureDeviceInput *input in [self.session inputs]) {
					if ([[input device] hasMediaType:deviceMediaType]) {
						sessionHasDeviceWithMatchingMediaType = YES;
						break;
					}
				}

				if (!sessionHasDeviceWithMatchingMediaType) {
					NSError	*error;
					AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
					if ([self.session canAddInput:input])
						[self.session addInput:input];
				}
			}
        };
        void (^deviceDisconnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
            if ([device hasMediaType:AVMediaTypeVideo]) {
				[self.session removeInput:[weakSelf videoInput]];
				[weakSelf setVideoInput:nil];
			}
        };

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        _deviceConnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification object:nil queue:nil usingBlock:deviceConnectedBlock];
        _deviceDisconnectedObserver = [notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification object:nil queue:nil usingBlock:deviceDisconnectedBlock];

		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		[notificationCenter addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
		_orientation = AVCaptureVideoOrientationPortrait;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.session stopRunning];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (BOOL)setupSession {
    BOOL success = NO;

    [self setFlashMode:AVCaptureFlashModeAuto];

    self.session = [AVCaptureSession new];
    self.session.sessionPreset = __previewQuality;

    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:nil];
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }

    self.stillImageOutput = [AVCaptureStillImageOutput new];
    [self.stillImageOutput setOutputSettings:@{ AVVideoCodecKey : AVVideoCodecJPEG }];
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }

    self.videoDataOutput = [AVCaptureVideoDataOutput new];
    self.videoDataOutput.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };  
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    if([self.session canAddOutput:self.videoDataOutput]) {
        [self.session addOutput:self.videoDataOutput];
        [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    }

    success = YES;
    return success;
}

- (void)captureStillImage {
    AVCaptureTorchMode currentTorchMode = [[self backFacingCamera] torchMode];
    
    self.session.sessionPreset = __stillQuality;
    AVCaptureConnection *stillImageConnection = [MACCamera connectionWithMediaType:AVMediaTypeVideo fromConnections:[self.stillImageOutput connections]];
    if ([stillImageConnection isVideoOrientationSupported]) {
        [stillImageConnection setVideoOrientation:_orientation];
    }

    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                       completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {

															 ALAssetsLibraryWriteImageCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error) {
																 if (error) {
                                                                     [self.delegate camera:self didFailWithError:error];
																 }
															 };

															 if (imageDataSampleBuffer != NULL) {
																 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                                 [self.delegate cameraStillImageCaptured:self image:[[UIImage alloc] initWithData:imageData]];
															 }
															 else {
																 completionBlock(nil, error);
                                                             }

                                                            self.session.sessionPreset = __previewQuality;
                                                            if ([[self.videoInput device] position] == AVCaptureDevicePositionBack) {
                                                                [self setTorchMode:currentTorchMode];
                                                            }
                                                         }];
}

- (void)capturePreviewImage {
    // we do not send high quality images as previews!
    if ([self.session.sessionPreset isEqualToString:__previewQuality]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate cameraPreviewImageCaptured:self image:_preview];
        });
    }
}

// Toggle between the front and back camera, if both are present.
- (BOOL)toggleCamera {
    BOOL success = NO;

    if ([self cameraCount] > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[self.videoInput device] position];

        if (position == AVCaptureDevicePositionBack) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontFacingCamera] error:&error];
        }
        else if (position == AVCaptureDevicePositionFront) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:&error];
        }
        else
            goto bail; // <---- WOHO!

        if (newVideoInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.videoInput];
            if ([self.session canAddInput:newVideoInput]) {
                [self.session addInput:newVideoInput];
                self.videoInput = newVideoInput;
            } else {
                [self.session addInput:self.videoInput];
            }
            [self.session commitConfiguration];
            success = YES;

        } else if (error) {
            [self.delegate camera:self didFailWithError:error];
        }
    }

bail:
    return success;
}

- (NSUInteger)cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (void)toggleFlash {
    AVCaptureDevicePosition position = [[self.videoInput device] position];
    if (position == AVCaptureDevicePositionBack) {
        AVCaptureFlashMode current = [[self backFacingCamera] flashMode];
        AVCaptureFlashMode new = current != AVCaptureFlashModeOff ? AVCaptureFlashModeOff : AVCaptureFlashModeOn;
        [self setFlashMode:new];
    }
}

- (void)toggleTorch {
    AVCaptureDevicePosition position = [[self.videoInput device] position];
    if (position == AVCaptureDevicePositionBack) {
        AVCaptureTorchMode current = [[self backFacingCamera] torchMode];
        AVCaptureTorchMode new = current != AVCaptureTorchModeOff ? AVCaptureTorchModeOff : AVCaptureTorchModeOn;
        [self setTorchMode:new];
    }
}

- (void)setFlashMode:(AVCaptureFlashMode)mode {
	if ([[self backFacingCamera] hasFlash]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
            [[self backFacingCamera] setFlashMode:mode];
			[[self backFacingCamera] unlockForConfiguration];
        }
    }
}

- (void)setTorchMode:(AVCaptureTorchMode)mode {
	if ([[self backFacingCamera] hasTorch]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
            [[self backFacingCamera] setTorchMode:mode];
			[[self backFacingCamera] unlockForConfiguration];
        }
    }
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections {
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
	return nil;
}

+ (BOOL)hasCamera {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    [connection isVideoOrientationSupported];
    if ([self.session.sessionPreset isEqualToString:__previewQuality]) {
        _preview = [self imageFromSampleBuffer:sampleBuffer];
    }
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)frontFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *)backFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (void)deviceOrientationDidChange {
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

	if (deviceOrientation == UIDeviceOrientationPortrait) {
		_orientation = AVCaptureVideoOrientationPortrait;
    }
	else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
		_orientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }
	// AVCapture and UIDevice have opposite meanings for landscape left and right (AVCapture orientation is the same as UIInterfaceOrientation)
	else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
		_orientation = AVCaptureVideoOrientationLandscapeLeft;
    }
	else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
		_orientation = AVCaptureVideoOrientationLandscapeRight;
    }
}

// http://developer.apple.com/library/ios/#qa/qa1702/_index.html
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);

    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);

//    [self rotateContext:context orientation:_orientation];

    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);

    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];

    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void)rotateContext:(CGContextRef)context orientation:(AVCaptureVideoOrientation)orientation {

    if (orientation == UIDeviceOrientationLandscapeRight) {

    } else if (orientation == UIDeviceOrientationLandscapeLeft) {
        CGContextRotateCTM (context, radians(180));
    } else if (orientation == AVCaptureVideoOrientationPortraitUpsideDown) {
        CGContextRotateCTM (context, radians(90));
    } else if (orientation == UIDeviceOrientationPortrait) {
        CGContextRotateCTM (context, radians(-90));
    }
}

@end
