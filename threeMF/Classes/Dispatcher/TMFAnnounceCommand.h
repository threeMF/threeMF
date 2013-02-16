//
//  TMFAnnounceCommand.h
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
#import "TMFRequestResponseCommand.h"
#import "TMFArguments.h"

/**
 Abstract system command class used to announce capabilities to other peers.
 Use subclasses of this command to announce a specific service for reverse discovery.
 This is a special case when the provider of a service is also the one discovering other services.
 The announce command helps the discoverer to find peers capable of subscribing to services the discoverer is providing.
 The corresponding arguments class is TMFAnnounceCommandArguments.

 - unique name: no name given! abstract class.
 - system command

 ## Usage

 This command is used to announce interest in subscribing to commands. The AirDraw and MultiAirCam samples use this
 pattern. In AirDraw the iOS device is provider for gyroscope information to visualize a pointer on the canvas. 
 The canvas is subscriber but it also announces it's interest in subscribing to gyroscope data for drawing. 
 The iOS client is responsible to find a canvas to draw on (the user selects the canvas) and therefore it needs to search for something.
 In this case it searches for a specific announce command to tell the canvas that it should subscribe to it's drawing
 commands.
 
 ### Announcing
     _announceCmd = [[CADAnnounceCommand alloc] initWithRequestReceivedBlock:^(CADAnnounceCommandArguments *arguments, TMFPeer *peer, responseBlock_t responseBlock){
            if(arguments) {
                if(peer) {
                    if(responseBlock) {
                        responseBlock(@(YES), nil);
                    }
                    // create a client to display
                    CADClient *client = [self clientWithPeer:peer create:YES];
                    client.name = arguments.name;
                    client.color = arguments.color;
                    [_view updateClient:client];

                    // subscribe to the client
                    [self subscribeMeta:peer];
                    [self subscribeKeyValue:peer];
                    [self subscribeGyro:peer];
                }
                else {
                    NSLog(@"Received invalid CADAnnounceCommandArguments %@", arguments);
                    if(responseBlock) {
                        responseBlock(@(NO), nil);
                    }
                }
            }
            else {
                NSLog(@"Received nil CADAnnounceCommandArguments");
                if(responseBlock) {
                    responseBlock(@(NO), nil);
                }
            }
     }];
     [_tmf publishCommand:_announceCmd];
 
 ### Sending announce request
     CADAnnounceCommandArguments *args = [CADAnnounceCommandArguments new];
     args.name = self.nameLabel.text;
     args.color = _color;

     [_tmf sendCommand:[CADAnnounceCommand class] arguments:args destination:peer
        response:^(id response, NSError *error){
            if(error) {
                NSLog(@"%@", [error localizedDescription]);
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil
                    cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                    otherButtonTitles:nil] show];
            }
            else {
                [self closeServiceBrowser];
                self.host = peer;
                [self broadcastMetaInfo];
            }
     }];
 
 @warning It is crucial to give each TMFAnnounceCommand subclass a unique name!  
 */
@interface TMFAnnounceCommand : TMFRequestResponseCommand
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 Arguments class for TMFAnnounceCommand
 */
@interface TMFAnnounceCommandArguments : TMFArguments
@end
