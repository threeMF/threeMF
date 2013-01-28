//
//  TMFHeartBeatCommand.h
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
 3MF subscription depends on peers seeing each other via bonjour
 to work properly. The heart beat is send to each discovered peer
 in order to tell the peer about it's visibility at the sender.
 A peer is not reported as discovered until it sends a heart beat.
 The corresponding arguments class is TMFHeartBeatCommandArguments.

 - unique name: _hb
 - system command
 
 @warning This is a system command, you must not use this command.
 */
@interface TMFHeartBeatCommand : TMFRequestResponseCommand
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Arguments class for TMFHeartBeatCommand used to tell peers that we found them.
 */
@interface TMFHeartBeatCommandArguments : TMFArguments
/**
 Identifier of the peer sending the heart beat.
 */
@property(nonatomic, strong) NSString *UUID;
@end