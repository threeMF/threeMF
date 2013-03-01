//
//  TMFCommandDispatcher.m
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

#import "TMFCommandDispatcher.h"
#import "TMFTcpChannel.h"
#import "TMFUdpChannel.h"
#import "TMFPeer.h"

#import "TMFProtocol.h"

#import "TMFError.h"
#import "TMFLog.h"
#import "TMFDefine.h"

#import "TMFPublishSubscribeCommand.h"
#import "TMFRequestResponseCommand.h"
#import "TMFHeartBeatCommand.h"

static dispatch_queue_t __bonjourQueue;

@interface TMFCommandDispatcher() <TMFChannelDelegate> {
    dispatch_queue_t _callBackQueue;
    NSMutableDictionary *_publishedCommands;

    TMFChannel *_systemChannel;    // main TCP channel for system commands (also published via bonjour)
    TMFProtocol *_protocol;

    NSMutableDictionary *_channels;
    NSLock *_channelLock;

    NSMutableArray *_subscriptions;
}
@end

@implementation TMFCommandDispatcher
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
+ (void)initialize {
    __bonjourQueue = dispatch_queue_create("tmf.server.bonjour", DISPATCH_QUEUE_SERIAL);
}

- (id)init {
    return [self initWithCallBackQueue:nil delegate:nil]; // will cause parameter assertion to fail
}

- (id)initWithCallBackQueue:(dispatch_queue_t)callBackQueue delegate:(NSObject<TMFConfigurationDelegate, TMFCommandDispatcherDelegate> *)delegate {
    NSParameterAssert(callBackQueue!=nil);
    NSParameterAssert(delegate!=nil);
    
    self = [super init];
    if(self) {
#if ARC_HANDLES_QUEUES
        dispatch_retain(callBackQueue);
#endif
        _callBackQueue = callBackQueue;
        _delegate = delegate; // weak ref!

        _publishedCommands = [NSMutableDictionary new];     

        _channels = [NSMutableDictionary new];
        _channelLock = [NSLock new];

        _subscriptions = [NSMutableArray new];
        
        _protocol = [[[self.delegate protocolClass] alloc] initWithCoder:[[self.delegate coderClass] new]];
        _systemChannel = [[[self.delegate reliableChannelClass] alloc] initWithProtocol:_protocol delegate:self];
        [_channels setObject:_systemChannel forKey:NSStringFromClass([_systemChannel class])];
    }
    return self;
}

- (void)dealloc {
    [self stopAllCommands];
    [self stopChannels];
#if ARC_HANDLES_QUEUES
    dispatch_release(_callBackQueue);
#endif
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)startChannels {
    for(TMFChannel *channel in [_channels allValues]) {
        if(channel != self.systemChannel) {
            [self startChannel:channel completion:NULL];
        }
    }

    if(![self.systemChannel isRunning]) {
        [self startChannel:self.systemChannel completion:NULL];
    }
}

- (void)stopChannels {
    for(TMFChannel *channel in [_channels allValues]) {
        [self stopChannel:channel completion:NULL];
    }
    
    [self stopChannel:self.systemChannel completion:NULL];
}

- (TMFPublishSubscribeCommand *)publishedCommandForName:(NSString *)commandName {
    return [_publishedCommands objectForKey:commandName];
}

- (void)registerPublishCommand:(TMFCommand *)command {
    NSParameterAssert(command!=nil);
    command.delegate = self;
    [self channelForCommand:[command class]];
    NSString *name = command.name;
    if(![_publishedCommands objectForKey:name]) {
        [_publishedCommands setObject:command forKey:name];
    }
    else {
        TMFLogError(@"Command '%@' already published. Ignored!", name);
    }
}

- (void)removePublishedCommand:(TMFCommand *)command {
    if(command) {
        [_publishedCommands removeObjectForKey:command.name];
    }
    
    // TODO: stop all channels without active commands?
    // stop multicast channel if neccessary
//    NSArray *multicastCommands = [[_publishedCommands allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TMFCommand *cmd, __unused NSDictionary *bindings){
//        return [command isKindOfClass:[TMFPublishSubscribeCommand class]] && [[command class] isMulticast];
//    }]];
//
//    if([multicastCommands count] == 0) {
//        [_multicastChannel stop:nil];
//        _multicastChannel = nil;
//    }
}

- (NSArray *)publishedCommandNames {
    NSMutableArray *cmdNames = [[NSMutableArray alloc] init];
    for(TMFCommand *cmd in [_publishedCommands allValues]) {
        [cmdNames addObject:cmd.name];
    }
    return [NSArray arrayWithArray:cmdNames];
}

