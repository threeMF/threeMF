//
//  TMFTcpChannelConnection.m
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

#import "TMFTcpChannelConnection.h"
#import "TMFLog.h"

@implementation TMFTcpChannelConnection
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)initWithSocket:(GCDAsyncSocket *)socket protocol:(TMFProtocol *)protocol delegate:(NSObject<TMFTcpChannelConnectionDelegate> *)delegate {
    NSParameterAssert(socket!=nil);
    NSParameterAssert([socket isConnected]);
    NSParameterAssert(delegate!=nil);

    self = [self init];
    if(self) {
        _delegate = delegate;
        _protocol = protocol;
        _socket = socket;
        [_socket setDelegate:self];
        [self readNextRequest];
    }
    return self;
}

- (void)dealloc {
    [_socket setDelegate:nil];
    [_socket disconnect];
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)sendResponseForRequest:(TMFRequest *)request result:(id)result error:(NSError *)error {
    TMFResponse *response = [TMFResponse responseWithidentifier:request.identifier result:result error:[error description]];
    NSData *data = [self.protocol responseDataForResponse:response];
    [self.socket writeData:data withTimeout:TIMEOUT tag:RESPONSE_SEND_TAG];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[self class]]) {
        return self.socket == ((TMFTcpChannelConnection *) object).socket;
    }

    return NO;
}

- (NSUInteger)hash {
    return self.socket.hash;
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

#pragma mark GCDAsyncSocketDelegate
/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if(tag == REQUEST_HEADER_TAG) {
        [self.protocol parseHeader:data completion:^(uint64_t length, NSError *error) {
            if(!error && length > 0) {
                [sock readDataToLength:length withTimeout:-1 tag:REQUEST_BODY_TAG];
            }
            else {
                [self readNextRequest];
            }
        }];
    }
    else if(tag == REQUEST_BODY_TAG) {
        TMFRequest *request = [self.protocol requestFromData:data];
        [self.delegate connection:self didReadRequest:request fromAddress:sock.connectedAddress];
        [self readNextRequest];
    }
    else {
        [self readNextRequest];
    }
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    if(error && error.code != GCDAsyncSocketClosedError) {
        TMFLogError(@"TCP Socket disconnected with Error: %@", error);
    }
    [self.delegate connection:self didDisconnect:sock withError:error];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)readNextRequest {
    [_socket readDataToLength:[self.protocol requestResponseHeaderLength] withTimeout:-1 tag:REQUEST_HEADER_TAG];
}

@end
