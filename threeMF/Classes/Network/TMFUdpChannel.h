//
//  TMFUdpChannel.h
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
#import "TMFChannel.h"

/**
 TMFChannel implementation communicating via UDP sockets.
 This channel can also be used for UDP multi-casting.
 
 It uses the great [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket) library. 
 */
@interface TMFUdpChannel : TMFChannel

/**
 Multi-cast group used for this channel, may be nil if the channel should not be part of the multi-cast group
 */
@property (nonatomic, copy) NSString * multiCastGroup;

/**
 Creates a new instance
 @param port port the channel should be bound to
 @param protocol protocol for en- decoding
 @param delegate delegate for callbacks
 @param multicastGroup multi-cast n group the peer should join
 @return a new instance
 */
- (id)initWithPort:(NSUInteger)port protocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate multicastGroup:(NSString *)multicastGroup;

/**
 Creates a new instance
 @param protocol protocol for en- decoding
 @param delegate delegate for callbacks
 @param multicastGroup multi-cast n group the peer should join
 @return a new instance
 */
- (id)initWithProtocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate multicastGroup:(NSString *)multicastGroup;

@end
