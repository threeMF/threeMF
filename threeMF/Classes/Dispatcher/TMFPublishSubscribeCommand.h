//
//  TMFPublishSubscribeCommand.h
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

#import "TMFCommand.h"
#import "TMFConfiguration.h"

/**
 Block for receiving arguments from a subscription
 @param arguments arguments send from publisher
 */
typedef void (^pubSubArgumentsReceivedBlock_t)(id arguments, TMFPeer *peer);

/**
 This abstract class describes a command following the publish subscribe pattern.

**Publish Subscribe** (P+S) commands get triggered by the **publisher** whenever a defined event occurs. Other peers can **subscribe** to P+S commands and get a command specific payload **push**ed. An example would be a mobile phone with motion sensors providing a command sending real time accelerometer data. This information could e.g. be used to control a mouse pointer on a desktop computer.
 
 ## Usage
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
     }];

 ### Push (Peer A)
     TMFKeyValueCommandArguments *kvArguments = [TMFKeyValueCommandArguments new];
     kvArguments.key = @"msg";
     kvArguments.value = @"Hello World!";
     [self.kvCmd sendWithArguments:kvArguments];
 
 ## Custom Publish Subscribe Command
 Publish subscribe commands can be **internally** or **externally** triggered. Internally triggered commands (e.g. TMFMotionCommand, TMFLocationCommand) are aware when and how to send arguments. A service is setup internally which sends payload to all subscribers on a use case dependent event (e.g. accelerometer data is available). The command just needs to be published, start and stop get called with the first and last subscriber - everything is handled by 3MF.
 Externally triggered commands (e.g. TMFImageCommand, TMFKeyValueCommand) get executed by the application using 3MF, the command is not aware of the trigger. TMFArguments need to be created and send at the application level.

 1. Subclass
    - Override [TMFCommand name] with a short unique string identifier NSStringFromClass() is default.
    - Override [TMFPublishSubscribeCommand isReliable] and return YES to use TCP instead of UDP
    - Override [TMFPublishSubscribeCommand isRealTime] and return YES to disable Nagle's algorithm for TCP
    - Override [TMFPublishSubscribeCommand isMulticast] and return YES if you want to use UDP multicast instead of UDP unicast.
    - Override [TMFPublishSubscribeCommand defaultConfiguration] if you want a default configuration.
 2. Command startup / shutdown
    - Override [TMFPublishSubscribeCommand start:] to setup the service (if needed, can also be triggered from "outside")
    - Override [TMFPublishSubscribeCommand stop:] to stop the service (if needed, can also be triggered from "outside")
 3. Create a TMFArguments subclass
    - Provide all payload parameters as strong read write properties (they get serialized automatically)
 4 Create a TMFConfiguration subclass (if needed)
    - Provide all configuration parameters as strong read write properties (they get serialized automatically)
 5. Publish the command

 @warning This class is abstract, don't use it directly. Create a a subclass to implement your own custom command.
 */
@interface TMFPublishSubscribeCommand : TMFCommand

/**
 Indicates if the command's service is running
 */
@property (nonatomic, getter = isRunning) BOOL running;

/**
 Configuration the command is running with.
 At the moment there can be only one configuration of all subscribers.
 */
@property (nonatomic, strong) TMFConfiguration *configuration;

/**
 Defines if a command should restart after configurations got updated
 default value is NO, override this method in your command class if you want to change it.
 */
@property (nonatomic, readonly, getter = shouldRestartOnConfigurationUpdate) BOOL restartOnConfigurationUpdate;

/**
 The list of all active subscribers receiving this command.
 */
@property (nonatomic, readonly, copy) NSArray *subscribers;

/**
 Defines if a command is using UDP multi-cast for data transmission.
 Default value is NO.
 Override this method in your command class if you want to change it.
 */
+ (BOOL)isMulticast;

/**
 Defines if a command has to be acknowledged by the receiver in order to be successful.
 The default value is NO, override this method in your command class if you want to change it.
 Commands configured as reliable will get delivered on a TCP channel, otherwise via UDP (by default).
 This behavior can be changed by providing a custom channel in the command's subclass.
 */
+ (BOOL)isReliable;

/**
 Defines if the command's arguments are used in an real time context (like sending gyroscope data or mouse positions)
 default value is NO, override this method in your command class if you want to change it.
 Setting this value to YES or NO in combination with unreliable commands will have no effect.
 Setting this value to YES for reliable commands will set the TCP_NODELAY flag for TCP sockets and
 disable Nagle's algorithm http://www.unixguide.net/network/socketfaq/2.16.shtml
 @bug This method can be removed, if the TCP channel decides on applying TCP_NDELAY based on a command's arguments size.
 */
+ (BOOL)isRealTime;

/**
 The standard configuration for the command which will be used if no configuration is transmitted on subscription.
 The default value is nil.
 */
+ (TMFConfiguration *)defaultConfiguration;

/**
 Broadcasts the given arguments to all listening peers
 @param arguments The arguments for the command execution
 */
- (void)sendWithArguments:(TMFArguments *)arguments;

/**
 Adds a subscriber, each subscriber will get data on send
 @param peer Thee peer to add to this commands subscribers list.
 */
- (void)addSubscriber:(TMFPeer *)peer;

/**
 Removes a subscriber, each subscriber will get data on send
 @param peer The peer to remove from this commands subscribers list.
 */
- (void)removeSubscriber:(TMFPeer *)peer;

/**
 Starts the command's service / worker.
 The default implementation is just calling the completion block.
 You need to override this method if your command runs internally triggered.
 @param completionBlock callback block which gets called after startup
 */
- (void)start:(startCompletionBlock_t)completionBlock;

/**
 Stops the command's service / worker and notifies all subscribers
 The default implementation is just calling the completion block.
 You need to override this method if your command runs internally triggered.
 @param completionBlock callback block which gets called after startup
 */
- (void)stop:(stopCompletionBlock_t)completionBlock;

@end
