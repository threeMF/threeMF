//
//  TMFChannel.m
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

#import "TMFChannel.h"
#import "TMFCommand.h"
#import "TMFPeer.h"

@interface TMFChannel() {
    NSUInteger _port;
}
@end

@implementation TMFChannel

//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)initWithPort:(NSUInteger)port protocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate {
    self = [self init];
    if(self) {
        NSParameterAssert(protocol != nil);
        NSParameterAssert(delegate != nil);
        _port = (port > 65535) ? 0 : port;
        _protocol = protocol;
        _delegate = delegate;
    }
    return self;
}

- (id)initWithProtocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate {
    return [self initWithPort:0 protocol:protocol delegate:delegate];
}

- (void)dealloc {
    [self stop:nil];
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)start:(__unused startCompletionBlock_t)completionBlock {
    [super doesNotRecognizeSelector:_cmd];
}

- (void)stop:(__unused stopCompletionBlock_t)completionBlock {
    [super doesNotRecognizeSelector:_cmd];
}

- (void)send:(__unused TMFCommand *)command arguments:(__unused TMFArguments *)arguments destination:(__unused TMFPeer *)peer responseBlock:(__unused responseBlock_t)responseBlock {
    [super doesNotRecognizeSelector:_cmd];
}

- (void)removePeer:(__unused TMFPeer *)peer {
    // doing nothing per default
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
