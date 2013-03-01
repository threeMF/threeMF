//
//  TMFDiscovery.m
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

#import "TMFDiscovery.h"
#import "TMFPeer.h"

#import "TMFError.h"
#import "TMFLog.h"
#import "TMFDefine.h"

static dispatch_queue_t __bonjourQueue;
static NSString *__uuid;
static TMFPeer *__localPeer;

@interface TMFDiscovery() <NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
    dispatch_queue_t _resolve_queue;    

    NSMutableArray *_discoveredServices;
    NSMutableDictionary *_peersByAddress;
    NSMutableArray *_livingPeers;

    NSMutableDictionary *_deadPeers;
    NSMutableArray *_heartBeats;

    NSMutableArray *_capabilities;

    NSNetServiceBrowser *_browser;
    NSNetService *_netService;
    NSUInteger _port;

    BOOL _running;
}
@end

@implementation TMFDiscovery
//............................................................................
#pragma mark -
#pragma mark init and Memory Management
//............................................................................
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __bonjourQueue = dispatch_queue_create("tmf.bonjour", DISPATCH_QUEUE_SERIAL);
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        __uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    });
}

- (id)init {
    if((self = [super init])!=nil) {
        _discoveredServices = [NSMutableArray new];
        _deadPeers = [NSMutableDictionary new];
        _heartBeats = [NSMutableArray new];
        _livingPeers = [NSMutableArray new];
        
        _capabilities = [NSMutableArray new];
        _resolve_queue = dispatch_queue_create("com.threemf.resolve_serivce_queue", DISPATCH_QUEUE_SERIAL);
        _peersByAddress = [NSMutableDictionary new];

        _heartBeatCommand = [[TMFHeartBeatCommand alloc] initWithRequestReceivedBlock:^(TMFHeartBeatCommandArguments *arguments, __unused TMFPeer *peer, responseBlock_t responseBlock) {
            NSError *error;
            if(arguments.UUID) {
                [self pulse:arguments.UUID];
            }
            else {
                error = [TMFError errorForCode:TMFCommandErrorCode message:@"Invalid arguments."];
            }

            if(responseBlock) {
                responseBlock(@1, error);
            }
        }];
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if ARC_HANDLES_QUEUES
    dispatch_release(_resolve_queue);
#endif
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)startOnPort:(NSUInteger)port {
    if(![self isRunning]) {
        TMFLogInfo(@"Starting discovery on port %@", @(port));
         _port = port;
        if(!_netService) {
            _netService = [[NSNetService alloc] initWithDomain:[self.configuration serviceDomain] type:[self.configuration serviceType] name:@"" port:(int)port];
            [_netService setDelegate:self];
        }
        [self publishBonJourService:_netService];
        // Do not set the txtRecordDictionary prior to publishing!!!
        // This will cause the OS to crash!!!
        [_netService setTXTRecordData:[self txtRecordData]];
    }
}

- (void)stop {
    if([self isRunning]) {
        TMFLogVerbose(@"Stopping peer browser.");
        [_browser stop];
    }
}

- (void)addCapability:(NSString *)commandName {
    if(![_capabilities containsObject:commandName]) {
        [_capabilities addObject:commandName];
        [[self class] performBonjourBlock:^{
            [_netService setTXTRecordData:[self txtRecordData]];
        }];
        TMFLogInfo(@"Added capablity %@", commandName);
    }
}

- (void)removeCapability:(NSString *)commandName {
    if([_capabilities containsObject:commandName]) {
        [_capabilities removeObject:commandName];
        [[self class] performBonjourBlock:^{
            [_netService setTXTRecordData:[self txtRecordData]];
        }];
        TMFLogInfo(@"Removed capablity %@", commandName);
    }
}

- (TMFPeer *)localPeer {
    return __localPeer;
}

- (TMFPeer *)peerByAddress:(NSData *)address {
    NSParameterAssert(address != nil);

    TMFPeer *peer = [_peersByAddress objectForKey:address];
    if(!peer) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(TMFPeer *peer, __unused NSDictionary *bindings){
            return [peer hasAddress:address];
        }];
        peer = [[_livingPeers filteredArrayUsingPredicate:predicate] lastObject];
        if(peer) {
            [_peersByAddress setObject:peer forKey:address];
        }
    }

    return peer;
}

- (NSArray *)livingPeers {
    return [NSArray arrayWithArray:_livingPeers];
}

- (BOOL)isRunning {
    return _running;
}