- (void)subscribe:(Class)commandClass peer:(TMFPeer *)peer receive:(pubSubArgumentsReceivedBlock_t)receive {
    NSParameterAssert(commandClass!=nil);
    NSParameterAssert([commandClass isSubclassOfClass:[TMFCommand class]]);
    NSParameterAssert(peer!=nil);

    TMFSubscription *subscription = [self findSubscriptionForCommand:[commandClass name] atPeer:peer];
    if(!subscription) {
        subscription = [[TMFSubscription alloc] initWithPeer:peer command:commandClass receive:receive];
        [self willChangeValueForKey:@"subscriptions"];
        [_subscriptions addObject:subscription];
        [self didChangeValueForKey:@"subscriptions"];
    }
}

- (void)unsubscribe:(NSString *)commandName peer:(TMFPeer *)peer {
    NSParameterAssert(commandName!=nil);
    NSParameterAssert(peer!=nil);
    TMFSubscription *subscription = [self findSubscriptionForCommand:commandName atPeer:peer];
    [self unsubscribe:subscription];
}

- (void)unsubscribeAtPeer:(TMFPeer *)peer {
    NSParameterAssert(peer!=nil);
    for (NSString *commandName in [self subscribedCommandNamesAtPeer:peer]) {
        [self unsubscribe:commandName peer:peer];
    }
}

- (void)removePeer:(TMFPeer *)peer {
    NSParameterAssert(peer!=nil);    
    [_publishedCommands enumerateKeysAndObjectsUsingBlock:^(__unused id key, TMFCommand *cmd, __unused BOOL *stop) {
        if([cmd isKindOfClass:[TMFPublishSubscribeCommand class]]) {
            [((TMFPublishSubscribeCommand *)cmd) removeSubscriber:peer];
        }
    }];

    for(TMFChannel *channel in [_channels allValues]) {
        [channel removePeer:peer];
    }

    NSArray *subscriptions = [self findSubscriptionsAtPeer:peer];
    [self willChangeValueForKey:@"subscriptions"];
    [_subscriptions removeObjectsInArray:subscriptions];
    [self didChangeValueForKey:@"subscriptions"];
}

- (void)checkSubscriptionsForPeer:(TMFPeer *)peer {
    NSParameterAssert(peer!=nil);
    for(TMFSubscription *subscription in [self findSubscriptionsAtPeer:peer]) {
        if(![peer.capabilities containsObject:[subscription.commandClass name]]) {
            [self unsubscribe:subscription];
        }
    }
}

- (NSArray *)subscribedCommandNamesAtPeer:(TMFPeer *)peer {
    NSParameterAssert(peer!=nil);
    NSMutableArray *commands = [NSMutableArray new];
    for(TMFSubscription *subscription in [self findSubscriptionsAtPeer:peer]) {
        [commands addObject:[subscription.commandClass name]];
    }
    return [NSArray arrayWithArray:commands];
}

- (NSArray *)commandsSubscribedByPeer:(TMFPeer *)peer {
    NSParameterAssert(peer!=nil);
    return [[_publishedCommands allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TMFCommand *command, __unused NSDictionary *bindings) {
        if([command isKindOfClass:[TMFPublishSubscribeCommand class]]) {
            return [((TMFPublishSubscribeCommand *)command).subscribers containsObject:peer];
        }
        return NO;
    }]];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (NSArray *)publishedCommands {
    return [[_publishedCommands allValues] copy];
}

- (NSArray *)subscriptions {
    return [NSArray arrayWithArray:_subscriptions];
}

- (TMFChannel *)systemChannel {
    return _systemChannel;
}

//............................................................................
#pragma mark TMFCommandDelegate
//............................................................................
- (dispatch_queue_t)callBackQueueForCommand:(__unused TMFCommand *)command {
    return _callBackQueue;
}

- (TMFChannel *)channelForCommand:(Class)commandClass {
    NSParameterAssert([commandClass isSubclassOfClass:[TMFCommand class]]);
    NSParameterAssert([commandClass channelClass] != Nil);
    NSParameterAssert([[commandClass channelClass] isSubclassOfClass:[TMFChannel class]]);

    [_channelLock lock];    
    TMFChannel *channel = [_channels objectForKey:NSStringFromClass([commandClass channelClass])];
    if(!channel) {
        if ([commandClass isSubclassOfClass:[TMFPublishSubscribeCommand class]] && [commandClass isMulticast]) {
            channel = [[[commandClass channelClass] alloc] initWithPort:[self.delegate multicastPort] protocol:_protocol delegate:self multicastGroup:[self.delegate multicastGroup]];
        }
        else {
            channel = [[[commandClass channelClass] alloc] initWithProtocol:_protocol delegate:self];
        }
        
        [_channels setObject:channel forKey:NSStringFromClass([commandClass channelClass])];
    }
    [_channelLock unlock];

    if(![channel isRunning]) {
        [self startChannel:channel completion:NULL];
        TMFLogVerbose(@"channel %@ (running=%@) for %@", channel, @([channel isRunning]), NSStringFromClass(commandClass));
    }

    return channel;
}

