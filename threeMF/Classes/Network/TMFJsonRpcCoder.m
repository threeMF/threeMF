//
//  TMFJsonRpcProtocol.m
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

#import "TMFJsonRpcCoder.h"
#import "TMFLog.h"

@implementation TMFJsonRpcCoder
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
#pragma TMFProtocol
//............................................................................
- (NSString *)name {
    return @"Json";
}

- (NSString *)version {
    return @"1.0";
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (NSData *)encode:(NSDictionary *)dict {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&error];
    if(error) {
        TMFLogError(@"JSON parser error. %@ for %@", error, dict);
        return nil;
    }
    return data;
}

- (NSDictionary *)decode:(NSData *)data {
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if(error) {
        TMFLogError(@"JSON parser error. %@ for %@", error, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        return nil;
    }
    return dict;
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

@end
