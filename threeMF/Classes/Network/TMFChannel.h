//
//  TMFChannel.h
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
#import "TMFChannelDelegate.h"
#import "TMFProtocol.h"

/**
 Abstract class representing a network channel.
 A concrete channel communicates using a specific network technology (TCP sockets, HTTP rest API, ...).
 Each peer has at least one channel but can have multiple for different types of commands.
 */
@interface TMFChannel : NSObject {
    @protected
    BOOL _running; /* internal state ivar representing running state */
}

/**
 The object that acts as the delegate of the receiving channel.
 The delegate must adopt the TMFChannelDelegate protocol. The delegate is not retained.
 */
@property (nonatomic, weak) NSObject<TMFChannelDelegate> *delegate;

/**
 Protocol for message en- and decoding.
 */
@property (nonatomic, strong) TMFProtocol *protocol;

/**
 The socket port this channel is running on.
 */
@property (nonatomic, readonly) NSUInteger port;

/**
 Running state of this channel.
 YES if the channel is started and running.
 NO if the channel did never start, stop or quit because of an error.
 */
@property (nonatomic, readonly, getter = isRunning) BOOL running;

/**
 Creates a new instance.
 @param protocol The protocol for en- and decoding network messages.
 @param delegate The delegate adopting the TMFChannelDelegate protocol.
 @return a new instance
 */
- (id)initWithProtocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate;

/**
 Creates a new instance.
 @param port The port the channel should be forced to start on
 @param protocol The protocol for en- and decoding network messages.
 @param delegate The delegate adopting the TMFChannelDelegate protocol.
 @return a new instance
 */
- (id)initWithPort:(NSUInteger)port protocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate;

/**
 Starts the channel
 @param completionBlock callback block getting called after startup is done
 */
- (void)start:(startCompletionBlock_t)completionBlock;

/**
 Stops the channel
 @param completionBlock callback block getting called after startup is done
 */
- (void)stop:(stopCompletionBlock_t)completionBlock;

/**
 Sends a command with arguments via the channel.
 @param command command to send
 @param arguments arguments to send
 @param peer destination peer
 @param responseBlock response callback block to call for responses. This parameter gets ignored for TMFPublishSubscribeCommand
 */
- (void)send:(TMFCommand *)command arguments:(TMFArguments *)arguments destination:(TMFPeer *)peer responseBlock:(responseBlock_t)responseBlock;

/**
 Removes all connections and sockets for a given peer.
 @param peer Peer which should get removed.
 */
- (void)removePeer:(TMFPeer *)peer;
@end