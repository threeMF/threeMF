//
//  SFAppDelegate.m
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

#import "SFAppDelegate.h"
#import "threeMF.h"
#import "TMFImageCommand.h"
#import "TMFKeyValueCommand.h"
#import "TMFMultiTouchCommand.h"
#import "SFAnnounceCommand.h"
#import <QuartzCore/QuartzCore.h>

NSData * jpegDataWithCGImage(CGImageRef cgImage, CGFloat compressionQuality) {
    NSData *jpegData = nil;
    
    CFMutableDataRef      data = CFDataCreateMutable(NULL, 0);
    CGImageDestinationRef idst = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, NULL);
    if (idst) {
        NSDictionary *props = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:compressionQuality], kCGImageDestinationLossyCompressionQuality,/* [NSNumber numberWithInteger:1], kCGImagePropertyOrientation,*/ nil];
        
        CGImageDestinationAddImage(idst, cgImage, (__bridge CFDictionaryRef)props);
        if (CGImageDestinationFinalize(idst)) {
            jpegData = [NSData dataWithData:(__bridge NSData *)data];
        }
        CFRelease(idst);
    }
    CFRelease(data);
    
    return jpegData;
}

CGRect CGRectWithSize(CGPoint center, CGSize size) {
    return CGRectMake(center.x - (size.width * 0.5f), center.y - (size.height * 0.5f), size.width, size.height);
}

CGPoint CGRectCenter(CGRect r) {
    return CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));
}

@interface SFAppDelegate() <NSWindowDelegate, TMFConnectorDelegate> {
    TMFConnector *_tmf;
    SFAnnounceCommand *_announceCommand;
    TMFImageCommand *_imageCommand;
    TMFPeer *_host;
}
@end

@implementation SFAppDelegate
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
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setup];    
    [_window setLevel:NSFloatingWindowLevel]; // in front of all other windows
    _window.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowMoved:) name:SFMainWindowViewWindowMovedNotification object:_window.screenView];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidResignActive:(NSNotification *)notification {
    [_window setLevel:NSFloatingWindowLevel]; // keep window in front of all others
}

#pragma mark NSWindowDelegate
- (void)windowDidResize:(NSNotification *)notification {
    [self sendScreeShot];      
}

#pragma mark TMFConnectorDelegate
- (void)connector:(TMFConnector *)tmf didRemoveSubscriber:(TMFPeer *)peer fromCommand:(TMFPublishSubscribeCommand *)command {
    _host = nil;
    [self setWindowSize:NSMakeSize(0.0f, 0.0f)];
}

- (void)connector:(TMFConnector *)tmf didAddSubscriber:(TMFPeer *)peer forCommand:(TMFPublishSubscribeCommand *)command {
    if([command isKindOfClass:[TMFImageCommand class]]) {
        [self sendScreeShot];
    }
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)setWindowSize:(NSSize)size {
    CGRect frame = CGRectWithSize(CGRectCenter(_window.frame), size);
    [[_window animator] setFrame:NSRectFromCGRect(frame) display:YES];  
}

- (void)setZoomRect:(NSRect)rect {
    _window.screenView.zoomRect = CGRectMake(rect.origin.x, -(rect.origin.y - _window.screenView.frame.size.height + rect.size.height), rect.size.width, rect.size.height);
}

- (void)receiveTouch:(TMFTouch *)touch performClick:(BOOL)performClick {
    NSPoint touchPoint = NSMakePoint(touch.location.x * _window.screenView.frame.size.width, touch.location.y *_window.screenView.frame.size.height);
    [_window.screenView displayTouchAt:touchPoint];    

    NSRect windowRect = NSRectToCGRect([self windowFrame]);
    NSPoint click = NSMakePoint(CGRectGetMinX(windowRect) + touchPoint.x, CGRectGetMinY(windowRect) + touchPoint.y);

    if(performClick) {

        [_window setIgnoresMouseEvents:YES];
        
        // perform a click
        CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
        
        // mouse down
        CGEventRef downEvent = CGEventCreateMouseEvent(source, kCGEventLeftMouseDown, click, kCGMouseButtonLeft);
        CGEventSetType(downEvent, kCGEventLeftMouseDown);
        CGEventPost(kCGHIDEventTap, downEvent);
        CFRelease(downEvent);
        
        // mouse up
        CGEventRef upEvent = CGEventCreateMouseEvent(source, kCGEventLeftMouseDown, click, kCGMouseButtonLeft);
        CGEventSetType(upEvent, kCGEventLeftMouseUp);
        CGEventPost(kCGHIDEventTap, upEvent);
        CFRelease(upEvent);

        CFRelease(source);
        
        [_window setIgnoresMouseEvents:NO];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{ // short delay to get refreshed UI
            [self sendScreeShot];
        });
    }
}

