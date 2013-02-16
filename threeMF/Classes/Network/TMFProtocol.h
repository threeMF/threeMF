//
//  TMFProtocol.h
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
#import "TMFProtocolCoder.h"

@class TMFCommand, TMFArguments, TMFResponse;

/**
 Callback block for the header parser
 @param length length of the data message
 @param error error description if parsing went wrong, otherwise nil
 */
typedef void(^headerParserCompletion_t)(uint64_t length, NSError *error);

/**
 Protocol responsible for parsing TCP / UDP data to TMFRequest and TMFResponse objects.
 Each peer talking has to use the same protocol and coder in order to talk to each other.
 Provide your own protocol by sub-classing and overwriting each public method.
 */
@interface TMFProtocol : NSObject

/**
 Message En-/Decoder. conforming to the TMFProtocolCoder protocol
 */
@property (nonatomic, readonly) NSObject<TMFProtocolCoder> *coder;

/**
 Name of the protocol.
 */
@property (nonatomic, readonly, copy) NSString *name;

/**
 Version of the protocol.
 */
@property (nonatomic, readonly, copy) NSString *version;

/**
 Identifier of the protocol. Will get published with NSNetService's txtRecords.
 The default value will be a string containing of "name,version"
 */
@property (nonatomic, readonly, copy) NSString *identifier;

/**
 Size of a TMFRequestResponseCommand message header
 */
@property (nonatomic, readonly) NSUInteger requestResponseHeaderLength;

/**
 Size of a TMFPublishSubscribeCommand message header
 */
@property (nonatomic, readonly) NSUInteger publishSubscribeHeaderLength;

/**
 Initializes a new protocol instance with a given coder.
 @param coder Data coder conforming to TMFProtocolCoder
 */
- (id)initWithCoder:(NSObject<TMFProtocolCoder> *)coder;

/**
 Parses the header out of a given data package
 @param data the data containing the encoded header, must be of requestResponseHeaderLength or publishSubscribeHeaderLength length
 @param completion callback block containing the parsing result, may not be nil
 */
- (void)parseHeader:(NSData *)data completion:(headerParserCompletion_t)completion;

/**
 Creates a data package out of a command and corresponding arguments. The data package will get encoded using the protocol's coder.
 @param command the requests command to encode, must not be nil
 @param arguments corresponding arguments for the command, must not be nil
 @return an encoded TMFRequest as data object
 */
- (NSData *)requestDataForCommand:(TMFCommand *)command arguments:(TMFArguments *)arguments;

/**
 Creates a data package out of a request object. The data package will get encoded using the protocol's coder.
 @param request the request object to encode, must not be nil
 @return an encoded TMFRequest as data object
 */
- (NSData *)requestDataForRequest:(TMFRequest *)request;

/**
 Creates a data package out of a response object. The data package will get encoded using the protocol's coder.
 @param response the response object to encode, must not be nil
 @return an encoded TMFResponse as data object
 */
- (NSData *)responseDataForResponse:(TMFResponse *)response;

/**
 Decodes a data package into a TMFRequest object. The data package must not contain any headers and must not be nil.
 @param data data package for decoding
 @return a decoded TMFRequest
 */
- (TMFRequest *)requestFromData:(NSData *)data;

/**
 Decodes a data package into a TMFResponse object. The data package must not contain any headers and must not be nil.
 @param data data package for decoding
 @return a decoded TMFResponse
 */
- (TMFResponse *)responseFromData:(NSData *)data;

/**
 Encodes a request into several data packages with a maximal size.
 @param request the request object to encode, must not be nil
 @param maxSize maximum size for each individual data package
 @return an array containing 1 to n data packages
 */
- (NSArray *)broadcastPackagesForRequest:(TMFRequest *)request maxSize:(NSUInteger)maxSize; // unused

@end
