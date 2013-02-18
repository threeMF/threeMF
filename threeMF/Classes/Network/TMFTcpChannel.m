//
//  TMFTcpChannel.m
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

#import "TMFTcpChannel.h"
#import "TMFTcpChannelConnection.h"
#import "GCDAsyncSocket.h"
#import "TMFPublishSubscribeCommand.h"
#import "TMFRequestResponseCommand.h"
#import "TMFResponseCallback.h"

#import "TMFError.h"
#import "TMFLog.h"
#import "TMFDefine.h"

#import <sys/socket.h>
#import <arpa/inet.h>
#include <netinet/tcp.h>

static NSUInteger __counter;
static NSLock *__counterLock;

@interface TMFTcpChannel()<GCDAsyncSocketDelegate, TMFTcpChannelConnectionDelegate> {
    NSMutableDictionary *_responseCallbacks;
    NSMutableDictionary *_outPubSubSockets;
    NSMutableArray *_outReqResSockets;
    NSMutableArray *_connections;

    NSLock *_callbacksLock;
    NSLock *_socketsLock;
    NSLock *_startupLock;

    GCDAsyncSocket *_socket;
    dispatch_queue_t _socketQueue;
    dispatch_queue_t _connectionsQueue;
    dispatch_queue_t _socketDelegationQueue;

    // tmp
    stopCompletionBlock_t _shutdownCompletionBlock;
}
@end

@implementation TMFTcpChannel
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
+ (void)initialize {
    __counterLock = [NSLock new];
}

- (id)initWithPort:(NSUInteger)port protocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate {
    self = [super initWithPort:port protocol:protocol delegate:delegate];
    if(self) {
        _responseCallbacks = [NSMutableDictionary new];
        _outPubSubSockets = [NSMutableDictionary new];
        _outReqResSockets = [NSMutableArray new];
        _connections = [NSMutableArray new];

        _socketsLock = [NSLock new];
        _callbacksLock = [NSLock new];
        _startupLock = [NSLock new];

        _socketQueue = dispatch_queue_create("tmf.channel.tcp", DISPATCH_QUEUE_SERIAL);
        _connectionsQueue = dispatch_queue_create("tmf.channel.tcp.connections", DISPATCH_QUEUE_SERIAL);
        _socketDelegationQueue = dispatch_queue_create("tmf.channel.tcp.working", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    [self performBlockOnSocketQueue:^{
        [_socket setDelegate:nil delegateQueue:NULL];
        [_socket disconnect];
    }];

    [_responseCallbacks removeAllObjects];

#if ARC_HANDLES_QUEUES
    dispatch_release(_socketQueue);
    dispatch_release(_connectionsQueue);
    dispatch_release(_socketDelegationQueue);
#endif
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
+ (NSUInteger)nextIdentifier {
    [__counterLock lock];
    NSUInteger identifier = __counter;    
    __counter = __counter + 1;
    [__counterLock unlock];
    return identifier;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)send:(TMFCommand *)command arguments:(TMFArguments *)arguments destination:(TMFPeer *)peer responseBlock:(responseBlock_t)responseBlock {
    NSParameterAssert(peer!=nil);
    NSParameterAssert(command!=nil);
    BOOL publishSubscribe = [command isKindOfClass:[TMFPublishSubscribeCommand class]];
    if (!publishSubscribe) {
        NSParameterAssert(responseBlock!=nil);
    }

    arguments.identifier = [[self class] nextIdentifier];

    GCDAsyncSocket *socket = [self socketForCommand:command peer:peer];

    if(socket) {
        [self addResponseBlock:responseBlock identifier:arguments.identifier peer:peer socket:socket];
        NSData *data = [self.protocol requestDataForCommand:command arguments:arguments];
        [socket writeData:data withTimeout:TIMEOUT tag:0];
        if(!publishSubscribe) {
            [socket readDataToLength:[self.protocol requestResponseHeaderLength] withTimeout:TIMEOUT tag:RESPONSE_HEADER_TAG];
        }
    }
    else {
        dispatch_async(self.delegate.callbackQueue, ^{
            if(responseBlock) {
                responseBlock(nil, [NSError errorWithDomain:@"Could not create socket." code:0 userInfo:nil]);
            }
        });
    }
}

- (void)removePeer:(TMFPeer *)peer {
    
    // gettig rid of publish subscribe
    NSArray *peerSocketKeys = [[_outPubSubSockets allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *key, __unused NSDictionary *bindings) {
        return [key hasSuffix:peer.UUID];
    }]];

    // gettig rid of reqest response sockets
    NSArray *sockets = [_outReqResSockets filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GCDAsyncSocket *evaluatedObject, __unused NSDictionary *bindings) {
        return [[evaluatedObject userData] isEqual:peer];
    }]];

    for(NSString *key in peerSocketKeys) {
        [[_outPubSubSockets objectForKey:key] disconnect];
    }

    for(GCDAsyncSocket *socket in sockets) {
        [socket disconnect];
    }

    [_socketsLock lock];
    [_outPubSubSockets removeObjectsForKeys:peerSocketKeys];
    [_outReqResSockets removeObjectsInArray:sockets];
    [_socketsLock unlock];
}

