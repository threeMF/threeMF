//
//  TMFSerializableObject.m
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

#import "TMFSerializableObject.h"
#import <objc/runtime.h> 
#import "TMFLog.h"
#import "ybase64.h"

static NSMutableDictionary *__serializableKeysByClass;
static NSMutableDictionary *__propertyTypesByClass;
static NSArray *__numberEncodings;

NSString * const TMFSerializableObjectClassKey = @"_class";

#define kBinaryDataPrefix @"3mf_"
#define kBinaryDataSuffix @"_3mf"

@implementation TMFSerializableObject
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __numberEncodings = @[ @"c", @"i", @"s", @"l", @"q", @"C", @"I", @"S", @"L", @"Q", @"f", @"d", @"B" ];
    });
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if(self) {
        [self updateFromSerializedObject:[aDecoder decodeObject]];
    }
    return self;
}

- (id)initWithSerializedObject:(NSDictionary *)serializedObject {
    if(serializedObject) {
        self = [self init];
        if(self) {
            [self updateFromSerializedObject:serializedObject];
        }
        return self;
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] alloc] initWithSerializedObject:[self serializedObject]];
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (NSSet *)serializableKeys {
    @synchronized([NSObject class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __serializableKeysByClass = [NSMutableDictionary new];
        });

        Class class = [self class];
        NSString *className = NSStringFromClass(class);
        NSMutableSet *keys = [__serializableKeysByClass objectForKey:className];        
        if (keys == nil) {
            keys = [NSMutableSet set];
            unsigned int propertyCount;

            // walk class hierarchy 
            while (class != [NSObject class]) {
                objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
                // extract each property
                for (int i = 0; i < propertyCount; i++) {
                    objc_property_t property = properties[i];
                    NSString *key = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];

                    BOOL isReadOnly = NO;
                    const char *attributes = property_getAttributes(property);
                    NSString *encoding = [NSString stringWithCString:attributes encoding:NSUTF8StringEncoding];
                    if ([[encoding componentsSeparatedByString:@","] containsObject:@"R"]) {
                        isReadOnly = YES;

                        //see if there is a backing ivar with a KVC-compliant name
                        NSRange iVarRange = [encoding rangeOfString:@",V"];
                        if (iVarRange.location != NSNotFound) {
                            NSString *iVarName = [encoding substringFromIndex:iVarRange.location + 2];
                            if ([iVarName isEqualToString:key] || [iVarName isEqualToString:[@"_" stringByAppendingString:key]]) {
                                isReadOnly = NO;
                            }
                        }
                    }

                    if (!isReadOnly) {
                        [keys addObject:key];
                    }
                }
                free(properties);
                class = [class superclass];
            }
            // cache properties
            [__serializableKeysByClass setObject:keys forKey:className];
        }

        if([self notSerializableKeys]) {
            [keys minusSet:[self notSerializableKeys]];
        }
        return keys;
    }
}

- (NSSet *)notSerializableKeys {
    return nil;
}

