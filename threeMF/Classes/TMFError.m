//
//  TMFError.m
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

#import "TMFError.h"
#import "TMFLog.h"

static NSDictionary *__errorMessages;

@implementation TMFError
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __errorMessages = @{
            @0 : @"Unknown Error",
        };
    });
}


//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
+ (NSError *)errorForCode:(NSUInteger)code {
    return [self errorForCode:code message:nil];
}

+ (NSError *)errorForCode:(NSUInteger)code message:(NSString *)message {
    return [self errorForCode:code message:message userInfo:@{}];
}

+ (NSError *)errorForCode:(NSUInteger)code message:(NSString *)message userInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *userInfoMutable = [(userInfo ? userInfo : @{}) mutableCopy];
    if(!message) {
        message = [__errorMessages objectForKey:@(code)];
        if(!message) {
            message = [__errorMessages objectForKey:@0];
            TMFLogError(@"Using error code (%@) without predefined message.", @(code));
        }
    }

    TMFLogError(@"Error %@: %@", @(code), message);
    if([userInfo count] > 0) {
        TMFLogError(@"%@", userInfo);
    }
    [userInfoMutable setObject:message forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"threeMF" code:code userInfo:userInfoMutable];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

@end
