//
//  TMFSerializable.h
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

/**
 Macro converting nil values to NSNull.
 NSDictionarys can not contain nil as value, so NSNull acts as an placeholder for optional parameters.
 */
#define NSNullIfNil(o)          (o ? o : [NSNull null])

/**
 Macro converting NSNull to nil.
 NSDictionarys can not contain nil as value, so NSNull acts as an placeholder for optional parameters.
 */
#define NilIfNSNull(o)          ([[NSNull null] isEqual:o] ? nil : o)

/**
 This protocol defines defautl 3MF de- serialization.
 TMFSerializable has to be adapted by each object that should be able to transmittet to any TMFPeer.
 Each de-/serialization should be JSON compatible.
 */
@protocol TMFSerializable <NSObject>
@required

/**
 NSMutableDictionary representation of an object.
*/
@property (nonatomic, readonly) NSMutableDictionary *serializedObject;
/**
 Creates a new instance of an object based on a NSDictionary representation of the object
 @param serializedObject dictionary representation
 @return a new instance
 */
- (id)initWithSerializedObject:(NSDictionary *)serializedObject;

/**
 Updates an instance based on a NSDictionary representation.
 @param serializedObject dictionary representation
 */
- (void)updateFromSerializedObject:(NSDictionary *)serializedObject;

@end