+ (id)encode:(id)value {

    if(value == nil) {
        return [NSNull null];
    }

    if([value conformsToProtocol:@protocol(TMFSerializable)]) {
        return [((NSObject<TMFSerializable> *)value) serializedObject];
    }
    else if([value isKindOfClass:[NSDictionary class]]) {
        return [self traverseDictionary:value withSelector:_cmd];
    }
    else if([value isKindOfClass:[NSArray class]]) {
        return [self traverseArray:value withSelector:_cmd];
    }
    else if ([value isKindOfClass:[NSSet class]]) {
        return [self traverseArray:[[value allObjects] copy] withSelector:_cmd];
    }
    else if([value isKindOfClass:[NSDate class]]) {
        return @([((NSDate *)value) timeIntervalSince1970]);
    }
    else if([value isKindOfClass:[NSData class]]) {
        return [self encodeBinaryData:value];
    }
    else if([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        return value;
    }
    else {
        if(value != nil) {
            TMFLogInfo(@"Encoded NSNull for %@ (type: %@)", value, [NSString stringWithUTF8String:@encode(typeof(value))]);
        }
        return [NSNull null];
    }

    return value;
}

+ (id)decode:(id)value {
    if(NilIfNSNull(value) != nil) {
        if([value isKindOfClass:[NSDictionary class]]) {
            // lets see if we talk about a serializable object
            if([value objectForKey:TMFSerializableObjectClassKey]) {
                Class objectClass = NSClassFromString([value objectForKey:TMFSerializableObjectClassKey]);
                if(objectClass != Nil) {
                    return [[objectClass alloc] initWithSerializedObject:value];
                }
            }

            return [self traverseDictionary:value withSelector:_cmd];
        }
        else if([value isKindOfClass:[NSArray class]]) {
            return [self traverseArray:value withSelector:_cmd];
        }
        else if([value isKindOfClass:[NSString class]] && [value hasPrefix:kBinaryDataPrefix] && [value hasSuffix:kBinaryDataSuffix]) {
            return [self decodeBinaryData:value];
        }
        else if([__numberEncodings containsObject:[NSString stringWithUTF8String:@encode(typeof(value))]]) {
            return [[NSNumber alloc] initWithBytes:&value objCType:@encode(typeof(value))];
        }
        else if([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
            return value;
        }
        else {
            if(value != nil && ![[NSNull null] isEqual:value]) {
                TMFLogInfo(@"Decoded nil for %@ (type: %@)", value, [NSString stringWithUTF8String:@encode(typeof(value))]);
            }
        }
    }

    return nil;
}

+ (NSString *)encodeBinaryData:(NSData *)dataToEncode {
    NSString *enc = [self base64StringFromData:dataToEncode];
    return [NSString stringWithFormat:@"%@%@%@", kBinaryDataPrefix, enc, kBinaryDataSuffix];
}

+ (NSData *)decodeBinaryData:(NSString *)encodedData {  
    if([encodedData isKindOfClass:[NSString class]]) {
        NSMutableString *encData = [[NSMutableString alloc] initWithString:encodedData];
        [encData replaceOccurrencesOfString:kBinaryDataPrefix withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [encData length])];
        [encData replaceOccurrencesOfString:kBinaryDataSuffix withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [encData length])];
        return [self dataFromBase64String:encData];
    }
    else {
        TMFLogError(@"%@ can only decode binary data from %@.", NSStringFromClass([self class]), NSStringFromClass([NSString class]));
    }

    return nil;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (NSMutableDictionary *)serializedObject {    
    NSMutableDictionary *serializedObject = [[NSMutableDictionary alloc] initWithObjectsAndKeys:NSStringFromClass([self class]),TMFSerializableObjectClassKey, nil];
    for(NSString *key in [self serializableKeys]) {
        id value = [self valueForKey:key];
        [serializedObject setValue:[TMFSerializableObject encode:value] forKey:key];
    }
    
    return serializedObject;
}

- (void)updateFromSerializedObject:(NSDictionary *)serializedObject {
    if(serializedObject) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __propertyTypesByClass = [NSMutableDictionary new];
        });

        // cache types
        Class class = [self class];
        NSString *className = NSStringFromClass(class);
        NSMutableDictionary *propertyTypes = [__propertyTypesByClass objectForKey:className];
        if(!propertyTypes) {
            propertyTypes = [NSMutableDictionary new];
            for(NSString *key in [self serializableKeys]) {
                objc_property_t theProperty = class_getProperty(class, [key UTF8String]);
                const char * propertyAttrs = property_getAttributes(theProperty);
                NSString *propertyAttrsS = [NSString stringWithUTF8String:propertyAttrs];
                NSString *type = [[propertyAttrsS substringToIndex:[propertyAttrsS rangeOfString:@","].location] substringFromIndex:1];
                [propertyTypes setObject:type forKey:key];
            }

            [__propertyTypesByClass setObject:propertyTypes forKey:className];
        }

        // decode
        for(NSString *key in [self serializableKeys]) {
            NSString *type = [propertyTypes objectForKey:key];
            id value = NilIfNSNull([serializedObject objectForKey:key]);

            if(value != nil) {
                if([type hasPrefix:@"@"]) {
                    if([type length]>1) {
                        Class class = NSClassFromString([[type substringToIndex:[type length]-1] substringFromIndex:2]);

                        if([class isSubclassOfClass:[NSDictionary class]] || [class isSubclassOfClass:[NSArray class]]) {
                            value = [TMFSerializableObject decode:value];
                        }
                        else if([class isSubclassOfClass:[NSSet class]]) {
                            value = [TMFSerializableObject decode:value];
                            if(value !=  nil) {
                                value = [NSSet setWithArray:value];
                            }
                        }
                        else if([class isSubclassOfClass:[NSData class]]) {
                            value = NilIfNSNull([TMFSerializableObject decode:value]);
                        }
                        else if ([class isSubclassOfClass:[NSDate class]]) {
                            if(value != nil) {
                                value = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
                            }
                        }
                        else if ([class conformsToProtocol:@protocol(TMFSerializable)]) {
                            Class valueClass = NSClassFromString([value objectForKey:TMFSerializableObjectClassKey]);
                            if(valueClass) {
                                value = [[valueClass alloc] initWithSerializedObject:value];
                            }
                        }
                        else if([class isSubclassOfClass:[NSString class]] || [class isSubclassOfClass:[NSNumber class]]) {
                            value = NilIfNSNull(value);
                        }
                        else {
                            TMFLogError(@"Not supported type %@ property in %@.", NSStringFromClass(class), NSStringFromClass([self class]));
                        }
                    }
                }
                else if([__numberEncodings containsObject:[NSString stringWithUTF8String:@encode(typeof(value))]]) {
                    value = [[NSNumber alloc] initWithBytes:&value objCType:@encode(typeof(value))];
                }

                value = NilIfNSNull(value);
                if(value != nil) {
                    [self setValue:value forKey:key];
                }
            }
        }
    }
}

