//
//  TMFSerializableObject.h
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
#import "TMFSerializable.h"
/**
 This constant is representing the class key within a serialized dictionary.
 */
NSString * const TMFSerializableObjectClassKey;

/**
 Base class for all serializable objects.

 The serialization is automatic for strong and writable class properties.
 Serialization is triggered on calling [TMFSerializable serializedObject] and deserialization
 can be done by creating a new instance with [TMFSerializable initWithSerializedObject] or
 updating a existing with [TMFSerializable updateFromSerializedObject].

 Properties can get excluded by providing their names in [TMFSerializableObject notSerializableKeys].

 The automatic serialization creates JSON compatible dictionaries.
 Allowed types are:

 - NSString
 - NSNumber objects and primitives like NSInteger, BOOL, CGFloat...
 - NSDate (gets encoded as string)
 - NSData (gets encoded as Base64 string)
 - TMFSerializableObject
 - NSDictionary (can contain any other supported type)
 - NSArray (can contain any other supported type)
 - NSSet (gets encoded as array)

 This class also conforms to NSCoding in order to go beyond the limitations of custom serialization.

 @warning Cycle detection is not implemented. There must not be any direct or transitive parent child object relations.
 */
@interface TMFSerializableObject : NSObject <TMFSerializable, NSCoding, NSCopying>

/**
 Extracts a classes (and it's super classes) property list excluding read only properties and properties contained in notSerializableKeys.
 @return set of serializable class properties.
 */
- (NSSet *)serializableKeys;

/**
 Set of excluding property names used in serializableKeys. Nil by default.
 @return set of not serializable class properties.
 */
- (NSSet *)notSerializableKeys;

/**
 Encodes data structures with valid types.
 @param value The value to encode.
 @return The encoded value.
 */
+ (id)encode:(id)value;

/**
 Decodes encoded data structures.
 @param value The value to decode.
 @return The decoded value.
 */
+ (id)decode:(id)value;

/**
 Encodes binary data for JSON RPC.
 @param dataToEncode The data object to encode.
 @return The data encoded as NSString.
 */
+ (NSString *)encodeBinaryData:(NSData *)dataToEncode;

/**
 Decodes previously encoded binary data from strings to data.
 @param encodedData The data encoded as NSString.
 @return The decoded data.
 */
+ (NSData *)decodeBinaryData:(NSString *)encodedData;

@end