- (void)setup {
    _tmf = [[TMFConnector alloc] initWithCallBackQueue:dispatch_get_current_queue()];
    _tmf.delegate = self;
    
    _announceCommand = [[SFAnnounceCommand alloc] initWithRequestReceivedBlock:^(id arguments, TMFPeer *peer, responseBlock_t responseBlock){
        if(responseBlock && !_host) {
            responseBlock(@(YES), nil);
            [self receivedAnnouncementAnswerFromHost:peer];
        }
        else if(responseBlock && _host) {
            responseBlock(@(NO), [NSError errorWithDomain:@"tmf" code:1 userInfo:@{@"message" : @"Only one host allowed."}]);
        }
    }];

    [_tmf publishCommand:_announceCommand];
    
    _imageCommand = [TMFImageCommand new];
    [_tmf publishCommand:_imageCommand];
}

- (void)subscribeKeyValue:(TMFPeer *)peer {
    // -------------------------------
    // resolution changes
    // -------------------------------
    if([peer.capabilities containsObject:[TMFKeyValueCommand name]]) {
        [_tmf subscribe:[TMFKeyValueCommand class]
                   peer:peer
                receive:^(TMFKeyValueCommandArguments *arguments, TMFPeer *peer){
                    if([arguments.key isEqualToString:@"resolution"]) {
                        [self setWindowSize:NSSizeFromString(arguments.value)];
                    }
                    else if([arguments.key isEqualToString:@"visiblerect"]) {
                        [self setZoomRect:NSRectFromString(arguments.value)];
                    }
                }
             completion:^(NSError *error){
                 if(error) {
                     NSLog(@"%@", error);
                 }
             }];
    }
}

- (void)subscribeMultiTouch:(TMFPeer *)peer {   
    if([peer.capabilities containsObject:[TMFMultiTouchCommand name]]) {
        [_tmf subscribe:[TMFMultiTouchCommand class]
                   peer:peer
                receive:^(TMFMultiTouchCommandArguments *arguments, TMFPeer *peer){
                    if(arguments.phase == TMFMultiTouchPhaseBegin) {
                        [self receiveTouch:[arguments.touches lastObject] performClick:NO];
                    }
                    else if(arguments.phase == TMFMultiTouchPhaseEnded) {
                        [self receiveTouch:[arguments.touches lastObject] performClick:YES];
                    }
                }
             completion:^(NSError *error){
                 if(error) {
                     NSLog(@"%@", error);
                 }
             }];
    }
}

- (void)receivedAnnouncementAnswerFromHost:(TMFPeer *)host {
    if(!_host) {
        _host = host;
        [self subscribeKeyValue:host];
        [self subscribeMultiTouch:host];        
    }
}

- (void)sendScreeShot {       
	CGImageRef screenShot = CGWindowListCreateImage(NSRectToCGRect([self windowFrame]), kCGWindowListOptionOnScreenBelowWindow, (CGWindowID)[_window windowNumber], kCGWindowImageDefault);
    NSData *jpgData = jpegDataWithCGImage(screenShot, 0.1);
    TMFImageCommandArguments *args = [TMFImageCommandArguments new];
    args.data = jpgData;
    args.format = TMFImageFormatJpg;
    [_imageCommand sendWithArguments:args];
    CGImageRelease(screenShot);
}

- (void)windowMoved:(NSNotification *)notification {
    [self sendScreeShot];      
}

- (NSRect)windowFrame {
    CGRect windowRect = [_window frame];
    windowRect.origin.y = NSMaxY([[_window screen] frame]) - NSMaxY([_window frame]);
    return windowRect;
}

@end
