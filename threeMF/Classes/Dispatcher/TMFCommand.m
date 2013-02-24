//
//  TMFCommand.m
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

#import "TMFCommand.h"
#import "TMFCommandDispatcher.h"
#import "TMFPeer.h"

#import "TMFTcpChannel.h"

#define PREFIX @"TMF"
#define SUFFIX @"Command"

@interface TMFCommand()
@property (nonatomic, strong, readonly) TMFChannel *channel;
@end

@implementation TMFCommand
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)sendWithArguments:(TMFArguments *)arguments destination:(TMFPeer *)peer response:(responseBlock_t)responseBlock {
    NSAssert(self.delegate != nil, @"Dispatcher needed");
    NSAssert(self.channel != nil, @"Channel needed");
   [self.channel send:self arguments:arguments destination:peer responseBlock:responseBlock];
}

+ (NSString *)name {
    return NSStringFromClass([self class]);
}

+ (Class)argumentsClass {
    NSString *argumentsClassName = [NSString stringWithFormat:@"%@Arguments", NSStringFromClass(self)];
    Class argumentsClass = NSClassFromString(argumentsClassName);
    NSAssert(argumentsClass != Nil, @"Missing Arguments class");
    return argumentsClass;
}

+ (Class)channelClass {
    return [TMFTcpChannel class];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (BOOL)isSystemCommand {
    return NO;
}

- (NSUInteger)port {
    return self.channel.port;
}

- (TMFChannel *)channel {
    return [self.delegate channelForCommand:[self class]];
}

- (NSString *)name {
    return [[self class] name];
}

- (BOOL)isEqual:(id)object {
    if(object == self) {
        return YES;
    }

    if(object !=nil && [object isKindOfClass:[self class]]) {
        return [((TMFCommand *)object).name isEqualToString:self.name];
    }

    return NO;
}

- (NSUInteger)hash {
    return [self.name hash];
}


//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

@end