- (NSUInteger)port {
    __block NSUInteger port;
    [self performBlockOnSocketQueue:^{
        port = _socket.localPort;
    }];
    return port;
}

- (void)start:(startCompletionBlock_t)completion {
    [self performBlockOnSocketQueue:^{
        [_startupLock lock];
        @autoreleasepool {
            if(![self isRunning]) {
                NSError *error = nil;
                _running = [self startTCPService:&error];
                if(!_running) {
                    [self stop:nil];
                    TMFLogError(@"Error starting %@ %@", NSStringFromClass([self class]), error);
                }
                else {
                    TMFLogInfo(@"Started %@ on port %@.", NSStringFromClass([self class]), @(_socket.localPort));
                }

                if(completion) {
                    dispatch_async(self.delegate.callbackQueue, ^{ completion(error); });
                }
            }
        }
        [_startupLock unlock];
    }];
}

- (void)stop:(stopCompletionBlock_t)completion {
    [self performBlockOnSocketQueue:^{
        @autoreleasepool {
            if(completion) {
                _shutdownCompletionBlock = [completion copy];
            }

            [self closeTcpSocketAndDisconnectAllClients];
            _running = NO;
        }
    }];
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................
#pragma mark TMFConnectionDelegate
- (void)connection:(TMFTcpChannelConnection *)connection didReadRequest:(TMFRequest *)request fromAddress:(NSData *)address {
    if(connection && request && address) {
        dispatch_async(self.delegate.callbackQueue, ^{
            [self.delegate receiveOnChannel:self
                                commandName:request.commandName
                                  arguments:request.arguments
                                    address:address
                                   response:^(NSDictionary *result, NSError *error) {
                                       dispatch_async(_connectionsQueue, ^{
                                           [connection sendResponseForRequest:request result:result error:error];
                                       });
                                   }];
        });
    }
    else {
        TMFLogInfo(@"Empty request (%@), conneciton (%@) or address (%@)", request, connection, address);
    }
}

- (void)connection:(TMFTcpChannelConnection *)conneciton didDisconnect:(GCDAsyncSocket *)socket withError:(NSError *)error {
    dispatch_async(_connectionsQueue, ^{
        [_socketsLock lock];
        [_connections removeObject:conneciton];
        [_socketsLock unlock];
    });

    TMFLogVerbose(@"Connection <%@> to %@ disconnected with error %@.", conneciton, socket.userData, error);
}

#pragma mark GCDAsyncSocketDelegate
/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (sock != _socket) {
        TMFResponse *response = nil;
        __block NSError *error = nil;
        NSMutableArray *callbacks = [NSMutableArray new];

        if(tag == RESPONSE_HEADER_TAG) {
            [self.protocol parseHeader:data completion:^(uint64_t length, NSError *parseError) {
                if(!parseError && length > 0) {
                    [sock readDataToLength:length withTimeout:-1 tag:RESPONSE_BODY_TAG];
                }
                else {
                    TMFLogError(@"Invalid message header (%@)", parseError);
                    error = parseError;
                    [callbacks addObjectsFromArray:[self removeResponseBlocksForSocket:sock]];
                }
            }];
        }
        else if(tag == RESPONSE_BODY_TAG) {         
            response = [self.protocol responseFromData:data];
            if(response) {
                [callbacks addObject:[self removeResponseCallback:response]];
                if([callbacks count] == 0) {
                    error = [TMFError errorForCode:TMFChannelErrorCode message:@"No response callback block found!"];
                }
            }
            else {
                error = [TMFError errorForCode:TMFChannelErrorCode message:@"Received empty TMFResponse"];
                [callbacks addObjectsFromArray:[self removeResponseBlocksForSocket:sock]];
            }           
        }

        if(!error && response.error != nil) {
            error = [TMFError errorForCode:TMFResponseErrorCode message:response.error];
        }

        // execute response blocks
        [self executeResponseCallbacks:callbacks result:response.result error:error];

        // FIXME: each request response gets a new connection at the moment, this disconnect needs to get removed if error == nil when refactoring for reusable connections!
        if(error || tag == RESPONSE_BODY_TAG) {
            [sock disconnect];
        }
    }
}

