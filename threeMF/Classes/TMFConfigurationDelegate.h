//
//  TMFConfigurationDelegate.h
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
 An instance of TMFConnector uses methods in this protocol to define its
 configuration. Changing any of these settings requires sub-classing the
 TMFConnector class and overriding needed methods.
 */
@protocol TMFConfigurationDelegate <NSObject>
@required
/**
 Default bonjour service domain
 @return The name of the used service domain,
 */
- (NSString *)serviceDomain;

/**
 Default bonjour service name
 @return The name of the used service type.
 */
- (NSString *)serviceType;

/**
 Protocol type used for threeMF.
 Override this method if a custom protocol should be used for internal communication channels.
 @see TMFProtocol
 @return The class used as TMFProtocol implementation.
 */
- (Class)protocolClass;

/**
 Protocol type used for threeMF.
 Override this method if a custom coder should be used for internal communication channels.
 @see TMFProtocolCoder
 @return The class used as TMFProtocolCoder implementation.
 */
- (Class)coderClass;

/**
 Channel type which should be used for internal reliable channels.
 Override this method if a custom reliable channel should be used for internal communication channels.
 @see TMFChannel, TMFDispatcher
 @return The class used as reliable TMFChannel implementation.
 */
- (Class)reliableChannelClass;

/**
 Channel type which should be used for internal unreliable channels.
 Override this method if a custom unreliable channel should be used for internal communication channels.
 @return The class used as unreliable TMFChannel implementation.
 @see TMFChannel, TMFDispatcher
 */
- (Class)unreliableChannelClass;

/**
 Channel type which should be used for internal multi-cast channels.
 Override this method if a custom multi-cast channel should be used for internal communication channels.
 @return The class used as multi-cast TMFChannel implementation.
 @see TMFChannel, TMFDispatcher
 */
- (Class)multicastChannelClass;

/**
 @return The global port used for UDP multi-casting.
 */
- (NSUInteger)multicastPort;

/**
 @return The global address used for UDP multi-casting.
 */
- (NSString *)multicastGroup;

@end
