//
//  SFMainWindowView.m
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

#import "SFMainWindowView.h"
#import <Quartz/Quartz.h>
#import "CALayer+CADDrawing.h"
#import "CAShapeLayer+CADDrawing.h"

#define ZOOM_IMAGE_PADDING 5.0f

CGPathRef CreatePathRefFromBezierPath(NSBezierPath *bPath) {
    int i, numElements;

    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;

    // Then draw the path elements.
    numElements = (int)[bPath elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];
        BOOL                didClosePath = YES;

        for (i = 0; i < numElements; i++)
        {
            switch ([bPath elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;

                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;

                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    didClosePath = NO;
                    break;

                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }

        if (!didClosePath)
            CGPathCloseSubpath(path);

        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
}

NSString * const SFMainWindowViewWindowMovedNotification = @"SFMainWindowViewWindowMovedNotification";

@interface SFMainWindowView() {
    CALayer *_backingLayer;
    CAShapeLayer *_zoomIndicatorLayer;  
    CALayer *_zoomImageLayer;     
    CAShapeLayer *_touchIndicatorLayer;
    
    BOOL _dragging;
    BOOL _dragged;
    NSPoint _originalMouseLocation;
    NSRect _originalFrame;     
}

@end

@implementation SFMainWindowView
@synthesize zoomRect = _zoomRect;

//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................


//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)displayTouchAt:(NSPoint)point {
    _touchIndicatorLayer.position = CGPointMake(point.x, CGRectGetHeight(self.bounds) - point.y);
    CGPoint center = CGPointMake(CGRectGetMidX(_touchIndicatorLayer.bounds), CGRectGetMidY(_touchIndicatorLayer.bounds));
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"path"];

    CGPathRef fromPath = CreatePathRefFromBezierPath([NSBezierPath bezierPathWithOvalInRect:(CGRect){{center.x - 1.0f, center.y - 1.0f}, {2.0f, 2.0f}}]);
    CGPathRef toPath = CreatePathRefFromBezierPath([NSBezierPath bezierPathWithOvalInRect:_touchIndicatorLayer.bounds]);
    animation.fromValue = (__bridge id)fromPath;
    animation.toValue = (__bridge id)toPath;
    CGPathRelease(fromPath);
    CGPathRelease(toPath);

    animation.duration = 0.4;
    animation.autoreverses = YES;
    [_touchIndicatorLayer addAnimation:animation forKey:@"tapAnimation"];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)awakeFromNib {
    [super awakeFromNib];
    // make view layer backed
    _backingLayer = [CALayer layer];
    _backingLayer.bounds = self.bounds;
    _backingLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _backingLayer.position = CGPointZero;
    _backingLayer.delegate = self;     
    _backingLayer.borderWidth = 1.0f;
    [_backingLayer setBorderColorWithNSColor:[NSColor redColor]];
        
    _zoomIndicatorLayer = [CAShapeLayer layer];
    _zoomIndicatorLayer.bounds = self.bounds;
    _zoomIndicatorLayer.position = CGPointZero;
    _zoomIndicatorLayer.anchorPoint = CGPointMake(0.0f, 0.0f);
    [_zoomIndicatorLayer setNeedsDisplayOnBoundsChange:YES];
    [_zoomIndicatorLayer setStrokeColorWithNSColor:[NSColor redColor]];
    [_zoomIndicatorLayer setFillColorWithNSColor:[NSColor clearColor]];
    _zoomIndicatorLayer.lineDashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInt:2], [NSNumber numberWithInt:3], nil];
    _zoomIndicatorLayer.lineWidth = 2.0f;
    [_backingLayer addSublayer:_zoomIndicatorLayer];    
    
    NSImage *zoomImage = [NSImage imageNamed:@"zoom-in.png"];
    _zoomImageLayer = [CALayer layer];
    _zoomImageLayer.contents = (id)zoomImage;
    _zoomImageLayer.frame = CGRectMake(-zoomImage.size.width, -zoomImage.size.height, zoomImage.size.width, zoomImage.size.height);
    _zoomImageLayer.anchorPoint = CGPointMake(1.0f, 1.0f);
    _zoomImageLayer.opacity = 0.3f;
    [_backingLayer addSublayer:_zoomImageLayer]; 
    
    _touchIndicatorLayer = [CAShapeLayer layer];
    _touchIndicatorLayer.bounds = CGRectMake(0.0f, 0.0f, 20.0f, 20.0f);
    _touchIndicatorLayer.position = CGPointZero;
    _touchIndicatorLayer.anchorPoint = CGPointMake(0.5f, 0.5f);
    [_touchIndicatorLayer setFillColorWithNSColor:[NSColor redColor]];
    [_backingLayer addSublayer:_touchIndicatorLayer];
    
    [_touchIndicatorLayer setBorderColorWithNSColor:[NSColor blueColor]];
    _touchIndicatorLayer.borderWidth = 1.0f;
    
    [self setLayer:_backingLayer];
    [self setWantsLayer:YES];
}

- (void)setZoomRect:(CGRect)zoomRect {        
    [CATransaction begin];
    [CATransaction setDisableActions:YES];    
    BOOL hide = CGPointEqualToPoint(CGPointZero, zoomRect.origin);
    _zoomImageLayer.hidden = hide;
    _zoomIndicatorLayer.hidden = hide;
    CGPathRef path = CreatePathRefFromBezierPath([NSBezierPath bezierPathWithRect:zoomRect]);
    _zoomIndicatorLayer.path = path;
    CGPathRelease(path);
    _zoomImageLayer.position = CGPointMake(CGRectGetMaxX(zoomRect) - ZOOM_IMAGE_PADDING, CGRectGetMaxY(zoomRect) - ZOOM_IMAGE_PADDING);            
    [CATransaction commit];
}

- (void)mouseDown:(NSEvent *)event {    
    NSWindow *window = [self window];
    _originalMouseLocation = [window convertBaseToScreen:[event locationInWindow]];
    _originalFrame = [window frame];        
    _dragging = YES;
}

- (void)mouseDragged:(NSEvent *)event {
    if(_dragging) {
        NSWindow *window = [self window];            
        NSPoint newMouseLocation = [window convertBaseToScreen:[event locationInWindow]];
		NSPoint delta = NSMakePoint(newMouseLocation.x - _originalMouseLocation.x,
                                    newMouseLocation.y - _originalMouseLocation.y);
		
		NSRect newFrame = _originalFrame;
		newFrame.origin.x += delta.x;
		newFrame.origin.y += delta.y;		
		[window setFrame:newFrame display:YES animate:NO];
        _dragged = YES;
    }
}

- (void)mouseUp:(NSEvent *)event {
    _dragging = NO;
    if(_dragged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SFMainWindowViewWindowMovedNotification object:self];
        _dragged = NO;
    }
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

@end
