//
//  TMFArguments.m
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

#import "TMFArguments.h"
#import "TMFLog.h"

@implementation TMFArguments
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)initWithArgumentList:(NSArray *)list {
    self = [self init];
    if(self) {
        [self updateFromArgumentList:list];
    }
    return self;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (NSArray *)argumentList {
    NSDictionary *serialized = [self serializedObject];
    NSMutableArray *sortedKeys = [[self sortedKeysForDictionary:serialized] mutableCopy];
    [sortedKeys removeObjectAtIndex:0];
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[sortedKeys count]];
    for (NSString *key in sortedKeys) {
        [result addObject:[serialized objectForKey:key]];
    }
    return result;
}

- (BOOL)updateFromArgumentList:(NSArray *)list {

    BOOL result = NO;
    
    if(list) {
        NSMutableDictionary *serialized = [[self serializedObject] mutableCopy];
        NSMutableArray *sortedKeys = [[self sortedKeysForDictionary:serialized] mutableCopy];
        [sortedKeys removeObjectAtIndex:0];
        
        if([list count] == [sortedKeys count]) { // class key excluded
            NSUInteger i = 0;
            NSMutableDictionary *serializedObject = [[NSMutableDictionary alloc] initWithCapacity:[list count]];
            for(NSString *key in sortedKeys) {
                [serializedObject setObject:[list objectAtIndex:i] forKey:key];
                i++;
            }

            [serializedObject setObject:NSStringFromClass([self class]) forKey:TMFSerializableObjectClassKey];
            [self updateFromSerializedObject:serializedObject];
        }
        else {
            TMFLogError(@"ERROR: Arguments list contains wrong amount of arguments. Has %@ should be %@.", @([list count]), @([sortedKeys count]));
        }
    }
    else {
        TMFLogError(@"ERROR: Arguments list is nil.");
    }
    
    return result;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (NSArray *)sortedKeysForDictionary:(NSDictionary *)dic {
    NSMutableArray *keys = [[NSMutableArray alloc] initWithArray:[dic allKeys]];
    [keys removeObject:TMFSerializableObjectClassKey]; // remove _class key to ensure it is always at index 0
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]; // sort keys alphabetical
    
    [keys removeAllObjects];
    [keys insertObject:TMFSerializableObjectClassKey atIndex:0]; // ensure the _class key is at index 0
    [keys addObjectsFromArray:sortedKeys]; // add all other keys behind the _class
    return keys;
}

@end
