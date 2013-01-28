//
//  TMFConnector.h
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
#import "TMFPeer.h"
#import "TMFPublishSubscribeCommand.h"
#import "TMFRequestResponseCommand.h"

#import "TMFConfigurationDelegate.h"
#import "TMFDiscoveryDelegate.h"
#import "TMFConnectorDelegate.h"

typedef void (^tmfCompletionBlock_t)(NSError *error);

/**
 This is the central facade class for 3MF. An instance is required to enable
 discovery and command management.

 ## 3MF System Service
 TMFDiscovery gets started with the TMFConnector instance and stopped with it's deallocation. If the application turns into the background on iOS all discovery components get stopped and started on resume again. Because we can not decide if the app will ever become active again, this also implies, that all subscriptions get removed locally and on remote peers. All peer applications get informed about this change (clean up and prepare to reconnect!).
 ## Publish Subscribe
**Publish Subscribe** (P+S) commands on the other hand get triggered by the **publisher** whenever a defined event occurs. Other peers can **subscribe** to P+S commands and get a command specific payload **push**ed. An example would be a mobile phone with motion sensors providing a command sending real time accelerometer data. This information could e.g. be used to control a mouse pointer on a desktop computer.

 ### Setup (Peer A + Peer B)
    self.tmf = [TMFConnector new];

 ### Publishing (Peer A)
    self.kvCmd = [TMFKeyValueCommand new]; // P+S command
    [self.tmf publishCommand:self.kvCmd];

 ### Discovery (Peer B)
    [self.tmf startDiscoveryWithCapabilities:@[ [TMFKeyValueCommand name] ] delegate:self];

 ### Subscription (Peer B)
    [self.tmf subscribe:[TMFKeyValueCommand name] peer:peer receive:^(TMFKeyValueCommandArguments *arguments){
        // do awesome things
        NSLog(@"%@: %@", arguments.key, arguments.value);
    }
    completion:^(NSError *error){
        if(error) { // handle error
            NSLog(@"%@", error);
        }
    }];

 ### Push (Peer A)
    TMFKeyValueCommandArguments *kvArguments = [TMFKeyValueCommandArguments new];
    kvArguments.key = @"msg";
    kvArguments.value = @"Hello World!";
    [self.kvCmd sendWithArguments:kvArguments];

 ## Request Response
**Response Request** (R+R) commands are common remote procedures delivering a **response** for a list of defined parameters on **request**. An example would be a computer asking a mobile phone for its current GPS location.

 ### Setup (Peer A + Peer B)
    self.tmf = [TMFConnector new];

 ### Publishing (Peer A)
    self.announceCmd = [[CADAnnounceCommand alloc] initWithRequestReceivedBlock:^(CADAnnounceCommandArguments *arguments, TMFPeer *peer, responseBlock_t responseBlock){
        // do awesome things
        return result;
    }];

    [self.tmf publishCommand:self.announceCmd];

 ### Requesting (Peer B)
    CADAnnounceCommandArguments *args = [CADAnnounceCommandArguments new];
    args.name = @"Zaphod";

    [self.tmf sendCommand:[CADAnnounceCommand class] arguments:args destination:peer response:^(id response, NSError *error) {
        // do something with your response
    }];

 @sa TMFConnectorDelegate
 */
@interface TMFConnector : NSObject <TMFConfigurationDelegate>

/**
 A list containing the names of all published services the current instance supports.
 If no commands are published the resulting collection will be empty.
 */
@property (nonatomic, readonly, copy) NSArray *publishedCommandNames;

/**
 A peer instance representing the local peer on it's system channel.
 */
@property (nonatomic, readonly) TMFPeer *localPeer;

/**
 List of all currently visible peers the serviceType service with any capabilities.
 */
@property (nonatomic, readonly) NSArray *peers;

/**
 Delegate for connector state changes.
 */
@property (nonatomic, weak) NSObject<TMFConnectorDelegate> *delegate;

/**
 Creates a new instance of threeMF
 @param callBackQueue is the dispatch queue used to make any callbacks going out of the framework.
        If no queue is give the main queue will be the default value
 @return a new instance of threeMF
 */
- (id)initWithCallBackQueue:(dispatch_queue_t)callBackQueue;

/** @name Discovery */

/**
 Publishes a command for public access on it's corresponding channel.
 The command will get registered with the internal dispatcher and all delegates and references
 will be set up for publishing. In addition the txtRectord of each
 published NSNetService will get updated in order to notify other peers about the state change.
 @param command The command which should get published for the current peer.
 */
- (void)publishCommand:(TMFCommand *)command;

/**
 Publishes a set of commands for public access on it's corresponding channel.
 These commands will get registered with the internal dispatcher and all delegates and references
 will be set up for publishing. In addition the txtRectord of each
 published NSNetService will get updated in order to notify other peers about the state change.
 @param commands A list of commands which should get published for the current peer.
 */
