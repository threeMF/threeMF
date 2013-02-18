//
//  CADAnnounceCommandArguments.m
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

#import "CADAnnounceCommandArguments.h"
#import "CADAnnounceCommand.h"

#define kKeyColor @"color"

@implementation CADAnnounceCommandArguments

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
- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    CADAnnounceCommandArguments *obj = (CADAnnounceCommandArguments *)object;
    if(![self.name isEqualToString:obj.name]) {
        return NO;
    }
    
    if(![self.color isEqual:obj.color]) {
        return NO;
    }
    
    return YES;
}

- (NSSet *)notSerializableKeys {
    return [NSSet setWithArray:@[ @"color" ]]; // color gets serialized manually
}

//............................................................................
#pragma mark TMFSerializable
//............................................................................
- (NSMutableDictionary *)serializedObject {    
    NSMutableDictionary *serializedObject = [super serializedObject];
    
    CGFloat red, green, blue, alpha;
    [self.color getRed:&red green:&green blue:&blue alpha:&alpha];
    [serializedObject setObject:[NSString stringWithFormat:@"%f;%f;%f;%f", red, green, blue, alpha] forKey:kKeyColor];  
    return serializedObject;
}

- (void)updateFromSerializedObject:(NSDictionary *)serializedObject {
    [super updateFromSerializedObject:serializedObject];
    if(serializedObject) {
        
        if([serializedObject objectForKey:kKeyColor]) {
            NSString *colorComponents = [serializedObject objectForKey:kKeyColor];
            __block CGFloat red, green, blue, alpha;            
            [[colorComponents componentsSeparatedByString:@";"] enumerateObjectsUsingBlock:^(NSString *comp, NSUInteger idx, __unused BOOL *stop){
                switch (idx) {
                    case 0:
                        red = [comp floatValue];
                        break;
                    case 1:
                        green = [comp floatValue];
                        break;
                    case 2:
                        blue = [comp floatValue];
                        break;
                    case 3:
                        alpha = [comp floatValue];
                        break;                                                                        
                    default:
                        break;
                }
            }];
            
#if TARGET_OS_IPHONE
            self.color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
#elif TARGET_OS_MAC
            self.color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
#endif            
        }
    }
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

@end
