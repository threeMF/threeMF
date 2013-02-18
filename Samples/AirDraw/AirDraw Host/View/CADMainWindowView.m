//
//  CADMainWindowView.m
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

#import "CADMainWindowView.h"
#import "CADPointerLayer.h"
#import "CADBezierPath.h"
#import "CALayer+CADDrawing.h"
#import "CAShapeLayer+CADDrawing.h"
#import <Quartz/Quartz.h>
#import "CADClient.h"

#define FRAME_LAYERS 0
CGPathRef createCGPathFromNSBezierPath(NSBezierPath *bpath);

CGPathRef createCGPathFromNSBezierPath(NSBezierPath *bpath) {
    int i, numElements;

    // Need to begin a path here.
    CGPathRef           immutablePath = NULL;

    // Then draw the path elements.
    numElements = (int)[bpath elementCount];
    if (numElements > 0)
    {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];

        for (i = 0; i < numElements; i++)
        {
            switch ([bpath elementAtIndex:i associatedPoints:points])
            {
                case NSMoveToBezierPathElement:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;

                case NSLineToBezierPathElement:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    break;

                case NSCurveToBezierPathElement:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                          points[1].x, points[1].y,
                                          points[2].x, points[2].y);
                    break;

                case NSClosePathBezierPathElement:
                    CGPathCloseSubpath(path);
                    break;
            }
        }

        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    
    return immutablePath;
}


@interface CADMainWindowView() {
    CALayer *_backingLayer;
    NSMutableDictionary *_pointers;
    NSMutableDictionary *_canvases;
}
- (void)defaultInit;
@end

@implementation CADMainWindowView

//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    self = [super init];
    if(self) {
        [self defaultInit];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if(self) {
        [self defaultInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self defaultInit];        
    }
    return self;
}

- (void)defaultInit {    
    _pointers = [NSMutableDictionary new];
    _canvases = [NSMutableDictionary new];
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)updateClient:(CADClient *)client {
    CADPointerLayer *clientPointer = [self pointerForClient:client];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    clientPointer.position = client.location;
    clientPointer.nameLayer.string = client.name;
    [clientPointer.nameLayer setForegroundColor:client.color.CGColor];
    [clientPointer setFillColorWithNSColor:client.color];
    [self drawCurrentPath:client];
    [self updateCanvas:client];
    [CATransaction commit];
}

- (void)removeClient:(CADClient *)client {
    [CATransaction begin];
    [[_pointers objectForKey:client.peer.UUID] removeFromSuperlayer];
    [[_canvases objectForKey:client.peer.UUID] removeFromSuperlayer];

    [_pointers removeObjectForKey:client.peer.UUID];
    [_canvases removeObjectForKey:client.peer.UUID];
    [CATransaction commit];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)awakeFromNib {
    [super awakeFromNib];
    // make view layer backed
    _backingLayer = [CAShapeLayer layer];
    _backingLayer.bounds = self.bounds;
    _backingLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    _backingLayer.position = CGPointZero;
    _backingLayer.delegate = self;     
#if FRAME_LAYERS    
    _backingLayer.borderWidth = 2.0f;
    [_backingLayer setBorderColorWithNSColor:[NSColor redColor]];
#endif    
    [self setLayer:_backingLayer];
    [self setWantsLayer:YES];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)drawCurrentPath:(CADClient *)client {
    CAShapeLayer *canvas = [self canvasForClient:client];
    CGPathRef path = createCGPathFromNSBezierPath(client.currentPath);
    canvas.path = path;
    CGPathRelease(path);
    [canvas setStrokeColorWithNSColor:client.color];
#if FRAME_LAYERS
    canvas.borderWidth = 2.0f;
    [canvas setBorderColorWithNSColor:client.color];
#endif
    [canvas setNeedsDisplay];
}

- (void)updateCanvas:(CADClient *)client {
    CAShapeLayer *canvas = [self canvasForClient:client];
    NSUInteger pathCount = [client.paths count];
    NSUInteger pathLayersCount = [[canvas sublayers] count];
    
    if(pathLayersCount < pathCount) { // new path -> persist
        CADBezierPath *bezierPath = (CADBezierPath *)[client.paths lastObject];
        CAShapeLayer *pathLayer = [CAShapeLayer new];
        CGPathRef path = createCGPathFromNSBezierPath(bezierPath);
        pathLayer.path = path;
        CGPathRelease(path);
        [pathLayer setFillColorWithNSColor:[NSColor clearColor]];
        [pathLayer setStrokeColorWithNSColor:bezierPath.color];
        [canvas addSublayer:pathLayer];
    }
    else if(pathLayersCount > pathCount) { // path gone -> remove
        [[[canvas sublayers] lastObject] removeFromSuperlayer];
    }
    else if(pathCount == 0 && client.currentPath == NULL) {
        [canvas removeFromSuperlayer];
        [_canvases removeObjectForKey:client.peer.UUID];
        canvas = nil;
    }
}

- (CADPointerLayer *)pointerForClient:(CADClient *)client {
    CADPointerLayer *clientPointer = [_pointers objectForKey:client.peer.UUID];
    if(!clientPointer) {
        clientPointer = [CADPointerLayer layer];
        CGPathRef path = createCGPathFromNSBezierPath([CADBezierPath bezierPathWithOvalInRect:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)]);
        clientPointer.path = path;
        CGPathRelease(path);
        [clientPointer setMasksToBounds:NO];
        [_pointers setObject:clientPointer forKey:client.peer.UUID];
        [_backingLayer addSublayer:clientPointer];
    }
    return clientPointer;
}

- (CAShapeLayer *)canvasForClient:(CADClient *)client {
    CAShapeLayer *canvas = [_canvases objectForKey:client.peer.UUID];
    if(!canvas) {
        // create canvas
        canvas = [CAShapeLayer layer];
        [canvas setLineWidth:2.0f];
        [canvas setFillColorWithNSColor:[NSColor clearColor]];

        [_canvases setObject:canvas forKey:client.peer.UUID];
        [_backingLayer addSublayer:canvas];
    }
    return canvas;
}

@end
