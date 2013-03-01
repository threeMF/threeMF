//
//  TMFConnector.m
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

#import "TMFConnector.h"
#import "TMFCommandDispatcher.h"
#import "TMFDiscovery.h"

#import "TMFTcpChannel.h"
#import "TMFUdpChannel.h"
#import "TMFJsonRpcCoder.h"

#import "TMFViewCommand.h"
#import "TMFSubscribeCommand.h"
#import "TMFUnsubscribeCommand.h"
#import "TMFCapabilityCommand.h"
#import "TMFAnnounceCommand.h"
#import "TMFDisconnectCommand.h"
#import "TMFHeartBeatCommand.h"

#import "TMFError.h"
#import "TMFLog.h"
#import "TMFDefine.h"

@interface TMFConnector()<TMFDiscoveryDelegate, TMFCommandDispatcherDelegate> {
    dispatch_queue_t _callBackQueue;    

    TMFCommandDispatcher *_dispatcher;
    TMFSubscribeCommand *_subscribeCommand;
    TMFCapabilityCommand *_capabilityCommand;
    TMFUnsubscribeCommand *_unsubscribeCommand;
    TMFDisconnectCommand *_disconnectCommand;
    TMFHeartBeatCommand *_heartBeatCommant;

    TMFDiscovery *_discovery;

    NSMutableDictionary *_discoveries;
    NSLock *_discoveryLock;

    dispatch_semaphore_t _shutdownSemaphore;
#if TARGET_OS_IPHONE
    __block UIBackgroundTaskIdentifier _task;
#endif
}
@end

@implementation TMFConnector
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    return [self initWithCallBackQueue:dispatch_get_main_queue()];
}

- (id)initWithCallBackQueue:(dispatch_queue_t)callBackQueue {
    self = [super init];
    if(self) {
        // use main queue as default
        callBackQueue = (callBackQueue == NULL) ? dispatch_get_main_queue() : callBackQueue;
#if ARC_HANDLES_QUEUES
        dispatch_retain(callBackQueue);
#endif
        _callBackQueue = callBackQueue;

        _discoveries = [NSMutableDictionary new];
        _discoveryLock = [NSLock new];

        _discovery = [TMFDiscovery new];
        _discovery.configuration = self;
        _discovery.delegate = self;
        
        _dispatcher = [[TMFCommandDispatcher alloc] initWithCallBackQueue:callBackQueue delegate:self];
        [_dispatcher addObserver:self forKeyPath:@"subscriptions" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:(__bridge void *)self];
        [self registerSystemCommands];
        
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:[UIApplication sharedApplication]];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:[UIApplication sharedApplication]];
#else
        [_dispatcher startChannels];
#endif
    }
    return self;
}

