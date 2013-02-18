//
//  CADDrawingController.m
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

#import "CADDrawingController.h"
#import "threeMF.h"
#import "TMFKeyValueCommand.h"
#import "CADCommands.h"
#import "CADDrawing.h"
#import "CADClient.h"

static CGFloat mapGyroAngleToPixel(CGFloat axissize, CGFloat angel) {
    return (angel * (axissize * 0.5f / (axissize/100.0f)) );     
}

@interface CADDrawingController() <TMFConnectorDelegate> {
    TMFConnector *_tmf;
    CADAnnounceCommand *_announceCmd;
    NSMutableDictionary *_clients;
    NSMutableDictionary *_menuItemsForPeers;
}
@end

@implementation CADDrawingController
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    self = [super init];
    if (self) {
        _clients = [NSMutableDictionary new];
        _tmf = [TMFConnector new];
        _tmf.delegate = self;
        
        _announceCmd = [[CADAnnounceCommand alloc] initWithRequestReceivedBlock:^(CADAnnounceCommandArguments *arguments, TMFPeer *peer, responseBlock_t responseBlock){
                                                   if(arguments) {
                                                       if(peer) {
                                                           if(responseBlock) {
                                                               responseBlock(@(YES), nil);
                                                           }
                                                           
                                                           CADClient *client = [self clientWithPeer:peer create:YES];
                                                           client.name = arguments.name;
                                                           client.color = arguments.color;
                                                           [_view updateClient:client];
                                                           
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
    }
    return self;
}

- (id)initWithView:(CADMainWindowView *)view {
    self = [self init];
    if(self) {
        _view = view;
    }
    return self;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................

//............................................................................
#pragma mark -
#pragma mark TMFConnectorDelegate
//............................................................................
// client goes offline
- (void)connector:(TMFConnector *)tmf didChangePeer:(TMFPeer *)peer forChangeType:(TMFPeerChangeType)changeType {
    if(peer != nil && ((changeType == TMFPeerChangeUpdate && ![peer.capabilities containsObject:[CADGyroMouseCommand name]]) || changeType == TMFPeerChangeRemove)) {
        [self removePeerFromClients:peer];
    }
}

// client closes the subscription (disconnect)
- (void)connector:(TMFConnector *)tmf didRemoveSubscription:(TMFPeer *)peer forCommand:(Class)commandClass {
    if(tmf == _tmf) {
        [self removePeerFromClients:peer];
    }
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)selectedConnectedClient:(NSMenuItem *)menuItem {
    [_clients enumerateKeysAndObjectsUsingBlock:^(TMFPeer *peer, CADClient *client, BOOL *stop) {
        if(client.menuItem == menuItem) {
            [_tmf unsubscribeFromPeer:peer completion:NULL];
            *stop = YES;
        }
    }];
}

- (NSMenuItem *)devicesMenuItems {
    return [self.statusMenu itemAtIndex:0];
}

- (CADClient *)clientWithPeer:(TMFPeer *)peer create:(BOOL)create {
    if(peer) {
        CADClient *client = [_clients objectForKey:peer];
        if(!client && create) {
            client = [CADClient new];
            client.peer = peer;
            client.location = [self center];
            client.menuItem = [[NSMenuItem alloc] initWithTitle:peer.name action:@selector(selectedConnectedClient:) keyEquivalent:@""];
            [client.menuItem setEnabled:YES];
            [client.menuItem setTarget:self];
            
            if(![[self devicesMenuItems] hasSubmenu]) {
                [[self devicesMenuItems] setSubmenu:[[NSMenu alloc] init]];
            }

            [[[self devicesMenuItems] submenu] addItem:client.menuItem];
            [_clients setObject:client forKey:peer];
            [[self devicesMenuItems] setEnabled:[_clients count]>0];
        }
        
        return client;
    }

    return nil;
}

- (void)subscribeMeta:(TMFPeer *)peer {
    // -------------------------------
    // Metainformation updates
    // -------------------------------
    if([peer.capabilities containsObject:[CADClientMetaInformationCommand name]]) {
        [_tmf subscribe:[CADClientMetaInformationCommand class]
          configuration:nil
                   peer:peer
                receive:^(CADClientMetaInformationCommandArguments *arguments, TMFPeer *peer){
//                    NSLog(@"name: %@, color. %@", arguments.name, arguments.color);
                    CADClient *client = [self clientWithPeer:peer create:YES];
                    client.color = arguments.color;
                    client.name = arguments.name;
                    [_view updateClient:client];
                }
             completion:^(NSError *error){
                 if(error) {
                     NSLog(@"%@", error);
                 }
             }];
    }
}

- (void)subscribeKeyValue:(TMFPeer *)peer {
    // -------------------------------
    // undo, redo, clear...
    // -------------------------------
    if([peer.capabilities containsObject:[TMFKeyValueCommand name]]) {
        [_tmf subscribe:[TMFKeyValueCommand class]
                   peer:peer
                receive:^(TMFKeyValueCommandArguments *arguments, TMFPeer *peer){
//                    NSLog(@"%@: %@", arguments.key, arguments.value);

                    CADClient *client = [self clientWithPeer:peer create:YES];
                    if([arguments.key isEqualToString:@"center"]) {
                        client.location = [self center];
                    }
                    else if([arguments.key isEqualToString:@"draw"]) {
                        if([arguments.value isEqualToString:@"begin"]) {
                            [client startPath];
                        }
                        else if([arguments.value isEqualToString:@"end"]) {
                            [client endPath];
                        }
                    }
                    else if ([arguments.key isEqualToString:@"do"]) {
                        if([arguments.value isEqualToString:@"clear"]) {
                            [client clear];
                        }
                        else if([arguments.value isEqualToString:@"redo"]) {
                            [client redo];
                        }
                        else if([arguments.value isEqualToString:@"undo"]) {
                            [client undo];
                        }
                    }

                    [_view updateClient:client];
                }
             completion:^(NSError *error){
                 if(error) {
                     NSLog(@"%@", error);
                 }
             }];
    }
}

- (void)subscribeGyro:(TMFPeer *)peer {
    // -------------------------------
    // Gyroscope updates
    // -------------------------------
    if([peer.capabilities containsObject:[CADGyroMouseCommand name]]) {
        [_tmf subscribe:[CADGyroMouseCommand class]
                   peer:peer
                receive:^(CADGyroMouseCommandArguments *args, TMFPeer *peer){
                    [self updateMotionDataWithX:args.x y:args.y peer:peer];
                }
             completion:^(NSError *error){
                 if(error) {
                     NSLog(@"%@", error);
                 }
             }];
    }
}

- (void)updateMotionDataWithX:(double)x y:(double)y peer:(TMFPeer *)peer {
    CGFloat w = [self size].width;
    CGFloat h = [self size].height;
    CGFloat newX = fminf(w, [self center].x + mapGyroAngleToPixel(w,x));
    CGFloat newY = fminf(h, [self center].y + mapGyroAngleToPixel(h,y));
    CGPoint point = CGPointMake(newX, newY);

    CADClient *client = [self clientWithPeer:peer create:YES];
    client.location = point;
    [_view updateClient:client];
}

- (CGPoint)center {
    return CGPointMake(CGRectGetMidX(_view.bounds), CGRectGetMidY(_view.bounds));
}

- (CGSize)size {
    return [_view bounds].size;
}

- (void)removePeerFromClients:(TMFPeer *)peer {
    if([_clients objectForKey:peer]) {
        CADClient *client = [_clients objectForKey:peer];
        if(client) {
            [_view removeClient:client];
            [[[self devicesMenuItems] submenu] removeItem:client.menuItem];
            [_clients removeObjectForKey:peer];
            [[self devicesMenuItems] setEnabled:[_clients count]>0];
        }
    }
}

@end
