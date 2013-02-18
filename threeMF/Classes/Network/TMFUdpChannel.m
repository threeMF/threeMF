//
//  TMFUdpChannel.m
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

#import "TMFUdpChannel.h"
#import "GCDAsyncUdpSocket.h"
#import "TMFPeer.h"
#import "TMFCommand.h"
#import "TMFError.h"
#import "TMFLog.h"
#import "TMFDefine.h"

#import "TMFPublishSubscribeCommand.h"

@interface TMFUdpChannel() <GCDAsyncUdpSocketDelegate> {
    GCDAsyncUdpSocket *_socket;
    dispatch_queue_t _socketQueue;
    dispatch_queue_t _socketDelegationQueue;
    
    startCompletionBlock_t _startupCompletionBlock;
    stopCompletionBlock_t _shutdownCompletionBlock;

    NSLock *_startupLock;
}
@end

@implementation TMFUdpChannel
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    self = [super init];
    if (self) {
        _startupLock = [NSLock new];
        _socketQueue = dispatch_queue_create("tmf.channel.udp.queue", DISPATCH_QUEUE_SERIAL);
        _socketDelegationQueue = dispatch_queue_create("tmf.channel.udp.working", DISPATCH_QUEUE_SERIAL);
        [self performBlockOnSocketQueue:^{
            _socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:_socketDelegationQueue socketQueue:_socketQueue];
        }];
    }
    return self;
}

- (id)initWithPort:(NSUInteger)port protocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate multicastGroup:(NSString *)multicastGroup {
    self = [super initWithPort:port protocol:protocol delegate:delegate];
    if(self) {
        _multiCastGroup = [multicastGroup copy];
    }
    return self;
}

- (id)initWithProtocol:(TMFProtocol *)protocol delegate:(NSObject<TMFChannelDelegate> *)delegate multicastGroup:(NSString *)multicastGroup {
    return [self initWithPort:0 protocol:protocol delegate:delegate multicastGroup:multicastGroup];
}

- (void)dealloc {
#if ARC_HANDLES_QUEUES
    dispatch_release(_socketQueue);
    dispatch_release(_socketDelegationQueue);
#endif
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (BOOL)enableBroadcast:(BOOL)flag error:(NSError *__autoreleasing *)error {
    __block BOOL result = NO;
    [self performBlockOnSocketQueue:^{
        result = [_socket enableBroadcast:flag error:error];
    }];
    return result;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (NSUInteger)port {
    __block NSUInteger port;
    [self performBlockOnSocketQueue:^{
        port = _socket.localPort;
    }];
    return port;
}

- (void)setMultiCastGroup:(NSString *)multiCastGroup {
    if(![_multiCastGroup isEqualToString:multiCastGroup]) {
        [self performBlockOnSocketQueue:^{
            NSError *error = nil;
            if(_multiCastGroup || [_multiCastGroup length]>0) {
                if(![_socket leaveMulticastGroup:_multiCastGroup error:&error]) {
                    TMFLogError(@"Could not leave multicast group %@. %@", _multiCastGroup, error);
                }
            }

            _multiCastGroup = multiCastGroup;
            [self joinMulticastGroup:_multiCastGroup error:&error];
            if(error) {
                TMFLogError(@"Could not join multicast group %@. %@", _multiCastGroup, error);
                _multiCastGroup = nil;
            }
        }];
    }
}

- (BOOL)joinMulticastGroup:(NSString *)multiCastGroup error:(NSError *__autoreleasing *)error {
    [_socket joinMulticastGroup:multiCastGroup error:error];
    if(!*error) {
        TMFLogInfo(@"Joined multicast group %@", multiCastGroup);
    }
    else {
        TMFLogError(@"Could not joun multicast group %@ - %@", multiCastGroup, *error);
    }
    return (*error == nil);
}

- (void)send:(TMFPublishSubscribeCommand *)command arguments:(TMFArguments *)arguments destination:(TMFPeer *)peer responseBlock:(responseBlock_t)responseBlock {
//    NSParameterAssert(arguments!=nil);
    NSParameterAssert(command!=nil);
    NSParameterAssert([command isKindOfClass:[TMFPublishSubscribeCommand class]]);
    if([[command class] isMulticast]) {
        NSParameterAssert(_multiCastGroup!=nil);
    }

    [self performBlockOnSocketQueue:^{
        NSData *data = [self.protocol requestDataForCommand:command arguments:arguments];
        if([[command class] isMulticast]) {
            TMFLog(@"Multicasting");
            [_socket sendData:data toHost:_multiCastGroup port:self.port withTimeout:-1 tag:0];
        }
        else {
            [_socket sendData:data toHost:peer.hostName port:[peer portForCommandName:command.name] withTimeout:-1 tag:0];
        }

        // no responses
        if(responseBlock) {
            dispatch_async(self.delegate.callbackQueue, ^{
                responseBlock(nil, nil);
            });
        }
    }];
}

- (void)start:(startCompletionBlock_t)completionBlock {
    [self performBlockOnSocketQueue:^{
        [_startupLock lock];
        @autoreleasepool {
            NSError *error = nil;            
            if(![self isRunning]) {
                if([_socket bindToPort:super.port error:&error]) {
                    if([_socket beginReceiving:&error]) {
                        if(_multiCastGroup && [_multiCastGroup length]>0) {
                            [self joinMulticastGroup:_multiCastGroup error:&error];
                        }
                    }
                }

                _running = (error == nil);
                if(![self isRunning]) {
                    TMFLogError(@"Error starting %@ %@", NSStringFromClass([self class]), error);
                    [_socket close];
                }
                else {
                    TMFLogInfo(@"Started %@ on port %@.", NSStringFromClass([self class]), @(_socket.localPort));
                }                
            }

            if(completionBlock) {
                dispatch_async(self.delegate.callbackQueue, ^{ completionBlock(error); });
            }
        }
        [_startupLock unlock];
    }];
}

- (void)stop:(stopCompletionBlock_t)completionBlock {
    [self performBlockOnSocketQueue:^{
        @autoreleasepool {
            _shutdownCompletionBlock = [completionBlock copy];
            [_socket close];
            _running = NO;
        }
    }];
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................
#pragma mark GCDAsyncUdpSocketDelegate
/**
 * Called when the socket has received the requested datagram.
 **/
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    if(data) {
        NSData *datawithoutHeader = [data subdataWithRange:NSMakeRange(self.protocol.publishSubscribeHeaderLength, [data length] - self.protocol.publishSubscribeHeaderLength)];
        TMFRequest *request = [self.protocol requestFromData:datawithoutHeader];
        dispatch_async(self.delegate.callbackQueue, ^{
            [self.delegate receiveOnChannel:self commandName:request.commandName arguments:request.arguments address:address response:nil];
        });
    }
}

/**
 * Called when the socket is closed.
 **/
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    if(error && error.code != GCDAsyncUdpSocketClosedError) {
        TMFLogError(@"UDP Socket disconnected with Error: %@", error);
    }

    if (_shutdownCompletionBlock) {
        dispatch_async(self.delegate.callbackQueue, ^{
            _shutdownCompletionBlock();
        });
    }
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)performBlockOnSocketQueue:(dispatch_block_t)block {
    dispatch_sync(_socketQueue, block);
}

@end
