//
//  TMFTcpChannelConnection.h
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
#import "GCDAsyncSocket.h"
#import "TMFRequest.h"
#import "TMFPeer.h"
#import "TMFProtocol.h"
#import "TMFChannelDelegate.h"
#import "TMFChannel.h"

#define REQUEST_HEADER_TAG  100 /* GCDAsyncSocket tag for reading request headers */
#define REQUEST_BODY_TAG    101 /* GCDAsyncSocket tag for reading request bodies */
#define RESPONSE_HEADER_TAG 200 /* GCDAsyncSocket tag for reading response headers */
#define RESPONSE_BODY_TAG   201 /* GCDAsyncSocket tag for reading response bodies */
#define RESPONSE_SEND_TAG   202 /* GCDAsyncSocket tag for sending response data */

#define TIMEOUT             60.0 /* default time out for GCDAsyncSocket operations */

@class TMFTcpChannelConnection;

/**
 An instance of TMFChannelConnection uses methods in this protocol
 to communicate it's underlying sockets events.
 */
@protocol TMFTcpChannelConnectionDelegate <NSObject>
@required
/**
 This callback gets triggered when a connection finished reading a request.
 @param connection The connection sending the message.
 @param request The read request object.
 @param address The senders address.
 */
- (void)connection:(TMFTcpChannelConnection *)connection didReadRequest:(TMFRequest *)request fromAddress:(NSData *)address;

/**
 This callback gets called after the socket of a connection gets disconnected.
 @param connection The connection sending the message.
 @param socket The disconnected socket object.
 @param error The error message containing the reason for the disconnection. The reason could also be an expected close of the socket.
 */
- (void)connection:(TMFTcpChannelConnection *)connection didDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error;
@end


/**
 The class is used to handle a GCDasyncSocket connected.
 It represents a TCP connection from any TMFPeer in the 3MF peer 2 peer network. It is used to read TCP requests and sending responses.
 */
@interface TMFTcpChannelConnection : NSObject <GCDAsyncSocketDelegate>

/**
 The corresponding TCP socket for this connection
 */
@property (nonatomic, readonly) GCDAsyncSocket *socket;

/**
 The protocol used for decoding incoming TMFRequests and outgoing TMFResponses
 */
@property (nonatomic, strong) TMFProtocol *protocol;

/**
 The object that acts as delegate of the receiving channel.
 */
@property (nonatomic, weak) NSObject<TMFTcpChannelConnectionDelegate> *delegate;


/**
 Initializes a new instance.
 @param socket  The corresponding TCP socket for this connection. The **delegate** of this socket **gets changed** to the current class.
 @param protocol The protocol used for decoding incoming TMFRequests and outgoing TMFResponses
 @param delegate The corresponding delegate getting notified about new incoming TMFRequests
 */
- (id)initWithSocket:(GCDAsyncSocket *)socket protocol:(TMFProtocol *)protocol delegate:(NSObject<TMFTcpChannelConnectionDelegate> *)delegate;

/**
 Send a response to the connected peer's socket.
 @param request The corresponding request the result is meant for. Must not be nil.
 @param result The result for the request. May be nil
 @param error The error if anything went wrong with the request. May be nil
 */
- (void)sendResponseForRequest:(TMFRequest *)request result:(id)result error:(NSError *)error;
@end
