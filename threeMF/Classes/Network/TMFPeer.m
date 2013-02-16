//
//  TMFPeer.m
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

#import "TMFPeer.h"
#import "GCDAsyncSocket.h"
#import "TMFLog.h"

#include <arpa/inet.h>
#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>

@interface TMFPeer () {
    NSNetService *_service;
    NSString *_hostName;
    NSMutableArray *_addresses;
    NSArray *_previousCapabilities;
    NSMutableDictionary *_portsByCommand;
}
@end

@implementation TMFPeer
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    self = [super init];
    if(self) {
        _UUID = @"";
        _protocolIdentifier = @"";
        _domain = @"";
        _name = @"";
        _hostName = @"";
        _addresses = [NSMutableArray new];
        _capabilities = [NSArray new];

        _portsByCommand = [NSMutableDictionary new];
    }
    return self;
}

- (id)initWithNetService:(NSNetService *)netService {
    NSParameterAssert(netService!=nil);
    self = [self init];
    if(self) {
        _service = netService;
        _domain = [[netService domain] copy];
        _name = [[netService name] copy];
        _hostName = [[netService hostName] copy];
        _addresses = [[NSMutableArray alloc] initWithArray:[netService addresses] copyItems:YES];
        [self updateWithTXTRecordData:netService.TXTRecordData];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    TMFPeer *copy = [TMFPeer new]; // also tired: [[TMFPeer allocWithZone:zone] init];
    copy->_UUID = self.UUID; // copy property
    copy->_protocolIdentifier = self.protocolIdentifier;
    copy->_domain = self.domain; // copy property
    copy->_name = self.name; // copy property
    copy->_addresses = [[NSMutableArray alloc] initWithArray:_addresses copyItems:YES];
    copy->_hostName = self.hostName; // copy property
    copy->_capabilities = [[NSArray alloc] initWithArray:self.capabilities copyItems:YES];
    return copy;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)setPort:(NSUInteger)port {
    NSMutableArray *newAddresses = [NSMutableArray arrayWithCapacity:[_addresses count]];
    for(NSData *address in [_addresses copy]) {
        [newAddresses addObject:[TMFPeer addressWithAddress:address port:port]];
    }
    _addresses = newAddresses;
}

- (void)setPort:(NSUInteger)port commandName:(NSString *)commandName {
    if(commandName) {
        [_portsByCommand setObject:@(port) forKey:commandName];
    }
}

- (NSUInteger)portForCommandName:(NSString *)commandName {
    if(commandName && [_portsByCommand objectForKey:commandName]) {
        return [[_portsByCommand objectForKey:commandName] unsignedIntegerValue];
    }
    return [GCDAsyncSocket portFromAddress:[self firstAddress]]; // system channel port
}

- (void)updateWithTXTRecordData:(NSData *)data {
    NSParameterAssert(data!=nil);
    NSString *uuid = [TMFPeer UUIDFromTXTRecordData:data];
    
    if(_UUID == nil || [_UUID length] == 0 || [_UUID isEqualToString:uuid]) {
        NSDictionary *TXTRecord = [NSNetService dictionaryFromTXTRecordData:data];        
        _UUID = [uuid copy];
        _protocolIdentifier = [TMFPeer protocolIdentifierFromTXTRecord:TXTRecord];

        NSArray *previousCapabilities = [NSArray arrayWithArray:_capabilities];
        NSArray *newCapabilities = [TMFPeer capabilitiesFromTXTRecord:TXTRecord];

        if(![_capabilities isEqualToArray:newCapabilities]) {
            [self willChangeValueForKey:@"capabilities"];
            _capabilities = newCapabilities;
            [self didChangeValueForKey:@"capabilities"];

            if(![[NSSet setWithArray:previousCapabilities] isEqualToSet:[NSSet setWithArray:_capabilities]]) {
                _previousCapabilities = previousCapabilities;
            }
            else {
                _previousCapabilities = [NSArray new];
            }
        }
    }
    else {
        TMFLogError(@"Can not update peer with different UUID %@ vs. %@.", _UUID, uuid);
    }
}

- (BOOL)hasAddress:(NSData *)address {
    for (NSData *addressdata in _addresses) {
        if([[GCDAsyncSocket hostFromAddress:address] isEqualToString:[GCDAsyncSocket hostFromAddress:addressdata]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasService:(NSNetService *)service {
    return [_service isEqual:service];
}

+ (NSString *)UUIDFromTXTRecordData:(NSData *)data {
    NSDictionary *TXTRecord = [NSNetService dictionaryFromTXTRecordData:data];
    NSString *uuid = [[NSString alloc] initWithData:[TXTRecord objectForKey:@"id"] encoding:NSUTF8StringEncoding];
    return uuid;
}

+ (NSString *)stringFromAddressData:(NSData *)data {
    return [NSString stringWithFormat:@"%@:%d", [GCDAsyncSocket hostFromAddress:data], [GCDAsyncSocket portFromAddress:data]];
}

- (void)addAddressesFromNetService:(NSNetService *)netService {
    [_addresses addObjectsFromArray:netService.addresses];
}

- (BOOL)isEqualHost:(TMFPeer *)peer {
    __block BOOL equalHost = NO;

    // prepare comparing addresses
    NSMutableArray *addresses = [NSMutableArray new];
    for (NSData *addressdata in [peer.addresses copy]) {
        [addresses addObject:[TMFPeer addressWithAddress:addressdata port:0]]; // cut off port
    }

    // compare addresses
    [[_addresses copy] enumerateObjectsUsingBlock:^(NSData *address, __unused NSUInteger idx, BOOL *stop) {
        if([addresses containsObject:[TMFPeer addressWithAddress:address port:0]]) {
            equalHost = YES;
        }
        *stop = equalHost;
    }];

    return equalHost;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (NSString *)hostName {
    return (_hostName != nil && [_hostName length] > 0 ? _hostName : [GCDAsyncSocket hostFromAddress:[self firstAddress]]);
}

- (NSArray *)addresses {
    NSMutableArray *addresses = [NSMutableArray new];
    struct  sockaddr_in *socketAddress;
    for(NSData *adr in [_addresses copy]) {
        socketAddress = (struct sockaddr_in *)[adr bytes];
        if(socketAddress->sin_family == AF_INET || socketAddress->sin_family == AF_INET6) {
            [addresses addObject:adr];
        }
    }
    return [NSArray arrayWithArray:addresses];
}

- (NSArray *)previousCapabilities {
    return _previousCapabilities;
}

- (BOOL)didChangeCapabilitiesOnLastUpdate {
    return [self.previousCapabilities count]!=0;
}

- (BOOL)isEqual:(id)object {
    if(self == object) {
        return YES;
    }
    else if([object isKindOfClass:[self class]])  {
        return [((TMFPeer *)object).UUID isEqualToString:self.UUID];
    }
    
    return NO;
}

- (NSUInteger)hash {
    return [self.UUID hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", _hostName, self.UUID, self.protocolIdentifier];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (NSData *)firstAddress {
    for(NSData *a in self.addresses) {
        if(((struct sockaddr *)[a bytes])->sa_family == AF_INET || ((struct sockaddr *)[a bytes])->sa_family == AF_INET6
           ) {
            return a;
        }
    }
    return nil;
}

+ (NSData *)addressWithAddress:(NSData *)addr port:(NSUInteger)port {
    NSMutableData *address = [addr mutableCopy];
    struct  sockaddr_in *socketAddress = (struct sockaddr_in *)[address mutableBytes];
    socketAddress->sin_port = htons(port);
    return address;
}

+ (NSArray *)capabilitiesFromTXTRecord:(NSDictionary *)TXTRecord {
    NSString *capabilities = [[NSString alloc] initWithData:[TXTRecord objectForKey:@"cap"] encoding:NSUTF8StringEncoding];
    return [capabilities componentsSeparatedByString:@","];
}

+ (NSString *)protocolIdentifierFromTXTRecord:(NSDictionary *)TXTRecord {
    return [[NSString alloc] initWithData:[TXTRecord objectForKey:@"pro"] encoding:NSUTF8StringEncoding];
}

@end
