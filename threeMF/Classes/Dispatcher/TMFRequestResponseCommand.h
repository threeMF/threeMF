//
//  TMFRequestResponseCommand.h
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

/**
 Block for receiving arguments from a requester
 @param arguments arguments send from publisher
 @param responseBlock response block which should be used to send the response after processing all received arguments
 */
typedef void (^reqResArgumentsReceivedBlock_t)(id arguments, TMFPeer *peer, responseBlock_t responseBlock);

/**
 This class describes a command following the request response pattern.
 
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
 
 ## Custom Request Response Command
 Request Response commands are always send via a reliable channel (TCP).

 1. Subclass
 - Override [TMFCommand name] with a short unique string identifier (NSStringFromClass() is default).
 2. Create a TMFArguments subclass
 - Provide all payload parameters as strong read write properties (they get serialized automatically).
 3. Publish the command

 @warning This class is abstract, don't use it directly. Create a a subclass to implement your own custom command.
 */
@interface TMFRequestResponseCommand : TMFCommand

/**
 Creates a new instance
 @param requestReceivedBlock block which gets executed when the request gets triggered
 @return a new instance
 */
- (id)initWithRequestReceivedBlock:(reqResArgumentsReceivedBlock_t)requestReceivedBlock;

/**
 @param arguments The list of arguments sent by the requester.
 @param source The peer sending the request.
 @param response A response block which should get triggered after processing received arguments.
 */
- (void)receivedWithArguments:(TMFArguments *)arguments source:(TMFPeer *)source response:(responseBlock_t)response;

@end
