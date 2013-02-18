//
//  CADClient.m
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

#import "CADClient.h"

@interface CADClient() {
    CADBezierPath *_currentPath;
    NSMutableArray *_paths;
    NSMutableArray *_redoStack;
}
@end

@implementation CADClient

//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    self = [super init];
    if(self) {
        _paths = [[NSMutableArray alloc] init];
        _redoStack = [[NSMutableArray alloc] init];
    }
    return self;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)enumeratePaths:(void (^)(CADBezierPath *))block {
    if(block) {
        for(CADBezierPath *path in [_paths copy]) {
            block(path);
        }
    }
}

- (void)startPath {
    _currentPath = [[CADBezierPath alloc] initWithColor:_color];    
    _currentPath.color = _color;
    [_currentPath moveToPoint:_location];
}

- (void)endPath {
    [_paths addObject:_currentPath];  
    _currentPath = nil;
}

- (void)clear {
    [_paths removeAllObjects];
    [_redoStack removeAllObjects];
}

- (void)undo {
    if([_paths count] > 0) {
        CADBezierPath *lastPath = [_paths lastObject];
        [_redoStack addObject:lastPath];
        [_paths removeObject:lastPath];
    }
}

- (void)redo {
    if([_redoStack count]>0) {
        CADBezierPath *lastPath = [_redoStack lastObject];        
        [_paths addObject:lastPath];
        [_redoStack removeObject:lastPath];
    }
}

- (CADBezierPath *)currentPath {
    return _currentPath;
}

- (NSArray *)paths {
    return [NSArray arrayWithArray:_paths]; // immutable
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)setName:(NSString *)name {
    if(name != _name) {
        _name = name;
        [self update];
    }
}

- (void)setColor:(NSColor *)color {
    if(color != _color) {
        _color = color;
        [self update];
    }
}

- (void)setLocation:(CGPoint)location {
    _location = location;
    if(_currentPath) { // in drawing mode if we have a _currentPath ref
        [_currentPath lineToPoint:location];
    }
}

- (BOOL)isEqual:(id)object {
    if(self == object) {
        return YES;
    }
    
    if([object isKindOfClass:[self class]]) {
        return [((CADClient *)object).peer isEqual:self.peer];
    }
    
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - %@ %@ %@", _peer, _name, NSStringFromPoint(NSPointFromCGPoint(_location)), _color];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)update {
    self.menuItem.attributedTitle = [[NSAttributedString alloc] initWithString:(self.name ? self.name : @"")
                                                                    attributes:@{ NSForegroundColorAttributeName : (self.color ? self.color : [NSColor blackColor]) }];
}


@end