- (NSString *)description {
    NSDictionary *serialized = [self serializedObject];
    NSMutableString *str = [[NSMutableString alloc] init];
    [serialized enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop){
        [str appendFormat:@"<%@: %@> ", key, obj];
    }];
    
    return str;
}

//............................................................................
#pragma mark NSCoding
//............................................................................
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.serializedObject];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
+ (NSString *)base64StringFromData:(NSData *)data {
    size_t length = ybase64_encode(data.bytes, data.length, NULL, 0);
    void *d = malloc(length);
    ybase64_encode(data.bytes, data.length, d, length);
    NSString *s = [NSString stringWithUTF8String:d];
    free(d);
    return s;
}

+ (NSData *)dataFromBase64String:(NSString *)string {
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    size_t len = ybase64_decode([stringData bytes], [stringData length], NULL, 0);
    NSMutableData *data = [[NSMutableData alloc] initWithLength:len];
    ybase64_decode([stringData bytes], [stringData length], data.mutableBytes, data.length);
    return [data copy];
}

//............................................................................
#pragma mark collection traversing
//............................................................................
+ (NSDictionary *)traverseDictionary:(NSDictionary *)dict withSelector:(SEL)sel {
    id obj = nil;
    NSMutableDictionary *codedDictionary = [[NSMutableDictionary alloc] initWithCapacity:[dict count]];
    if([self respondsToSelector:sel]) {
        for(NSString *k in [dict allKeys]) {
            obj = [dict objectForKey:k];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            obj = [self performSelector:sel withObject:obj];
#pragma clang diagnostic pop
            [codedDictionary setObject:obj forKey:k];
        }
    }
    return codedDictionary;
}

+ (NSArray *)traverseArray:(NSArray *)array withSelector:(SEL)sel {
    NSMutableArray *codedArray = [[NSMutableArray alloc] initWithCapacity:[array count]];
    if([self respondsToSelector:sel]) {
        for (id o in array) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [codedArray addObject:[self performSelector:sel withObject:o]];
#pragma clang diagnostic pop
        }
    }
    return codedArray;
}

@end
