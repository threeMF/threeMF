//
//  TMFChannelDelegate.h
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

@class TMFCommand, TMFArguments, TMFPeer, TMFChannel;

/**
 Callback block for TMFRequestResponseCommand responses
 @param response response for the request, may be nil in the case of an error. The response must be a TMFSerializableObject compatible type @see TMFSerializabelObject
 @param error error object if anything went wrong, may be nil
 */
typedef void (^responseBlock_t)(id response, NSError *error);

/**
 Callback after channel startup completion.
 @param error error object if anything went wrong, may be nil
 */
typedef void (^startCompletionBlock_t)(NSError *error);

/**
 Callback after channel shutdown completion.
 */
typedef void (^stopCompletionBlock_t)();

/**
 An instance of TMFChannel uses methods in this protocol
 to notify the command dispatcher about incoming messages
 on the channel.
 */
@protocol TMFChannelDelegate <NSObject>
@required
/**
 This method is called whenever a command got sent to this peer.
 The response block should return an appropriate response to the sender
 or be executed with nil parameters if no response is needed.
 @param channel The channel that sends the message
 @param commandName The command name of the incoming message
 @param arguments The alphabetical ordered list of arguments for the command execution.
 @param address The senders address.
 @param responseBlock The response block to call after command execution.
 */
- (void)receiveOnChannel:(TMFChannel *)channel commandName:(NSString *)commandName arguments:(NSArray *)arguments address:(NSData *)address response:(responseBlock_t)responseBlock;

/**
 Defines the callback queue used for all delegate callbacks.
 Ignored if NULL.
 */
- (dispatch_queue_t)callbackQueue;

@end
