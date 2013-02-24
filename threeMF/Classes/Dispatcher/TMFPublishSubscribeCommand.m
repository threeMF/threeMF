//
//  TMFPublishSubscribeCommand.m
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

#import "TMFPublishSubscribeCommand.h"
#import "TMFCommandDispatcher.h"
#import "TMFPeer.h"

#import "TMFTcpChannel.h"
#import "TMFUdpChannel.h"

#import "TMFLog.h"

@interface TMFPublishSubscribeCommand() {
    NSMutableArray *_subscribers;
}
@end

@implementation TMFPublishSubscribeCommand
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)init {
    self = [super init];
    if(self) {
        _subscribers = [NSMutableArray new];
        _configuration = [[self class] defaultConfiguration];
    }
    return self;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
+ (Class)channelClass {
    if(![self isReliable]) {
        return [TMFUdpChannel class];
    }
    else {
        return [super channelClass];
    }
}

+ (TMFConfiguration *)defaultConfiguration {
    return nil;
}

+ (BOOL)isMulticast {
    return NO;
}

+ (BOOL)isReliable {
    return NO;
}

+ (BOOL)isRealTime {
    return NO;
}

- (void)sendWithArguments:(TMFArguments *)arguments {
    NSParameterAssert([[self class] argumentsClass] != Nil); // needs to be overriden or exist according to the naming convetion.
    NSParameterAssert(arguments != nil);
    if([[self class] isMulticast]) {
        [super sendWithArguments:arguments destination:nil response:NULL];
    }
    else {
        for(TMFPeer *subscriber in [_subscribers copy]) {
            [super sendWithArguments:arguments destination:subscriber response:NULL];
        }
    }
}

- (void)sendWithArguments:(TMFArguments *)arguments destination:(__unused TMFPeer *)peer response:(responseBlock_t)responseBlock {
    [self sendWithArguments:arguments];
    if(responseBlock) {
        // just in case the caller rely on the response block getting called
        responseBlock(nil,nil);
    }
}

- (void)addSubscriber:(TMFPeer *)peer {
    if(![_subscribers containsObject:peer]) {
        [self willChangeValueForKey:@"subscribers"];
        [_subscribers addObject:peer];
        [self didChangeValueForKey:@"subscribers"];

        if(![self isRunning]) {
            [self start:^(NSError *error){
                if(error) {
                    TMFLogError(@"%@", error);
                }
            }];
        }
    }
}

- (void)removeSubscriber:(TMFPeer *)peer {
    if([_subscribers containsObject:peer]) {
        [self willChangeValueForKey:@"subscribers"];
        [_subscribers removeObject:peer];
        [self didChangeValueForKey:@"subscribers"];    

        if([_subscribers count] == 0) {
            [self stop:NULL];
        }
    }
}

- (void)start:(startCompletionBlock_t)completionBlock {
    if (completionBlock) {
        completionBlock(nil);
    }
}

- (void)stop:(stopCompletionBlock_t)completionBlock {
    if(completionBlock) {
        completionBlock(nil);
    }
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)setConfiguration:(TMFConfiguration *)configuration {
    if(![_configuration isEqual:configuration]) {
        _configuration = configuration;
        if([self shouldRestartOnConfigurationUpdate] && _running) {
            [self restart:^(NSError *error){
                if(error) {
                    TMFLogError(@"Error while restarting after configurration update. %@", error);
                }
            }];
        }
    }
}

- (NSArray *)subscribers {
    return [NSArray arrayWithArray:_subscribers];
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)restart:(startCompletionBlock_t)completionBlock {
    [self stop:^{
        [self start:completionBlock];
    }];
}

@end