//............................................................................
#pragma mark -
#pragma mark NSNetServiceDelegate
//............................................................................
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    if([sender.addresses count] > 0) {
        TMFPeer *peer = [self peerForService:sender];
        if(!peer) {
            peer = [[TMFPeer alloc] initWithNetService:sender];
            if([peer.UUID isEqualToString:__uuid]) {
                if(__localPeer == nil) {
                    __localPeer = peer;
                    TMFLogVerbose(@"set local peer to: %@", peer);
                    if([self.delegate respondsToSelector:@selector(discoveryDidStart:)]) {
                        [self.delegate discoveryDidStart:self];
                    }
                    _running = YES;
                    TMFLogInfo(@"Started P2P components.");
                }
            }
            else {
                if([peer.protocolIdentifier isEqualToString:self.delegate.protocolIdentifier]) {
                    // we did already get a heartbeat from this peer
                    if([_heartBeats containsObject:peer.UUID]) {
                        [self awakePeer:peer];
                    }
                    // we need to wait for a heartbeat
                    else {
                        [_deadPeers setObject:peer forKey:peer.UUID];
                    }

                    TMFHeartBeatCommandArguments *args = [TMFHeartBeatCommandArguments new];
                    args.UUID = __uuid;
                    [_heartBeatCommand sendWithArguments:args destination:peer response:^(__unused id response, NSError *error) {
                        if(error) {
                            TMFLogError(@"Ignoring %@, could not send heart beat (%@).", peer, [error localizedDescription]);
                            [_deadPeers removeObjectForKey:peer.UUID];
                        }
                    }];
                }
                else {
                    TMFLogInfo(@"Ignoring %@ with wrong communication protocol '%@'.", peer, peer.protocolIdentifier);
                }
            }
        }
    }
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    TMFLogError(@"Unable to resolve peer %@: %@", sender.hostName, errorDict);
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    if([_discoveredServices containsObject:sender]) {
        TMFPeer *peer = [self peerForService:sender];
        if(peer) {
            [peer updateWithTXTRecordData:data];        
            if(peer != __localPeer) {
                if([self.delegate respondsToSelector:@selector(discovery:didUpdatePeer:)]) {
                    [self.delegate discovery:self didUpdatePeer:peer];
                }
            }
        }
    }
}

- (void)netServiceDidPublish:(NSNetService *)sender {
	TMFLogInfo(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%@)", [sender domain], [sender type], [sender name], @([sender port]));
    if(sender == _netService && [sender port] != 0) {
        [self browse];
    }
    else {
        TMFLogInfo(@"Bonjour service published without port.");
        [self stop];
    }
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	TMFLogError(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [sender domain], [sender type], [sender name], errorDict);
    if(sender == _netService) {
        [self stop];
    }
}

- (void)netServiceDidStop:(NSNetService *)sender {
    if(_netService == sender) {
        TMFLogInfo(@"Bonjour Service did stop: domain(%@) type(%@) name(%@) port(%i)", [sender domain], [sender type], [sender name], (int)[sender port]);        
        _netService.delegate = nil;
        [_netService stop];
        _netService = nil;
        __localPeer = nil;

        TMFLogVerbose(@"Cleaning peers.");
        if([self.delegate respondsToSelector:@selector(discovery:willRemovePeer:)]) {
            for(TMFPeer *peer in [_livingPeers copy]) {
                [self.delegate discovery:self willRemovePeer:peer];
            }
        }

        TMFLogVerbose(@"Cleaning discovered services.");
        for (NSNetService *service in [_discoveredServices copy]) {
            [self clenupService:service];
        }

        [_browser stop];
        _browser = nil;

        [self checkShutdown];
    }
    else {
        TMFLogInfo(@"Stopped resolving %@", sender);
        // stoped resolving
    }
}

