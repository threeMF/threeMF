//
//  TMFPeer.h
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

/**
 This class represents a 3MF network peer. Each peer is based on a resolved NSNetService instance and identified by it's unique UUID.
 */
@interface TMFPeer : NSObject <NSCopying>

/**
 The UUID identifying the peer.
 @warning This UUID currently changes with every new 3MF session. Persisting the UUID for each installation can be discussed but currently I'm not seeing any need for it.
 */
@property (nonatomic, readonly, copy) NSString *UUID;

/**
 The identifier for the protocol used by this peer.
 */
@property (nonatomic, readonly, copy) NSString *protocolIdentifier;

/**
 The name of the peer.
 */
@property (nonatomic, readonly, copy) NSString *name;

/**
 The hostname of the peer.
 */
@property (nonatomic, readonly, copy) NSString *hostName;

/**
 The domain the peer was discovered in.
 */
@property (nonatomic, readonly, copy) NSString *domain;

/**
 All known AF_INET and AF_INET6 addresses of the host. This list may also include unreachable addresses.
 The address may be a sockaddr_in or sockaddr_in6 and may include a port (otherwise the port is 0).
 */
@property (nonatomic, readonly, copy) NSArray *addresses;

/**
 A list of command names the peer has published.
 */
@property (nonatomic, copy) NSArray *capabilities;

/**
 A list of command names the peer had published before the previous change.
 If this array is empty, the capabilities have not changed from the last update.
 */
@property (nonatomic, readonly) NSArray *previousCapabilities;

/**
 A convenience flag expressing if the last update operation included a capability change.
 */
@property (nonatomic, readonly) BOOL didChangeCapabilitiesOnLastUpdate;

/**
 Creates a new TMFPeer instance based on a resolved NSNetService
 @param netService The resolved NSNetService of a discovered peer
 @return A new peer instance
 @warning The NSNetService must be resolved!
 */
- (id)initWithNetService:(NSNetService *)netService;

/**
 Sets the port used for a specific command.
 The ports are defined by the command's corresponding TMFChannel.
 @param port The port used for the given command.
 @param commandName The unique command name provided by [TMFCommand name].
 */
- (void)setPort:(NSUInteger)port commandName:(NSString *)commandName;

/**
 Gets the port used for a specific command.
 The ports are defined by the command's corresponding TMFChannel. 
 @param commandName The unique command name provided by [TMFCommand name]. 
 @return The port for the given command
 */
- (NSUInteger)portForCommandName:(NSString *)commandName;

/**
 Updates the peers meta information based on [NSNetService TXTRecordData]
 @param data The new data provided by the NSNetService [NSNetService TXTRecordData]
 */
- (void)updateWithTXTRecordData:(NSData *)data;

/**
 @param address The sockaddr_in or sockaddr_in6 address the peer should have
 @return YES if the peer has the specified address. Otherwise NO.
 */
- (BOOL)hasAddress:(NSData *)address;

/**
 @param service The NSNetService the peer may be based on.
 @return YES if the internal NSNetService is the same as the provided one. Otherwise NO.
 */
- (BOOL)hasService:(NSNetService *)service;

/**
 Extracts a peer's UUID from a NSNetService's [NSNetService TXTRecordData]
 @param data a NSNetService's [NSNetService TXTRecordData]
 @return The extracted UUID. Nil if no UUID is found.
 */
+ (NSString *)UUIDFromTXTRecordData:(NSData *)data;

/**
 Translates sockaddr_in or sockaddr_in6 addresses to NSString.
 @param data The sockaddr_in or sockaddr_in6 data
 @return The string representation of the given address.
 */
+ (NSString *)stringFromAddressData:(NSData *)data;

@end
