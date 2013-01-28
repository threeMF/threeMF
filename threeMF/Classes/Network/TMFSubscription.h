//
//  TMFSubscription.h
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
#import "TMFPublishSubscribeCommand.h"

/**
 This class is used to represent a active subscription identified by a tuple of TMFPublishSubscribeCommand and TMFPeer.
 Each instance also includes a copy of the corresponding pubSubArgumentsReceivedBlock_t tied to the subscription.
 */
@interface TMFSubscription : NSObject

/**
 The peer this subscription is created for.
 */
@property (nonatomic, strong) TMFPeer *peer;

/**
 The name of the TMFPublishSubscribeCommand this subscription corresponds to.
 */
@property (nonatomic) Class commandClass;

/**
 The pubSubArgumentsReceivedBlock_t callback block tied to the subscription. This block gets called every time TMFArguments for TMFPublishSubscribeCommand get delivered from the subscribed TMFPeer.
 */
@property (nonatomic, readonly) pubSubArgumentsReceivedBlock_t receiveBlock;

/**
 Creates a new instance.
 @param peer The TMFPeer the subscription is made at.
 @param commandClass The TMFPublishSubscribeCommand class of the subscription.
 @param receive the callback block to trigger every time TMFArguments for a subscription get delivered
 @return a new TMFSubscription instance
 */
- (id)initWithPeer:(TMFPeer *)peer command:(Class)commandClass receive:(pubSubArgumentsReceivedBlock_t)receive;

@end
