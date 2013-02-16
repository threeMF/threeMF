//
//  TMFDiscoveryDelegate.h
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

@class TMFDiscovery, TMFPeer;

/**
 Delegate protocol for TMFDiscovery objects.
 */
@protocol TMFDiscoveryDelegate <NSObject>

@required
/**
 Defines the main channels communication protocol for compatibility checks.
 All peers have to communicate with the same protocol and coder version.
 */
- (NSString *)protocolIdentifier;

@optional
/**
 Gets called after all discovery components did start.
 @param discovery The discovery object finding the peer.
 */
- (void)discoveryDidStart:(TMFDiscovery *)discovery;

/**
 Gets called after all discovery components did stop.
 @param discovery The discovery object finding the peer.
 */
- (void)discoveryDidStop:(TMFDiscovery *)discovery;

/**
 Gets called when a peer satisfying the required capabilities is found.
 @param discovery The discovery object finding the peer.
 @param peer The peer discovered by the discovery object.
 */
- (void)discovery:(TMFDiscovery *)discovery didAddPeer:(TMFPeer *)peer;

/**
 Gets called when a host is offline and not gone online again for 2 minutes.
 @param discovery The discovery object finding the peer.
 @param peer The peer discovered by the discovery object.
 */
- (void)discovery:(TMFDiscovery *)discovery willRemovePeer:(TMFPeer *)peer;

/**
 Gets called when a host gets updated.
 @param discovery The discovery object finding the peer.
 @param peer The peer discovered by the discovery object.
 */
- (void)discovery:(TMFDiscovery *)discovery didUpdatePeer:(TMFPeer *)peer;

/**
 Gets called if the discovery could not start.
 @param discovery The discovery object finding the peer.
 @param errorDict The dictionary containing a reason.
 */
- (void)discovery:(TMFDiscovery *)discovery didNotSearchWithError:(NSDictionary *)errorDict;

@end