/**
 * This method is called immediately prior to socket:didAcceptNewSocket:.
 * It optionally allows a listening socket to specify the socketQueue for a new accepted socket.
 * If this method is not implemented, or returns NULL, the new accepted socket will create its own default queue.
 *
 * Since you cannot autorelease a dispatch_queue,
 * this method uses the "new" prefix in its name to specify that the returned queue has been retained.
 *
 * Thus you could do something like this in the implementation:
 * return dispatch_queue_create("MyQueue", NULL);
 *
 * If you are placing multiple sockets on the same queue,
 * then care should be taken to increment the retain count each time this method is invoked.
 *
 * For example, your implementation might look something like this:
 * dispatch_retain(myExistingQueue);
 * return myExistingQueue;
 **/
- (dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock {
#if ARC_HANDLES_QUEUES
    dispatch_retain(_connectionsQueue);
#endif
    return _connectionsQueue;
}

/**
 * Called when a socket accepts a connection.
 * Another socket is automatically spawned to handle it.
 *
 * You must retain the newSocket if you wish to handle the connection.
 * Otherwise the newSocket instance will be released and the spawned connection will be closed.
 *
 * By default the new socket will have the same delegate and delegateQueue.
 * You may, of course, change this at any time.
 **/
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    if(sock == _socket) {
        dispatch_async(_connectionsQueue, ^{
            TMFTcpChannelConnection *connection = [[TMFTcpChannelConnection alloc] initWithSocket:newSocket protocol:self.protocol delegate:self];
            [_socketsLock lock];
            [_connections addObject:connection];
            [_socketsLock unlock];
        });
    }
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
    if(error && error.code != GCDAsyncSocketClosedError) {
        TMFLogError(@"TCP Socket (%@) disconnected with Error: %@", sock, error);
        // lets make sure response callbacks get called even if we have an error (e.g. timeout)
        NSArray *blocks = [self removeResponseBlocksForSocket:sock];
        [self executeResponseCallbacks:blocks result:nil error:error];
    }

    if(sock == _socket) {
        // close all connections
        [_socketsLock lock];
        [_connections removeAllObjects];
        [_outPubSubSockets removeAllObjects];
        [_outReqResSockets removeAllObjects];
        [_socketsLock unlock];

        TMFLogInfo(@"System TCP channel socket disconnected!");
        if(_shutdownCompletionBlock != nil && ![self isRunning]) {
            stopCompletionBlock_t stopCompletion = [_shutdownCompletionBlock copy];
            _shutdownCompletionBlock = nil;
            dispatch_async(self.delegate.callbackQueue, ^{
                stopCompletion();
            });
        }
    }
    else {
        [self removeSocket:sock];
    }

    TMFLogVerbose(@"Socked <%@> to %@ disconnected with error %@.", sock, sock.userData, error);
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (BOOL)startTCPService:(NSError **)error {
    __block BOOL done = NO;
    if(self.protocol) {
        if(!_socket) {
            _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketDelegationQueue socketQueue:_socketQueue];
        }

        if([_socket acceptOnPort:super.port error:error]) {
            done = YES;
        }
        else {
            TMFLogError(@"Error in acceptOnPort:error: -> %@", *error);
        }
    }
    else {
        TMFLogError(@"No protocol provided.");
    }

    return done;
}

- (GCDAsyncSocket *)createSocketForPeer:(TMFPeer *)peer {
    TMFLogVerbose(@"Creating socket for peer %@", peer);
    GCDAsyncSocket *socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketDelegationQueue socketQueue:_socketQueue];
    [socket setUserData:peer];
    return socket;
}

- (GCDAsyncSocket *)socketForCommand:(TMFCommand *)command peer:(TMFPeer *)peer {

    GCDAsyncSocket *socket = nil;
    if([command isKindOfClass:[TMFRequestResponseCommand class]]) {
        // disabling reuse for request response commands because
        // sending a request while waiting for a response is not supported
        // TODO: a better strategy may be queing requests to avoid new sockets for each request
        socket = [self createSocketForPeer:peer];
        [_socketsLock lock];
        [_outReqResSockets addObject:socket];
        [_socketsLock unlock];        
    } else {
        // reuse previously created socket for publish subscribe
        NSString *key = [NSString stringWithFormat:@"%@:%@", command.name, peer.UUID];
        socket = [_outPubSubSockets objectForKey:key];
        if(!socket) {
            socket = [self createSocketForPeer:peer];
            [_socketsLock lock];
            [_outPubSubSockets setObject:socket forKey:key];
            [_socketsLock unlock];
        }

        // disablel nagle's algorithm for small messages
        if([command isKindOfClass:[TMFPublishSubscribeCommand class]] && [[command class] isRealTime]) {
            [self disableDelay:YES socket:socket];
        }
    }

    // connect
    if(![socket isConnected]) {
        NSError *error = nil;
        NSUInteger port = [peer portForCommandName:command.name];
        TMFLogVerbose(@"Trying to connect to %@:%@", peer.hostName, @(port));
        if([socket connectToHost:peer.hostName onPort:port error:&error]){
            if(!error) {
                error = nil;
                TMFLogVerbose(@"Connected to %@:%@", peer.hostName, @(port));
            }
        }

        if(error) {
            TMFLogError(@"Could not connect to %@. Reason: %@", peer, error);
            [self removeSocket:socket];
            return nil;
        }
    }

    return socket;
}