- (void)dealloc {
    [_dispatcher removeObserver:self forKeyPath:@"subscriptions" context:(__bridge void *)self];
    for(TMFCommand *command in [_dispatcher publishedCommands]) {
        [self stopObservinvCommand:command];
    }
    [_discovery stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#if ARC_HANDLES_QUEUES
    dispatch_release(_callBackQueue);
#endif
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................

//............................................................................
#pragma mark publishing and unpublising command services
//............................................................................
- (void)publishCommand:(TMFCommand *)command {
    // FIXME: setting the view's reverse reference should not be so indirect
    if([command conformsToProtocol:@protocol(TMFViewCommand)]) {
        TMFCommand <TMFViewCommand> *viewCommand = (TMFCommand <TMFViewCommand> *)command;
        viewCommand.view.command = viewCommand;
    }
    
    [self observeCommand:command];
    [_dispatcher registerPublishCommand:command];
    
    if(![command isSystemCommand]) {
        [_discovery addCapability:command.name];
    }
}

- (void)publishCommands:(NSArray *)commands {
    for(TMFCommand *command in commands) {
        [self publishCommand:command];
    }
}

- (void)unpublishCommand:(TMFCommand *)command {
    [_dispatcher removePublishedCommand:command];
    if(![command isSystemCommand]) {
        [_discovery removeCapability:command.name];
    }
    
    [self stopObservinvCommand:command];
}


//............................................................................
#pragma mark discovery with specific capabilities
//............................................................................
- (void)startDiscoveryWithCapabilities:(NSArray *)listOfCommands delegate:(NSObject<TMFConnectorDelegate> *)delegate {
    NSParameterAssert(delegate!=nil);
    NSParameterAssert(listOfCommands!=nil);
    NSParameterAssert([listOfCommands count]!=0);

    [_discoveryLock lock];
    
    NSSet *capabilities = [NSSet setWithArray:listOfCommands];
    NSMutableArray *delegates = [_discoveries objectForKey:capabilities];
    if(!delegates) {
        delegates = [NSMutableArray arrayWithObject:delegate];
        [_discoveries setObject:delegates forKey:capabilities];
    }
    else {
        [delegates addObject:delegate];
    }

    if([delegate respondsToSelector:@selector(connector:didChangeDiscoveringPeer:forChangeType:)]) {
        // send already available peers
        for(TMFPeer *peer in _discovery.peers) {
            NSSet *peerCapabilities = [NSSet setWithArray:peer.capabilities];
            if([capabilities isSubsetOfSet:peerCapabilities]) {
                [delegate connector:self didChangeDiscoveringPeer:peer forChangeType:TMFPeerChangeFound];
            }
        }
    }

    [_discoveryLock unlock];
}

- (void)stopDiscoveryWithCapabilities:(NSArray *)listOfCommands delegate:(NSObject<TMFConnectorDelegate> *)delegate {
    NSParameterAssert(delegate!=nil);
    NSParameterAssert(listOfCommands!=nil);
    NSParameterAssert([listOfCommands count]!=0);

    [_discoveryLock lock];

    NSSet *capabilities = [NSSet setWithArray:listOfCommands];
    NSMutableArray *delegates = [_discoveries objectForKey:capabilities];
    if(delegates) {
        [delegates removeObject:delegate];
        if([delegates count] == 0) {
            [_discoveries removeObjectForKey:capabilities];
        }
    }
    
    [_discoveryLock unlock];
}


//............................................................................
#pragma mark subscription cleanup
//............................................................................
- (void)subscribe:(Class)commandClass peer:(TMFPeer *)peer receive:(pubSubArgumentsReceivedBlock_t)receive completion:(tmfCompletionBlock_t)completion {
    [self subscribe:commandClass configuration:nil peer:peer receive:receive completion:completion];
}

- (void)subscribe:(Class)commandClass configuration:(TMFConfiguration *)configuation peer:(TMFPeer *)peer receive:(pubSubArgumentsReceivedBlock_t)receive completion:(tmfCompletionBlock_t)completion {
    NSParameterAssert(commandClass!=nil);
    NSParameterAssert([commandClass isSubclassOfClass:[TMFCommand class]]);
    NSParameterAssert(peer!=nil);
    NSParameterAssert(receive!=nil);

    TMFChannel *channel = [_dispatcher channelForCommand:commandClass];
    TMFSubscribeCommandArguments *args = [TMFSubscribeCommandArguments new];
    args.commandName = [commandClass name];
    args.configuration = configuation;
    args.port = channel.port;

    [_subscribeCommand sendWithArguments:args
                             destination:peer
                                response:^(NSDictionary *response, NSError *error) {
                                    if(!error) {
                                        [_dispatcher subscribe:commandClass peer:peer receive:receive];
                                    }

                                    if(completion) {
                                        completion(error);
                                    }
                                }];
}

- (void)unsubscribe:(Class)commandClass fromPeer:(TMFPeer *)peer completion:(tmfCompletionBlock_t)completion {
    NSParameterAssert(commandClass != Nil);
    NSParameterAssert([commandClass isSubclassOfClass:[TMFPublishSubscribeCommand class]]);
    NSParameterAssert(peer != nil);    
    if(commandClass) {
        // 1. send an unsubscribe message to trigger a removal from the commands subscriber list
        TMFUnsubscribeCommandArguments *args = [TMFUnsubscribeCommandArguments new];
        args.commands = @[[commandClass name]];
        [_unsubscribeCommand sendWithArguments:args
                                   destination:peer
                                      response:^(id response, NSError *error) {
                                          if(!error) {
                                              // 2. remove the local subscription record
                                              [_dispatcher unsubscribe:[commandClass name] peer:peer];
                                          }

                                          if(completion) {
                                              completion(error);
                                          }
                                      }];
    }
}

- (void)unsubscribeFromPeer:(TMFPeer *)peer completion:(tmfCompletionBlock_t)completion {
    NSParameterAssert(peer != nil);
    TMFUnsubscribeCommandArguments *args = [TMFUnsubscribeCommandArguments new];
    args.commands = [_dispatcher subscribedCommandNamesAtPeer:peer];
    // 1. send an unsubscribe message to trigger a removal from the commands subscriber list
    [_unsubscribeCommand sendWithArguments:args
                               destination:peer
                                  response:^(id response, NSError *error) {
                                      if(!error) {
                                           // 2. remove all local subscription record                                          
                                          [_dispatcher unsubscribeAtPeer:peer];
                                      }

                                      if(completion) {
                                          completion(error);
                                      }
                                  }];
}

- (void)disconnect:(Class)commandClass fromPeer:(TMFPeer *)peer completion:(tmfCompletionBlock_t)completion {
    NSParameterAssert(commandClass != Nil);
    NSParameterAssert([commandClass isSubclassOfClass:[TMFPublishSubscribeCommand class]]);
    NSParameterAssert(peer != nil);
    [self disconnect:peer commands:@[[_dispatcher publishedCommandForName:[commandClass name]]] completion:completion];
}

- (void)disconnect:(TMFPeer *)peer completion:(tmfCompletionBlock_t)completion {
    NSParameterAssert(peer != nil);
    [self disconnect:peer commands:[_dispatcher commandsSubscribedByPeer:peer] completion:completion];
}


//............................................................................
#pragma mark sending request response commands
//............................................................................
- (void)sendCommand:(Class)commandClass arguments:(TMFArguments *)arguments destination:(TMFPeer *)peer response:(responseBlock_t)response {
    NSParameterAssert(commandClass!=nil);
    NSParameterAssert([commandClass isSubclassOfClass:[TMFCommand class]]);    
    NSParameterAssert(peer!=nil);
    NSParameterAssert(response!=nil);

    TMFRequestResponseCommand *command = [commandClass new];
    command.delegate = _dispatcher;
    NSParameterAssert(command!=nil);
    NSParameterAssert([command isKindOfClass:[TMFRequestResponseCommand class]]);
    [command sendWithArguments:arguments destination:peer response:response];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    BOOL subscribers = [keyPath isEqualToString:@"subscribers"];
    BOOL subscriptions = [keyPath isEqualToString:@"subscriptions"];

    if(((__bridge void *)self) == context && (subscribers || subscriptions)) {
        NSSet *old = [NSSet setWithArray:[change objectForKey:@"old"]];
        NSSet *new = [NSSet setWithArray:[change objectForKey:@"new"]];

        NSMutableSet *added = [new mutableCopy];
        [added minusSet:old];

        NSMutableSet *removed = [old mutableCopy];
        [removed minusSet:new];

        dispatch_async(_callBackQueue, ^{        
            if([object isKindOfClass:[TMFPublishSubscribeCommand class]] && subscribers) {
                for(TMFPeer *peer in [added allObjects]) {
                    if([self.delegate respondsToSelector:@selector(connector:didAddSubscriber:toCommand:)]) {
                        [self.delegate connector:self didAddSubscriber:peer toCommand:object];
                    }
                    TMFLogInfo(@"Did add subscriber %@ to command %@.", peer.name, [object name]);
                }

                for(TMFPeer *peer in [removed allObjects]) {
                    if([self.delegate respondsToSelector:@selector(connector:didRemoveSubscriber:fromCommand:)]) {
                        [self.delegate connector:self didRemoveSubscriber:peer fromCommand:object];
                    }
                    TMFLogInfo(@"Did remove subscriber %@ from command %@.", peer.name, [object name]);                    
                }
            }
            else if(_dispatcher == object && subscriptions) {   
                for(TMFSubscription *subscription in [added allObjects]) {
                    if([self.delegate respondsToSelector:@selector(connector:didAddSubscription:forCommand:)]) {
                        [self.delegate connector:self didAddSubscription:subscription.peer forCommand:subscription.commandClass];
                    }
                    TMFLogInfo(@"Did add subscription for command %@ at %@.", [subscription.commandClass name], [subscription.peer name]);
                }

                for(TMFSubscription *subscription in [removed allObjects]) {
                    if([self.delegate respondsToSelector:@selector(connector:didRemoveSubscription:forCommand:)]) {
                        [self.delegate connector:self didRemoveSubscription:subscription.peer forCommand:subscription.commandClass];
                    }
                    TMFLogInfo(@"Did remove subscription for command %@ at %@.", [subscription.commandClass name], [subscription.peer name]);
                }
            }
        });
    }
}

- (void)setDelegate:(NSObject<TMFConnectorDelegate> *)delegate {
    if(_delegate != delegate) {
        // send already available peers
        if([delegate respondsToSelector:@selector(connector:didChangePeer:forChangeType:)]) {
            [_discoveryLock lock];
            for(TMFPeer *peer in _discovery.peers) {
                [delegate connector:self didChangePeer:peer forChangeType:TMFPeerChangeFound];
            }
            [_discoveryLock unlock];
        }
        _delegate = delegate;        
    }
}

- (NSArray *)publishedCommandNames {
    return [_dispatcher publishedCommandNames];
}

- (TMFPeer *)localPeer {
    return _discovery.localPeer;
}

- (NSArray *)peers {
    return _discovery.peers;
}

#pragma mark TMFCommandDispatcherDelegate
- (TMFPeer *)peerByAddress:(NSData *)address {
    return [_discovery peerByAddress:address];
}

- (void)dispatcher:(TMFCommandDispatcher *)dispatcher startedChannel:(TMFChannel *)channel {
    if (dispatcher == _dispatcher && channel == dispatcher.systemChannel) {
        if(dispatcher.systemChannel.port != 0) {
            [_discovery startOnPort:dispatcher.systemChannel.port];
        }
        else {
            TMFLogError(@"System channel started with port 0.");
            [dispatcher stopChannels];
            dispatch_async(_callBackQueue, ^{
                if([self.delegate respondsToSelector:@selector(connector:didFailWithError:)]) {
                    [self.delegate connector:self didFailWithError:[TMFError errorForCode:TMFChannelErrorCode message:@"Could not start communication channels."]];
                }
            });
        }
    }
}

- (void)dispatcher:(TMFCommandDispatcher *)dispatcher stoppedChannel:(TMFChannel *)channel {
    if (dispatcher == _dispatcher && channel == dispatcher.systemChannel) {

        if(_shutdownSemaphore != NULL) {
            dispatch_semaphore_signal(_shutdownSemaphore);
#if TARGET_OS_IPHONE
            if(_task) {
                [[UIApplication sharedApplication] endBackgroundTask: _task];
                _task = UIBackgroundTaskInvalid;
            }
#endif
        }
        else {
            [_discovery stop]; // stop if running
            dispatch_async(_callBackQueue, ^{
                if([self.delegate respondsToSelector:@selector(connector:didFailWithError:)]) {
                    [self.delegate connector:self didFailWithError:[TMFError errorForCode:TMFChannelErrorCode message:@"Could not start communication channels."]];
                }
            });
        }
    }
}

- (void)dispatcher:(TMFCommandDispatcher *)dispatcher failedStartingChannel:(__unused TMFChannel *)channel error:(NSError *)error {
    if(dispatcher == _dispatcher) {
        dispatch_async(_callBackQueue, ^{
            if([self.delegate respondsToSelector:@selector(connector:didFailWithError:)]) {
                [self.delegate connector:self didFailWithError:error];
            }
        });
    }
}

#pragma mark TMFDiscoveryDelegate
- (NSString *)protocolIdentifier {
    return _dispatcher.systemChannel.protocol.identifier;
}

- (void)discovery:(TMFDiscovery *)discovery didAddPeer:(TMFPeer *)peer {
    if(discovery == _discovery) {
        [self sendDiscoveryCallbackForPeer:peer type:TMFPeerChangeFound];
    }
}

- (void)discovery:(TMFDiscovery *)discovery willRemovePeer:(TMFPeer *)peer {
    if(discovery == _discovery) {
        [self sendDiscoveryCallbackForPeer:peer type:TMFPeerChangeRemove];
        [_dispatcher removePeer:peer];        
    }
}

- (void)discovery:(TMFDiscovery *)discovery didUpdatePeer:(TMFPeer *)peer {
    if(discovery == _discovery) {
        [self sendDiscoveryCallbackForPeer:peer type:TMFPeerChangeUpdate];
        if([peer didChangeCapabilitiesOnLastUpdate]) {
            [_dispatcher checkSubscriptionsForPeer:peer];
        }
    }
}

- (void)discovery:(__unused TMFDiscovery *)discovery didNotSearchWithError:(NSDictionary *)errorDict {
    TMFLogError(@"%@", errorDict);
}

- (void)discoveryDidStart:(TMFDiscovery *)discovery {
    if(discovery == _discovery) {
        
    }
}

- (void)discoveryDidStop:(TMFDiscovery *)discovery {
    if(discovery == _discovery) {
        [_dispatcher stopChannels];
    }
}

#pragma mark TMFConfiguration
- (NSString *)serviceDomain {
    return @"local";
}

- (NSString *)serviceType {
    return @"_threeMF._tcp.";
}

- (Class)protocolClass {
    return [TMFProtocol class];
}

- (Class)coderClass {
    return [TMFJsonRpcCoder class];
}

- (Class)reliableChannelClass {
    return [TMFTcpChannel class];
}

- (Class)unreliableChannelClass {
    return [TMFUdpChannel class];
}

- (Class)multicastChannelClass {
    return [TMFUdpChannel class];
}

- (NSUInteger)multicastPort {
    return 42424;
}

- (NSString *)multicastGroup {
    return @"239.255.42.42";
}

#pragma mark App background state notificaiton handler
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [_dispatcher startChannels];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
#if TARGET_OS_IPHONE
    _task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^ {
        [[UIApplication sharedApplication] endBackgroundTask: _task];
        _task = UIBackgroundTaskInvalid;
        TMFLogError(@"Stopping services expired.");
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
#endif
        _shutdownSemaphore = dispatch_semaphore_create(0);
        [_discovery stop];
        dispatch_semaphore_wait(_shutdownSemaphore, DISPATCH_TIME_FOREVER);
#if ARC_HANDLES_QUEUES
        dispatch_release(_shutdownSemaphore);
#endif
        _shutdownSemaphore = NULL;
        TMFLogInfo(@"All services stopped");

#if TARGET_OS_IPHONE
    });
#endif
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)sendDiscoveryCallbackForPeer:(TMFPeer *)peer type:(TMFPeerChangeType)type {

    NSSet *currentCapabilities = [NSSet setWithArray:peer.capabilities ? peer.capabilities : @[]];
    NSSet *previousCapabilities = [NSSet setWithArray:peer.previousCapabilities ? peer.previousCapabilities : @[]];
    NSDictionary *callbacks = @{ @(TMFPeerChangeFound) : [NSMutableArray new],
                                 @(TMFPeerChangeRemove) : [NSMutableArray new],
                                 @(TMFPeerChangeUpdate) : [NSMutableArray new] };
    BOOL update = NO;
    
    for(NSSet *capabilities in [_discoveries allKeys]) {
        NSArray *delegates = [_discoveries objectForKey:capabilities];
        TMFPeerChangeType resultingType = type;
        
        // case 1: adding a new peer with matching capabilities -> insert
        // case 2: removing a peer with matching capabilties or matching previous capabilities -> remove
        if(TMFPeerChangeFound == type || TMFPeerChangeRemove == type) {
            // resultingType stays
            update = [capabilities isSubsetOfSet:currentCapabilities] || (TMFPeerChangeRemove == type && [capabilities isSubsetOfSet:previousCapabilities]);
        }
        else if(type == TMFPeerChangeUpdate) { // change
            // case 4: changing a peer which gets matching capabilities -> update (which implies insert if not already inserted)
            // case 5: changing a peer which keeps matching capabilities -> update
            if([capabilities isSubsetOfSet:currentCapabilities]) {
                resultingType = TMFPeerChangeUpdate;
                update = YES;
            }
            // case 3: changing a peer which had matching capabilities -> remove            
            else if([peer didChangeCapabilitiesOnLastUpdate] && [capabilities isSubsetOfSet:previousCapabilities]) {
                resultingType = TMFPeerChangeRemove;
                update = YES;
            }
        }

        if (update) {
            [[callbacks objectForKey:@(resultingType)] addObjectsFromArray:delegates];
        }

        update = NO; // reset flag
    }

    dispatch_async(_callBackQueue, ^{
        BOOL delegateNotified = NO;
        for(NSNumber *key in [callbacks allKeys]) {
            for(NSObject<TMFConnectorDelegate> *delegate in [callbacks objectForKey:key]) {
                if([delegate respondsToSelector:@selector(connector:didChangeDiscoveringPeer:forChangeType:)]) {
                    [delegate connector:self didChangeDiscoveringPeer:peer forChangeType:(TMFPeerChangeType)[key integerValue]];
                    if(!delegateNotified) {
                        delegateNotified = (delegate == self.delegate);
                    }
                }
            }
        }

        if(!delegateNotified && [self.delegate respondsToSelector:@selector(connector:didChangePeer:forChangeType:)]) {
            [self.delegate connector:self didChangePeer:peer forChangeType:type];
        }
    });
}

