//
//  TMFProtocolCoder.h
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

#import "TMFResponse.h"
#import "TMFRequest.h"

/**
 This protocol defines the contract for any encoder / decoder used within threeMF.
 Each coder must conform to this protocol and each peer communicating
 has to use the same encoding / decoding strategy in order to understand each other.
*/
@protocol TMFProtocolCoder <NSObject>

@required
/**
 Name of the coding strategy.
 The name gets published as part of a 3MF bonjour service in order to determine compatibility.
 */
- (NSString *)name;

/**
 Version of the coding strategy.
 The version gets published as part of a 3MF bonjour service in order to determine compatibility.
 */
- (NSString *)version;

/**
 Encodes requests to an appropriate data package
 @param request request to encode, must not be nil
 @return data representation of the given request
 */
- (NSData *)encodeRequest:(TMFRequest *)request;

/**
 Encodes responses to an appropriate data package
 @param response response to encode, must not be nil
 @return data representation of the given response
 */
- (NSData *)encodeResponse:(TMFResponse *)response;

/**
 Decodes requests from an appropriate data package
 @param data data representation of a TMFRequest, must not be nil
 @return the request instance of the given data package, should return nil if the data package did not match
 */
- (TMFRequest *)decodeRequest:(NSData *)data;

/**
 Decodes responses from an appropriate data package
 @param data data representation of a TMFResponse, must not be nil
 @return the response instance of the given data package, should return nil if the data package did not match
 */
- (TMFResponse *)decodeResponse:(NSData *)data;

@end
