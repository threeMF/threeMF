//
//  TMFProtocol.m
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

#import "TMFProtocol.h"
#import "TMFCommand.h"
#import "TMFError.h"

#import "TMFRequest.h"
#import "TMFResponse.h"

#import "TMFJsonRpcCoder.h"

@interface TMFProtocol() {
    NSObject<TMFProtocolCoder> *_coder;
    NSString *_identifier;
}
@end

@implementation TMFProtocol
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    return [self initWithCoder:[TMFJsonRpcCoder new]];
}

- (id)initWithCoder:(NSObject<TMFProtocolCoder> *)coder {
    self = [super init];
    if (self) {
        _coder = coder;
        _identifier = [NSString stringWithFormat:@"%@,%@", self.name, self.version];
    }
    return self;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (NSString *)name {
    return [NSString stringWithFormat:@"%@RPC", [_coder name]];
}

- (NSString *)version {
    return @"1.0";
}

- (NSString *)identifier {
    return _identifier;
}

- (void)parseHeader:(NSData *)data completion:(headerParserCompletion_t)completion {
    NSParameterAssert(completion!=nil);
    if(data != nil && ([data length] == self.requestResponseHeaderLength || [data length] == self.publishSubscribeHeaderLength )) {
        uint64_t length = 0;
        [data getBytes:&length range:NSMakeRange(0, sizeof(uint64_t))];
        completion(length, (length == 0 ? [TMFError errorForCode:TMFMessageParsingErrorCode message:@"Could not parse message header."] : nil));
    }
    else {
        completion(0, [TMFError errorForCode:TMFMessageParsingErrorCode message:@"Could not parse message header."]);
    }
}

- (NSData *)requestDataForCommand:(TMFCommand *)command arguments:(TMFArguments *)arguments {
    NSParameterAssert(command != nil);
    return [self requestDataForRequest:[TMFRequest requestWithCommandName:command.name arguments:[arguments argumentList] identifier:@(arguments.identifier)]];
}

- (NSData *)requestDataForRequest:(TMFRequest *)request {
    NSParameterAssert(request != nil);
    NSData *requestData = [_coder encodeRequest:request];
    return [self dataPackageForResponseRequestData:requestData];
}

- (NSData *)responseDataForResponse:(TMFResponse *)response {
    NSParameterAssert(response != nil);
    NSData *responseData = [_coder encodeResponse:response];
    return [self dataPackageForResponseRequestData:responseData];
}

- (TMFRequest *)requestFromData:(NSData *)data {
    NSParameterAssert(data != nil);
    return [_coder decodeRequest:data];
}

- (TMFResponse *)responseFromData:(NSData *)data {
    NSParameterAssert(data != nil);
    return [_coder decodeResponse:data];
}

- (NSArray *)broadcastPackagesForRequest:(TMFRequest *)request maxSize:(NSUInteger)maxSize {
    NSParameterAssert(request != nil);
    NSParameterAssert(maxSize > 0);
    NSData *data = [_coder encodeRequest:request];

    NSUInteger read = 0, next = 0;
    NSUInteger maxBodySize = maxSize - [self publishSubscribeHeaderLength];
    NSMutableArray *result = [NSMutableArray new];

    NSUInteger packages = ceil([data length] / maxSize);
    NSUInteger identifier = ((rand() + 13) * 42) % UINT16_MAX;
    
    while(read < data.length) {
        NSRange range = NSMakeRange(read, maxBodySize);
        next += range.length;
        // overflow
        if(next >= data.length) {
            range = NSMakeRange(range.location, (data.length - read));
        }

        NSMutableData *datagram = [self headerForData:[data subdataWithRange:range]];
        [self appendBroadcastPackageHeader:datagram index:[result count] numberOfPackage:packages identifier:identifier];
        [datagram appendData:[data subdataWithRange:range]];
        [result addObject:datagram];

        read = read + range.length;
    }    

    return [NSArray arrayWithArray:result]; // immutable
}

- (NSUInteger)requestResponseHeaderLength {
    return sizeof(uint64_t);
}

- (NSUInteger)publishSubscribeHeaderLength {
    return self.requestResponseHeaderLength;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (NSObject<TMFProtocolCoder> *)coder {
    return _coder;
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (NSMutableData *)headerForData:(NSData *)request {
    uint64_t length = [request length];
    NSMutableData *data = [[NSMutableData alloc] initWithBytes:&length length:sizeof(uint64_t)];
    return data;
}

- (void)appendBroadcastPackageHeader:(NSMutableData *)data index:(NSUInteger)index numberOfPackage:(NSUInteger)numberOfPackages identifier:(NSUInteger)identifier {
    uint16_t identitiy = identifier;
    [data appendBytes:&identitiy length:sizeof(uint16_t)];

    uint16_t idx = index;
    [data appendBytes:&idx length:sizeof(uint16_t)];

    uint16_t packages = numberOfPackages;
    [data appendBytes:&packages length:sizeof(uint16_t)];
}

- (NSData *)dataPackageForResponseRequestData:(NSData *)data {
    NSMutableData *result = [self headerForData:data];
    [result appendData:data];
    return [NSData dataWithData:result]; // immutable
}

@end
