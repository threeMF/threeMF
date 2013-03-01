//
//  TMFCommandDispatcher.h
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
#import "TMFConfigurationDelegate.h"
#import "TMFPublishSubscribeCommand.h"
#import "TMFSubscription.h"

@class TMFCommandDispatcher, TMFDiscovery;
@protocol TMFCommandDelegate;

/**
 An instance of TMFCommandDispatcher uses methods in this protocol to inform the
 TMFConnector about channel state changes.
 */
@protocol TMFCommandDispatcherDelegate <NSObject>
/**
 @param address The peers address.
 @return The peer for the given address or nil if the peer is not visible / known.
 */
- (TMFPeer *)peerByAddress:(NSData *)address;

/**
 Gets called if a channel is started.
 @param dispatcher The dispatcher sending this message.
 @param channel The started channel.
 */
- (void)dispatcher:(TMFCommandDispatcher *)dispatcher startedChannel:(TMFChannel *)channel;

/**
 Gets called if a channel is stopped.
 @param dispatcher The dispatcher sending this message.
 @param channel The stopped channel.
 */
- (void)dispatcher:(TMFCommandDispatcher *)dispatcher stoppedChannel:(TMFChannel *)channel;

/**
 Gets called if a channel failed to start.
 @param dispatcher The dispatcher sending this message.
 @param channel The channel failed to start.
 @param error The error object describing the failure.
 */
- (void)dispatcher:(TMFCommandDispatcher *)dispatcher failedStartingChannel:(TMFChannel *)channel error:(NSError *)error;
@end

/**
 The dispatcher is responsible for bookkeeping commands, network channels, routing messages and executing callbacks.
 */
@interface TMFCommandDispatcher : NSObject <TMFCommandDelegate>

/**
 Framework configuration.
 By default this is the threeMF facade but due to extendability it can be any other class providing the protocol's implementation.
 */
@property (nonatomic, weak) NSObject<TMFConfigurationDelegate, TMFCommandDispatcherDelegate> *delegate;

/**
 Systems (TCP) channel used for reliable unicast communication.
 This channel's port is also published with the peers Bonjour's service and represents the first and primary entry point.
 */
@property (nonatomic, readonly) TMFChannel *systemChannel;

/**
 All published commands.
 */
@property (nonatomic, readonly) NSArray *publishedCommands;

/**
 All active subscriptions at other peers.
 */
@property (nonatomic, readonly) NSArray *subscriptions;

/**
 A list of commands published on this dispatcher.
 */
@property (nonatomic, readonly, copy) NSArray *publishedCommandNames;

/**
 Creates a new dispatcher instance.
 @param callBackQueue The dispatch queue used to execute all callbacks, receive blocks and callback blocks on. Default value is the main queue.
 @param configurationDelegate configuration delegate defining settings
 */
- (id)initWithCallBackQueue:(dispatch_queue_t)callBackQueue delegate:(NSObject<TMFConfigurationDelegate, TMFCommandDispatcherDelegate> *)configurationDelegate;

/** @name Channels */

/**
 Starts all instantiated communication channels.
 */
- (void)startChannels;

/**
 Stops all running communication channels.
 */
- (void)stopChannels;

/** @name Publish Subscribe */

/**
 Gets the command instance of a published command by it's unique name.
 @param command The name of the published command
 @return The published command corresponding to name. Nil if not found.
 */
- (TMFPublishSubscribeCommand *)publishedCommandForName:(NSString *)command;

/**
 Registers a command as published.
 @param command The command to publish.
 */
- (void)registerPublishCommand:(TMFCommand *)command;

/**
 Removes a command from the list of published commands.
 @param command The command to unpublish.
 */
- (void)removePublishedCommand:(TMFCommand *)command;

/**
 Subscribes to a command at a given remote peer.
 @param commandClass The class of the TMFPublishSubscribeCommand to subscribe to.
 @param peer The peer the command should get subscribed at.
 @param receive The receive block being executed with pushed arguments for the subscribed command.
 */
- (void)subscribe:(Class)commandClass peer:(TMFPeer *)peer receive:(pubSubArgumentsReceivedBlock_t)receive;

/**
 Unsubscribes from a command at the given remote peer.
 Nothing will happen if no corresponding subscription exists.
 @param commandName The name of the command to unsubscribe from.
 @param peer The peer the command should get unsubscribed at.
 */
- (void)unsubscribe:(NSString *)commandName peer:(TMFPeer *)peer;

/**
 Unsubscribes from all commands at the given remote peer.
 Nothing will happen if no corresponding subscription exists.
 @param peer The peer the command should get unsubscribed at.
 */
- (void)unsubscribeAtPeer:(TMFPeer *)peer;

/**
 Removes a peer by deleting all subscriptions and channel connections.
 @param peer The peer to remove.
 */
- (void)removePeer:(TMFPeer *)peer;

/**
 Checks if a peer still meets all requirements (capabilities) and updates subscriptions if necessary.
 @param peer The peer to update.
 */
- (void)checkSubscriptionsForPeer:(TMFPeer *)peer;

/**
 A list of all command names with active subscriptions at the given peer.
 @param peer The peer we are subscribed to.
 @return The unique [TMFCommand name] of commands the local peer is subscribed to at the given peer.
 */
- (NSArray *)subscribedCommandNamesAtPeer:(TMFPeer *)peer;

/**
 A list of all command objects where the given peer is a subscriber.
 @param peer The peer we are subscribed to.
 @return The list of command objects subscribed by the given peer.
 */
- (NSArray *)commandsSubscribedByPeer:(TMFPeer *)peer;

@end
