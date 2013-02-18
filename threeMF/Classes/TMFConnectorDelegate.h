//
//  TMFConnectorDelegate.h
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

typedef enum {
    TMFPeerChangeFound,
    TMFPeerChangeRemove,
    TMFPeerChangeUpdate
} TMFPeerChangeType;

@class TMFConnector;

/**
 An instance of TMFConnector uses methods in this protocol to inform the controller
 about discovery, subscription state changes and errors.
 */
@protocol TMFConnectorDelegate <NSObject>

@optional

/** @name Discovery */

/**
 Gets called if a peer is found, changed or removed after starting discovery with specific capability requirements.
 @param connector The TMFConnector instance calling the method
 @param peer The changed TMFPeer
 @param changeType The type of change. Valid values are TMFPeerChangeFound, TMFPeerChangeRemove and TMFPeerChangeUpdate.
 */
- (void)connector:(TMFConnector *)connector didChangeDiscoveringPeer:(TMFPeer *)peer forChangeType:(TMFPeerChangeType)changeType;

/**
 Gets called if any peer is found, changed or removed.
 All peers with the same bonjour service name are reported with this method, no matter what capabilities they have.
 @param connector The TMFConnector instance calling the method
 @param peer The changed TMFPeer
 @param changeType The type of change. Valid values are TMFPeerChangeFound, TMFPeerChangeRemove and TMFPeerChangeUpdate.
 */
- (void)connector:(TMFConnector *)connector didChangePeer:(TMFPeer *)peer forChangeType:(TMFPeerChangeType)changeType;



/** @name Subscriber */

/**
 Gets called if a peer subscribed to a published command
 @param connector The TMFConnector instance calling the method
 @param peer The added subscriber
 @param command The command a subscriber has been added to
 */
- (void)connector:(TMFConnector *)connector didAddSubscriber:(TMFPeer *)peer toCommand:(TMFPublishSubscribeCommand *)command;

/**
 Gets called if a peer got ubsusbcribed from a published command
 @param connector The TMFConnector instance calling the method
 @param peer The removed subscriber
 @param command The command a subscriber has been removed from
 */
- (void)connector:(TMFConnector *)connector didRemoveSubscriber:(TMFPeer *)peer fromCommand:(TMFPublishSubscribeCommand *)command;



/** @name Subscriptions */

/**
 Gets called if a subscription is added
 @param connector The TMFConnector instance calling the method
 @param peer The provider where the subscription has been added to
 @param commandClass The command's class which has been subscribed to
 */
- (void)connector:(TMFConnector *)connector didAddSubscription:(TMFPeer *)peer forCommand:(Class)commandClass;

/**
 Gets called if a subscription is removed
 @param connector The TMFConnector instance calling the method
 @param peer The provider where the subscription has been removed from
 @param commandClass The command's class which has been unsubsribed from
 */
- (void)connector:(TMFConnector *)connector didRemoveSubscription:(TMFPeer *)peer forCommand:(Class)commandClass;



/** @name Error Handling */

/**
 Informs about errors.
 @see TMFError for error codes
 @param connector The TMFConnector instance calling the method
 @param error The error
 */
- (void)connector:(TMFConnector *)connector didFailWithError:(NSError *)error;

@end