- (NSArray *)delegatesForCapabilities:(NSArray *)capabilities {
    NSSet *capabilitiesSet = [NSSet setWithArray:capabilities];
    return [[_discoveries objectForKey:capabilitiesSet] copy];
}

- (void)registerSystemCommands {
    __unsafe_unretained TMFConnector *weakSelf = self;
    // -------------------------------
    // Subscribe Command
    // -------------------------------
    _subscribeCommand = [[TMFSubscribeCommand alloc] initWithRequestReceivedBlock:^(TMFSubscribeCommandArguments *arguments, TMFPeer *source, responseBlock_t responseBlock) {
                                                     TMFLogVerbose(@"Received subscription request for %@ from %@.", arguments.commandName, source);
                                                     if(responseBlock) {
                                                         NSError *error = nil;
                                                         TMFPublishSubscribeCommand *command = [_dispatcher publishedCommandForName:arguments.commandName];

                                                         if(command) {
                                                             if(arguments.configuration) {
                                                                 TMFConfiguration *conf = arguments.configuration;
                                                                 conf.sender = source;
                                                                 command.configuration = arguments.configuration;
                                                             }
                                                             
                                                             [source setPort:arguments.port commandName:command.name];
                                                             [command addSubscriber:source];                                                            
                                                         }
                                                         else {
                                                             error = [TMFError errorForCode:TMFInternalErrorCode message:[NSString stringWithFormat:@"Command '%@' not found.", arguments.commandName]];
                                                         }

                                                         responseBlock(@(error == nil), error);
                                                     }
                                                 }];

    // -------------------------------
    // Unsubscribe Command
    // -------------------------------
    _unsubscribeCommand = [[TMFUnsubscribeCommand alloc] initWithRequestReceivedBlock:^(TMFUnsubscribeCommandArguments *arguments, TMFPeer *peer, responseBlock_t responseBlock) {
        TMFPublishSubscribeCommand *command;
        for (NSString *commandName in arguments.commands) {
            command = [_dispatcher publishedCommandForName:commandName];
            [command removeSubscriber:peer];
        }

        if(responseBlock) {
            responseBlock(@1, nil);
        }    
    }];

    // -------------------------------
    // Disconnect Command
    // -------------------------------
    _disconnectCommand = [[TMFDisconnectCommand alloc] initWithRequestReceivedBlock:^(TMFDisconnectCommandArguments *arguments, TMFPeer *peer, responseBlock_t responseBlock) {
        for (NSString *commandName in arguments.commands) {
            [weakSelf->_dispatcher unsubscribe:commandName peer:peer];
        }

        if(responseBlock) {
            responseBlock(@1, nil);
        }
    }];

    // -------------------------------
    // Capability Command
    // -------------------------------    
    _capabilityCommand = [[TMFCapabilityCommand alloc] initWithRequestReceivedBlock:^(__unused TMFArguments *arguments, __unused TMFPeer *peer, responseBlock_t responseBlock) {
        if(responseBlock) {
           responseBlock(self.publishedCommandNames, nil);
        }
    }];

    [self publishCommands:@[ _subscribeCommand, _unsubscribeCommand, _disconnectCommand, _capabilityCommand, _discovery.heartBeatCommand ]];
}

- (void)disconnect:(TMFPeer *)peer commands:(NSArray *)commands completion:(tmfCompletionBlock_t)completion {
    for(TMFPublishSubscribeCommand *command in commands) {
        [command removeSubscriber:peer];
    }

    // send a disconnect command -> the peer will remove all local subscriptions for each command
    TMFDisconnectCommandArguments *args = [TMFDisconnectCommandArguments new];
    args.commands = [commands valueForKeyPath:@"name"];
    [_disconnectCommand sendWithArguments:args
                              destination:peer
                                 response:^(id response, NSError *error) {
                                     if(completion) {
                                         completion(error);
                                     }
                                 }];
}

- (void)observeCommand:(TMFCommand *)command {
    if([command isKindOfClass:[TMFPublishSubscribeCommand class]]) {
        [((TMFPublishSubscribeCommand *)command) addObserver:self forKeyPath:@"subscribers" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:(__bridge void *)self];
    }
}

- (void)stopObservinvCommand:(TMFCommand *)command {
    if([command isKindOfClass:[TMFPublishSubscribeCommand class]]) {
        [((TMFPublishSubscribeCommand *)command) removeObserver:self forKeyPath:@"subscribers" context:(__bridge void *)self];
    }
}

@end
