//
//  TMFStringBasedCoder.m
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

#import "TMFRpcCoder.h"
#import "TMFSerializableObject.h"

@implementation TMFRpcCoder
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (NSData *)encode:(NSDictionary *)dict {
    [super doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSDictionary *)decode:(NSData *)data {
    [super doesNotRecognizeSelector:_cmd];
    return nil;
}

//............................................................................
#pragma mark -
#pragma TMFProtocol
//............................................................................
- (NSString *)name {
    [super doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)version {
    [super doesNotRecognizeSelector:_cmd];
    return nil;
}

- (TMFRequest *)decodeRequest:(NSData *)data {
    NSDictionary *dict = [self decode:data];
    NSArray *arguments = [dict objectForKey:@"params"];

    TMFRequest *request = [TMFRequest new];
    request.commandName = NilIfNSNull([dict objectForKey:@"method"]);
    request.identifier = NilIfNSNull([dict objectForKey:@"id"]);
    request.arguments = arguments;

    return request;
}

- (TMFResponse *)decodeResponse:(NSData *)data {
    NSDictionary *dict = [self decode:data];
    TMFResponse *response = [TMFResponse new];
    response.identifier = NilIfNSNull([dict objectForKey:@"id"]);
    response.result = NilIfNSNull([TMFSerializableObject decode:[dict objectForKey:@"result"]]);
    response.error = NilIfNSNull([dict objectForKey:@"error"]);
    return response;
}

- (NSData *)encodeRequest:(TMFRequest *)request {
    NSAssert(request.commandName!=nil, @"Command name may not be nil!");
    NSArray *params = (request.arguments ? request.arguments : @[ ]);
    return [self encode:@{ @"method" : request.commandName, @"params" : params, @"id" : NSNullIfNil(request.identifier) }];
}

- (NSData *)encodeResponse:(TMFResponse *)response {
    return [self encode:@{ @"result" : NSNullIfNil([TMFSerializableObject encode:response.result]), @"error" : NSNullIfNil(response.error), @"id" : NSNullIfNil(response.identifier) }];
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