//............................................................................
#pragma mark -
#pragma mark NSNetServiceBrowserDelegate
//............................................................................
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    [_discoveredServices addObject:aNetService];
    dispatch_async(_resolve_queue, ^{
        [aNetService setDelegate:self];
        [aNetService startMonitoring];
        [aNetService resolveWithTimeout:0.0f];
    });
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    TMFPeer *peer = [self peerForService:aNetService];
    if(peer) {
        if([peer.UUID isEqualToString:__uuid]) {
            __localPeer = nil;
        }
        else {
            if([self.delegate respondsToSelector:@selector(discovery:willRemovePeer:)]) {
                [self.delegate discovery:self willRemovePeer:peer];
            }
            [self removePeer:peer];
        }
    }

    [self clenupService:aNetService];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    TMFLogError(@"Error browsing for service: %@", errorDict);
    if([self.delegate respondsToSelector:@selector(discovery:didNotSearchWithError:)]) {
        [self.delegate discovery:self didNotSearchWithError:errorDict];
    }
    [self stop];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser {
    if(_browser == aNetServiceBrowser) {
        TMFLogVerbose(@"Shutting down local service.");
        [self unpublishBonjourService:_netService];

        _browser.delegate = nil;
        [_browser stop];
        _browser = nil;
    }

    [self checkShutdown];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (NSArray *)peers {
    return [NSArray arrayWithArray:_livingPeers];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
/**
 Confirms the reception of a heart beat and updates waiting peers.
 */
- (void)pulse:(NSString *)UUID {
    TMFLogVerbose(@"Received pulse %@", UUID);
    TMFPeer *deadPeer = [_deadPeers objectForKey:UUID];
    if(deadPeer) { // we have already seen this peer -> awake it
        [self awakePeer:deadPeer];
    }
    else { // we have to wait for bonjour to discover this peer
        TMFLogInfo(@"Waiting for heart beat of %@", UUID);
        [_heartBeats addObject:UUID];
    }
}

- (void)awakePeer:(TMFPeer *)peer {
    TMFLogInfo(@"%@ discovered (%@).", peer, [peer.capabilities componentsJoinedByString:@","]);
    [_livingPeers addObject:peer];
    [_deadPeers removeObjectForKey:peer.UUID];
    [_heartBeats removeObject:peer.UUID];
    
    if([self.delegate respondsToSelector:@selector(discovery:didAddPeer:)]) {
        [self.delegate discovery:self didAddPeer:peer];
    }
}

- (void)removePeer:(TMFPeer *)peer {
    NSArray *keys = [_peersByAddress allKeysForObject:peer];
    [_peersByAddress removeObjectsForKeys:keys];

    if(peer.UUID) {
        [_deadPeers removeObjectForKey:peer.UUID];
        [_heartBeats removeObject:peer.UUID];
    }

    if([_livingPeers containsObject:peer]) {
        [_livingPeers removeObject:peer];
        TMFLogInfo(@"Did remove %@", peer);
    }
}

- (void)clenupService:(NSNetService *)service {
    TMFPeer *peer = [self peerForService:service];

    [service stopMonitoring];
    service.delegate = nil;
    [_discoveredServices removeObject:service];

    [self removePeer:peer];
}

#pragma mark NSNetSerivce browsing
- (void)browse {
    if(!_browser) {
        _browser = [self createBrowser];
        [_browser searchForServicesOfType:self.configuration.serviceType inDomain:self.configuration.serviceDomain];
    }
}

- (NSNetServiceBrowser *)createBrowser {
    NSNetServiceBrowser *b = [[NSNetServiceBrowser alloc] init];
    b.delegate = self;
    return b;
}

- (void)checkShutdown {
    
    if(_running && _netService == nil && [_discoveredServices count] == 0 && [_livingPeers count] == 0 && __localPeer == nil && _browser == nil) {

        if([self.delegate respondsToSelector:@selector(discoveryDidStop:)]) {
            [self.delegate discoveryDidStop:self];
        }

        _running = NO;
        TMFLogVerbose(@"Stopped P2P components.");        
    }
}

- (NSData *)txtRecordData {
    return [NSNetService dataFromTXTRecordDictionary:@{
                @"id" : __uuid,
                // FIXME: what if _capabilities get too big for txtRecordData?
                // A placeholder should be added which indicates too much infomration for the txtRecord
                // Discovery should call the capability command to read a peer's capabilities in this case.
                @"cap" : [_capabilities componentsJoinedByString:@","],
                @"pro" : [self.delegate protocolIdentifier],
            }];
}

+ (void)performBonjourBlock:(void(^)(void))block {
    if(block){
        dispatch_sync(__bonjourQueue, block);
    }
}

- (void)publishBonJourService:(NSNetService *)service {
    [[self class] performBonjourBlock:^{
        [service removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        [service scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [service publish];
    }];
}

- (void)unpublishBonjourService:(NSNetService *)service {
	if (service) {
		[[self class] performBonjourBlock:^{
			[service stop];
            [service removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        }];
	}
}

- (TMFPeer *)peerForService:(NSNetService *)service {
    NSParameterAssert(service != nil);
    NSString *uuid = [TMFPeer UUIDFromTXTRecordData:service.TXTRecordData];

    if([[__localPeer UUID] isEqualToString:uuid]) {
        return __localPeer;
    }

    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(TMFPeer *peer, __unused NSDictionary *bindings) {
        return [peer.UUID isEqualToString:uuid] || [peer hasService:service];
    }];
    return [[_livingPeers filteredArrayUsingPredicate:predicate] lastObject];
}

@end
