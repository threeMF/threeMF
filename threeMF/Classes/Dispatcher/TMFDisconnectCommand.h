//
//  TMFDisconnectCommand.h
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

#import "TMFRequestResponseCommand.h"

/**
 System command used to remove a peer from a remote commands subscriber list.
 This command is used by a command provider to signal subscribers, that they
 get removed from the subscribers list and should not expect getting data
 pushed anymore. Use this command to remove subscribers from commands.
 The corresponding arguments class is TMFDisconnectCommandArguments.

 - unique name: _disc
 - system command
 
 @warning This is a system command, you must not use this command directly. Use [TMFConnector disconnect:fromPeer:completion:] or [TMFConnector disconnect:completion:] instead
 */
@interface TMFDisconnectCommand : TMFRequestResponseCommand
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Arguments class for TMFDisconnectCommand used to unsubscribe from commands at threeMF peers.
 */
@interface TMFDisconnectCommandArguments : TMFArguments
/**
 The list of unique command names to disconnect
 @see [TMFCommand name]
 */
@property (nonatomic, strong) NSArray *commands;
@end