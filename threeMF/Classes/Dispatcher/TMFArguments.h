//
//  TMFArguments.h
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
#import "TMFSerializableObject.h"

/**
 A abstract class representing arguments for TMFCommand.
 
 ## Custom Arguments
 - Create a class named *CommandName*Arguments (or different if specified in [TMFCommand argumentsClass])
 - Add strong read write properties of the types described in TMFSerializable

 All properties get serialized automatically. All other types can be serialized manually by overriding [TMFSerializable serializedObject] and [TMFSerializable updateFromSerializedObject:]. You can also exclude keys from serialization by overriding [TMFSerializableObject notSerializableKeys] (weak and readonly properties are **not** serialized).

 Simple arguments class: TMFKeyValueCommandArguments, TMFImageCommandArguments, TMFLocationCommandArguments, TMFMotionCommandArguments
 Extended arguments class: TMFMultiTouchCommandArguments
 
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

 @warning Arguments classes should follow a specific naming convention if no custom [TMFCommand argumentsClass] is given.
 */
@interface TMFArguments : TMFSerializableObject

/**
 TMFRequest identifier
 */
@property (nonatomic) NSInteger identifier;

/**
 An **alphabetical ordered** list of all serializable property values.
 This list is used for RPC transmission instead of key values pairs.
 */
@property (nonatomic, readonly) NSArray *argumentList;

/**
 Creates a new instance based on an **alphabetical ordered** list of property values.
 @param list The list of **alphabetical ordered** property value.
 @return The new arguments object based on the parameter list.
 */
- (id)initWithArgumentList:(NSArray *)list;

/**
 Popupates the instance with values from a given **alphabetical ordered** list of properties.
 @param list The list of **alphabetical ordered** property value.
 */
- (BOOL)updateFromArgumentList:(NSArray *)list;

@end