- (void)publishCommands:(NSArray *)commands;

/**
 Removes a command from public access on it's corresponding channel.
 The command will get removed from the internal dispatcher. In addition the txtRectord of each
 published NSNetService will get updated in order to notify other peers about the state change.
 @param command the command which should get removed.
 */
- (void)unpublishCommand:(TMFCommand *)command;

/**
 Starts discovery of peers capable of a given set of commands for the given delegate. Delegates will get retained.
 @param listOfCommands a list of command names representing the minimal set of services each discovered peers must support.
 @param delegate the delegate being notified on discovery state changes like new domains or peers.
 */
- (void)startDiscoveryWithCapabilities:(NSArray *)listOfCommands delegate:(NSObject<TMFConnectorDelegate> *)delegate;

/**
 Stops the discovery of peers capable of the given set of commands for the given delegate.
 @param listOfCommands a list of command names representing the minimal set of services each discovered peers must support.
 @param delegate the delegate being notified on discovery state changes like new domains or peers.
 */
- (void)stopDiscoveryWithCapabilities:(NSArray *)listOfCommands delegate:(NSObject<TMFConnectorDelegate> *)delegate;

/** @name Publish Subscribe */

/**
 Subscribes to a publish subscribe command at a given remote peer and sets up receiving data.
 @param commandClass The TMFPublishSubscribeCommand class to subscribe.
 @param peer the remote peer providing the command
 @param receive a receive block which gets trigged whenever the specific peer is publishing data for the subscribed service
 @param completion a completion block which gets triggered after the subscription has been confirmed or failed
 */
- (void)subscribe:(Class)commandClass peer:(TMFPeer *)peer receive:(pubSubArgumentsReceivedBlock_t)receive completion:(tmfCompletionBlock_t)completion;

/**
 Subscribes to a publish subscribe command at a given remote peer and sets up receiving data.
 @param commandClass The TMFPublishSubscribeCommand class to subscribe.
 @param configuration a configuration instance containing setup parameters for the remote command
 @param peer the remote peer providing the command
 @param receive a receive block which gets trigged whenever the specific peer is publishing data for the subscribed service
 @param completion a completion block which gets triggered after the subscription has been confirmed or failed
 */
- (void)subscribe:(Class)commandClass configuration:(TMFConfiguration *)configuration peer:(TMFPeer *)peer receive:(pubSubArgumentsReceivedBlock_t)receive completion:(tmfCompletionBlock_t)completion;

/**
 Unsubscribes from a publish subscribe command at a given peer.
 Subscribers call this message if they are not interested int a specific command anymore.
 @param commandClass The TMFPublishSubscribeCommand to unsubscribe from.
 @param peer the remote peer providing the command
 @param completion a completion block which gets triggered after the subscription has been confirmed or failed.
 */
- (void)unsubscribe:(Class)commandClass fromPeer:(TMFPeer *)peer completion:(tmfCompletionBlock_t)completion;

/**
 Unsubscribes from all publish subscribe commands at a given peer.
 Subscribers call this message if they are not interested in any commands from a peer anymore.
 @param peer The remote peer to unsubscribe from.
 @param completion a completion block which gets triggered after the subscription has been confirmed or failed.
 */
- (void)unsubscribeFromPeer:(TMFPeer *)peer completion:(tmfCompletionBlock_t)completion;

/**
 Disconnects a connected peer from a given command.
 Command provider call this message to remove a subscriber from a specific command.
 @param commandClass The TMFPublishSubscribeCommand to disconnect from.
 @param peer The remote peer to disconnect from the given command.
 @param completion A completion block which gets triggered after the disconnect has been confirmed or failed.
 */
- (void)disconnect:(Class)commandClass fromPeer:(TMFPeer *)peer completion:(tmfCompletionBlock_t)completion;

/**
 Disconnects a connected peer from all commands
 Command provider call this message to remove a subscriber from all commands.
 @param peer The remote peer to disconnect from.
 @param completion a completion block which gets triggered after the subscription has been confirmed or failed.
 */
- (void)disconnect:(TMFPeer *)peer completion:(tmfCompletionBlock_t)completion;

/** @name Request Response */

/**
 Sends a set of command arguments for a given request response command, the response block gets executed when the result
 got received or an error occurred.
 @param commandClass TMFPublishSubscribeCommand to send.
 @param arguments The corresponding arguments to send.
 @param peer The destination peer.
 @param response a response which gets triggered after a response is received.
 */
- (void)sendCommand:(Class)commandClass arguments:(TMFArguments *)arguments destination:(TMFPeer *)peer response:(responseBlock_t)response;

@end
