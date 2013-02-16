//
//  TMFSubscription.m
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

#import "TMFSubscription.h"
#import "TMFPeer.h"

@implementation TMFSubscription
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)initWithPeer:(TMFPeer *)peer command:(Class)commandClass receive:(pubSubArgumentsReceivedBlock_t)receive {
    NSParameterAssert(peer != nil);
    NSParameterAssert(commandClass != Nil);
    NSParameterAssert([commandClass isSubclassOfClass:[TMFPublishSubscribeCommand class]]);
    self = [self init];
    if(self) {
        _peer = peer;
        _commandClass = commandClass;
        _receiveBlock = [receive copy];
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
- (BOOL)isEqual:(id)object {
    if(object != self || ![object isKindOfClass:[TMFSubscription class]]) {
        return NO;
    }

    TMFSubscription *subscription = (TMFSubscription *)object;
    return [subscription.peer isEqual:self.peer] && subscription.commandClass == self.commandClass;
}

- (NSUInteger)hash {
    return _peer.hash * 7 + NSStringFromClass(_commandClass).hash * 13;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Subscription: %@ at %@", [_commandClass name], _peer.name];
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

@end
