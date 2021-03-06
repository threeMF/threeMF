//
//  TMFMultiTouchCommand.m
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

#import "TMFMultiTouchCommand.h"

@implementation TMFMultiTouchCommand
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
    return @"tmf_mt";
}

+ (BOOL)isReliable {
    return YES;
}

+ (BOOL)isRealtime {
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

@implementation TMFMultiTouchCommandArguments
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

static NSSet *__notSerializable;

@implementation TMFTouch
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
- (NSSet *)notSerializableKeys {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __notSerializable = [NSSet setWithObject:@"location"];
    });
    return __notSerializable;
}

- (NSMutableDictionary *)serializedObject {
    NSMutableDictionary *serializedObject = [super serializedObject];
#if TARGET_OS_IPHONE
    [serializedObject setObject:NSStringFromCGPoint(self.location) forKey:@"location"];
#else
    [serializedObject setObject:NSStringFromPoint(NSPointFromCGPoint(self.location)) forKey:@"location"];
#endif
    return serializedObject;
}

- (void)updateFromSerializedObject:(NSDictionary *)serializedObject {
    [super updateFromSerializedObject:serializedObject];
    NSString *location = [serializedObject objectForKey:@"location"];
    if([location isKindOfClass:[NSString class]]) {
#if TARGET_OS_IPHONE
        self.location = CGPointFromString(location);
#else
        self.location = NSPointFromString(location);
#endif
    }
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