//............................................................................
#pragma mark TMFChannelDelegate
//............................................................................
- (void)receiveOnChannel:(TMFChannel *)channel commandName:(NSString *)commandName arguments:(NSArray *)arguments address:(NSData *)address response:(responseBlock_t)responseBlock {

    void(^receiveBlock)(TMFCommand *, NSArray *, TMFPeer *) = ^(TMFCommand *command, NSArray *argumentsList, TMFPeer *sourcePeer) {
        BOOL hasArguments = (argumentsList != nil && [argumentsList count] > 0);
        if(command && [command isKindOfClass:[TMFRequestResponseCommand class]]) {
            TMFArguments *argumentsObject = hasArguments ? [[[[command class] argumentsClass] alloc] initWithArgumentList:argumentsList] : nil;
            [((TMFRequestResponseCommand *) command) receivedWithArguments:argumentsObject source:sourcePeer response:responseBlock];
        }
        else {
            TMFSubscription *subscription = [self findSubscriptionForCommand:commandName atPeer:sourcePeer];
            if(subscription) {
                TMFArguments *argumentsObject = [[[subscription.commandClass argumentsClass] alloc] initWithArgumentList:argumentsList];
                dispatch_async(self.callbackQueue, ^{
                    subscription.receiveBlock(argumentsObject, sourcePeer);
                });
            }
        }
    };

    TMFCommand *command = [self publishedCommandForName:commandName];
    TMFPeer *sourcePeer = [self.delegate peerByAddress:address];

    if(sourcePeer || [command isKindOfClass:[TMFHeartBeatCommand class]]) {
        receiveBlock(command, arguments, sourcePeer);
    }
    else if([command isKindOfClass:[TMFRequestResponseCommand class]] || ([command isKindOfClass:[TMFPublishSubscribeCommand class]] && [[command class] isReliable])) { // we did not see this
        if(responseBlock) {
            responseBlock(nil, [TMFError errorForCode:TMFPeerNotFoundErrorCode message:[NSString stringWithFormat:@"'%@' not visible. Try again.", [TMFPeer stringFromAddressData:address]]]);
        }
    }
}

- (dispatch_queue_t)callbackQueue {
    return _callBackQueue;
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)unsubscribe:(TMFSubscription *)subscription {
    if([_subscriptions containsObject:subscription]) {
        [self willChangeValueForKey:@"subscriptions"];
        [_subscriptions removeObject:subscription];
        [self didChangeValueForKey:@"subscriptions"];
    }
}

- (void)stopAllCommands {
    for(TMFPublishSubscribeCommand *command in [self publishedCommandsOfType:[TMFRequestResponseCommand class]]) {
        if([command isRunning]) {
            [command stop:nil];
        }
    }
}

- (NSArray *)publishedCommandsOfType:(Class)type {
    return [[_publishedCommands allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(TMFCommand *command, __unused NSDictionary *bindings){
        return [command isKindOfClass:type];
    }]];
}

- (NSArray *)findSubscriptionsAtPeer:(TMFPeer *)peer {
    return [_subscriptions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TMFSubscription *subscription, __unused NSDictionary *bindings) {
        return [subscription.peer isEqual:peer];
    }]];
}

- (TMFSubscription *)findSubscriptionForCommand:(NSString *)commandName atPeer:(TMFPeer *)peer {
    NSArray *subscriptions = [_subscriptions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TMFSubscription *subscription, __unused NSDictionary *bindings) {
        return [subscription.peer isEqual:peer] && [[subscription.commandClass name] isEqual:commandName];
    }]];
    
    return [subscriptions lastObject];
}

- (void)startChannel:(TMFChannel *)channel completion:(dispatch_block_t)completion {
    if(channel) {
        [channel start:^(NSError * error){
            if(!error) {
                [self.delegate dispatcher:self startedChannel:channel];
            }
            else {
                [self.delegate dispatcher:self failedStartingChannel:channel error:error];
                TMFLogError(@"Could not start %@ %@", NSStringFromClass([channel class]), error);
            }

            if(completion) {
                completion();
            }
        }];
    }
    else {
        if(completion) {
            completion();
        }
    }
}

- (void)stopChannel:(TMFChannel *)channel completion:(dispatch_block_t)completion {
    if(channel && [channel isRunning]) {
        [channel stop:^{
            [self.delegate dispatcher:self stoppedChannel:channel];
            if(completion) {
                completion();
            }
        }];
    }
    else {
        if(completion) {
            completion();
        }
    }
}

@end
