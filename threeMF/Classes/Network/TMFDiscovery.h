//
//  TMFDiscovery.h
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
#import "TMFDiscoveryDelegate.h"
#import "TMFConfigurationDelegate.h"
#import "TMFHeartBeatCommand.h"

/**
 This class handles the creation of a peer's Bonjour services and the discovery of other peers on the network.
 */
@interface TMFDiscovery : NSObject

/**
 The object that acts as the delegate of the receiving discovery.
 The delegate must adopt the TMFDiscoveryDelegate protocol. The delegate is not retained.
 */
@property (nonatomic, weak) NSObject<TMFDiscoveryDelegate> *delegate;

/**
 The object that acts as configuration delegate to provide setup information like service type and domain.
 In most cases this delegate should be the threeMF facade instance.
 */
@property (nonatomic, weak) NSObject<TMFConfigurationDelegate> *configuration;

/**
 The heart beat command used to inform peers, that they are visible at the local peer.
 */
@property (nonatomic, readonly) TMFHeartBeatCommand *heartBeatCommand;

/**
 The local peer's TMFPeer instance
 */
@property (nonatomic, readonly) TMFPeer *localPeer;

/**
 All visible peers
 */
@property (nonatomic, readonly) NSArray *peers;

/**
 This property states if all discovery components are running.
 */
@property (nonatomic, readonly, getter = isRunning) BOOL running;

/**
 Starts local NSNetService and browsing.
 @param port The port to start the local service on.
 */
- (void)startOnPort:(NSUInteger)port;

/**
 Stops all bonjour components (NSNetService and browser)
 */
- (void)stop;

/**
 Publishes a new capability on the network.
 Adding new capabilities will update the local NSNetService's TXTRecordData
 @param commandName The unique [TMFCommand name] of the new capability.
 */
- (void)addCapability:(NSString *)commandName;

/**
 Unpublishes a new capability on the network.
 Removing capabilities will update the local NSNetService's TXTRecordData
 @param commandName The unique [TMFCommand name] of the capability to remove.
 */
- (void)removeCapability:(NSString *)commandName;

/**
 Finds a peer by its address.
 The port will be ignored.
 @param address The sockaddr_in or sockaddr_in6 of the peer to find.
 */
- (TMFPeer *)peerByAddress:(NSData *)address;

@end
