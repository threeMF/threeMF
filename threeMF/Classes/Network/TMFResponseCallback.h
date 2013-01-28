//
//  TMFResponseCallback.h
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
#import "GCDAsyncSocket.h"

/**
 Object storing responseBlock_t corresponding to a tuple of one TMFPeer and an identifier.
 Instances are used to identify and find responseBlock_t blocks.
 */
@interface TMFResponseCallback : NSObject
/**
 Response callback block for a request the request with the stored identifier
 */
@property (nonatomic, readonly) responseBlock_t responseBlock;

/**
 Peer the request was sent to.
 */
@property (nonatomic, readonly) TMFPeer *peer;

/**
 Socket the response belongs to
 */
@property (nonatomic, readonly) GCDAsyncSocket *socket;

/**
 Identifier of the request
 */
@property (nonatomic) NSUInteger identifier;

/**
 Createst a new instance
 @param identifier The identifier of the request.
 @param peer The request's destination peer.
 @param socket The request's source socket.
 @param block Response callback block for the request send with id identifier
 */
- (id)initWithIdentifier:(NSUInteger)identifier peer:(TMFPeer *)peer socket:(GCDAsyncSocket *)socket block:(responseBlock_t)block;

@end
