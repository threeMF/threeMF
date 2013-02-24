//
//  TMFCommand.h
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
#import "TMFArguments.h"
#import "TMFChannelDelegate.h"

@class TMFCommand, TMFCommandDispatcher, TMFChannel;

/**
 An instance of TMFCommand uses methods in this protocol to get their callback
 queue and corresponding default communication channel.
 */
@protocol TMFCommandDelegate <NSObject>
@required
/**
 Dispatch queue on which all command callbacks should be executed
 all callbacks get executed synchronously.
 @param command command calling the delegate method
 */
- (dispatch_queue_t)callBackQueueForCommand:(TMFCommand *)command;

/**
 The channel fitting a commands type.
 @param commandClass The command calling the method
 */
- (TMFChannel *)channelForCommand:(Class)commandClass;
@end

/**
 Abstract command class representing a unique "service" provided by peers.

 The term command is borrowed from the command pattern (http://en.wikipedia.org/wiki/Command_pattern).
 At it's core 3MF is executing remote procedures following specific rules. Each remote procedure is
 represented by a command and can be called with it's corresponding TMFArguments object. This remote
 procedures differ in the direction of the information flow.
 Each command can currently follow one of two distribution patterns.

 - TMFPublishSubscribeCommand
 - TMFRequestResponseCommand
 */
@interface TMFCommand : NSObject

/**
 The object that acts as the delegate of the receiving command.
 The delegate must adopt the TMFCommandDelegate protocol. The delegate is not retained.
 
 @see TMFCommandDelegate
 */
@property (nonatomic, weak) NSObject<TMFCommandDelegate> *delegate;

/**
 Defines if a command is an operational command of 3MF like TMFSubscribeCommand.
 By default it is set to YES, override this property getter in order to change it in your
 specific command.

 @see TMFSubscribeCommand, TMFUnsubscribeCommand, TMFCapabilityCommand, TMFAnnounceCommand
 */
@property (nonatomic, readonly, getter = isSystemCommand) BOOL systemcommand;

/**
 The unique name of the command. By default the class name is used to identify each command.
 */
@property (nonatomic, strong, readonly) NSString *name;

/**
 Port of the commands channel.
 */
@property (nonatomic, readonly) NSUInteger port;

/** @name Configuration */

/**
 The unique name of the command.
 Define a unique name for your command. Use a prefix to avoid command collisions. System commands use the _ prefix
 The class name is used by default but this should be changed to a short string (transmission overhead).
 */
+ (NSString *)name;

/**
 The arguments class used for the command.
 Override this method in your custom command class if you want to use a custom command arguments class
 otherwise the following naming convention will be used: *CommandClassName*Arguments
 
 @see TMFArguments
 */
+ (Class)argumentsClass;

/**
 The channel class used for the command.
 The default channel is a reliable TCP channel.
 
 @see TMFChannel
 */
+ (Class)channelClass;

/** @name Execution */

/**
 Sends the given arguments object to the destination peer and triggers the command.
 @param arguments The Arguments used to send with the command.
 @param peer The destination peer.
 @param responseBlock The block executed on response.
 */
- (void)sendWithArguments:(TMFArguments *)arguments destination:(TMFPeer *)peer response:(responseBlock_t)responseBlock;

@end