- (void)closeTcpSocketAndDisconnectAllClients {
    [_socket disconnect];
    [_socketsLock lock];
    [_connections removeAllObjects];
    [_socketsLock unlock];
}

- (void)removeSocket:(GCDAsyncSocket *)sock {
    // remove stored references
    __block id socketKey = nil;
    [_outPubSubSockets enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if(obj == sock) {
            socketKey = key;
            *stop = YES;
        }
    }];

    [_socketsLock lock];
    [_outReqResSockets removeObject:sock];
    if(socketKey) {
        [_outPubSubSockets removeObjectForKey:socketKey];
    }
    [_socketsLock unlock];
}

- (void)executeResponseCallbacks:(NSArray *)callbacks result:(id)result error:(NSError *)error {
    dispatch_async(self.delegate.callbackQueue, ^{
        for(TMFResponseCallback *callback in callbacks) {
            callback.responseBlock(result, error);
        }
    });
}

- (NSArray *)removeResponseBlocksForPeer:(TMFPeer *)peer {
    return [self removeResponseBlocksWithPredicate:[NSPredicate predicateWithBlock:^BOOL(TMFResponseCallback *callback, __unused NSDictionary *bindings) {
        return [callback.peer isEqual:peer];
    }]];
}

- (NSArray *)removeResponseBlocksForSocket:(GCDAsyncSocket *)socket {
    return [self removeResponseBlocksWithPredicate:[NSPredicate predicateWithBlock:^BOOL(TMFResponseCallback *callback, __unused NSDictionary *bindings) {
        return callback.socket == socket;
    }]];
}

- (NSArray *)removeResponseBlocksWithPredicate:(NSPredicate *)predicate {
    NSArray *blocks = [[_responseCallbacks allValues] filteredArrayUsingPredicate:predicate];
    NSSet *keys = [_responseCallbacks keysOfEntriesPassingTest:^BOOL(__unused id key, id obj, __unused BOOL *stop) {
        return [blocks containsObject:obj];
    }];

    [_callbacksLock lock];
    [_responseCallbacks removeObjectsForKeys:[keys allObjects]];
    [_callbacksLock unlock];

    return [NSArray arrayWithArray:blocks];
}

- (TMFResponseCallback *)removeResponseCallback:(TMFResponse *)response {
    TMFResponseCallback *callback = [_responseCallbacks objectForKey:response.identifier];
    if(callback) {
        [_callbacksLock lock];
        [_responseCallbacks removeObjectForKey:response.identifier];
        [_callbacksLock unlock];
    }
    return callback;
}

- (void)addResponseBlock:(responseBlock_t)block identifier:(NSUInteger)identifier peer:(TMFPeer *)peer socket:(GCDAsyncSocket *)socket {
    if(block) {
        [_callbacksLock lock];
        [_responseCallbacks setObject:[[TMFResponseCallback alloc] initWithIdentifier:identifier peer:peer socket:socket block:block] forKey:@(identifier)];
        [_callbacksLock unlock];
    }
}

- (void)disableDelay:(BOOL)disable socket:(GCDAsyncSocket *)socket {
    // set Nagle delayed ack algorithm
    // http://www.unixguide.net/network/socketfaq/2.16.shtml
    // http://www.stuartcheshire.org/papers/NagleDelayedAck/
    [socket performBlock:^{
        int socketFD = [socket socketFD];
        int flag = [@(disable) intValue];
        int result = setsockopt(socketFD,        /* socket affected */
                                IPPROTO_TCP,     /* set option at TCP level */
                                TCP_NODELAY,     /* name of option */
                                (char *) &flag,  /* the cast is historical cruft */
                                sizeof(int));    /* length of option value */
        if (result != 0) {
            TMFLogError(@"Could not set TCP_NODELAY.");
        }
    }];
}

- (void)performBlockOnSocketQueue:(dispatch_block_t)block {
    dispatch_sync(_socketQueue, block);
}

@end
