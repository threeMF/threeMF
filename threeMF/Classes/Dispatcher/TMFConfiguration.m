//
//  TMFConfiguration.m
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

#import "TMFConfiguration.h"

static NSSet *__notSerializable;

@implementation TMFConfiguration
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
        __notSerializable = [NSSet setWithArray:@[ @"sender" ]];
    });
    return __notSerializable;
}

- (NSMutableDictionary *)serializedObject {
    if(![[self class] isSubclassOfClass:[TMFConfiguration class]]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ has to be overwritten in a subclass.", NSStringFromSelector(_cmd)]
                                     userInfo:nil];
    }
    return [super serializedObject];
}

- (void)updateFromSerializedObject:(NSDictionary *)serializedObject {
    [super updateFromSerializedObject:serializedObject];
    if(![[self class] isSubclassOfClass:[TMFConfiguration class]]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ has to be overwritten in a subclass.", NSStringFromSelector(_cmd)]
                                     userInfo:nil];
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
