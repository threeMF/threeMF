//
//  TMFError.h
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

static const NSInteger TMFInternalErrorCode = 0;
static const NSInteger TMFChannelErrorCode = 100;
static const NSInteger TMFMessageParsingErrorCode = 200;
static const NSInteger TMFPeerNotFoundErrorCode = 300;
static const NSInteger TMFSubscribeErrorCode = 400;
static const NSInteger TMFResponseErrorCode = 500;
static const NSInteger TMFCommandErrorCode = 500;

/**
 A little NSError subclass easing the creation of error objects.
 */
@interface TMFError : NSError
/**
 Creates an error object based on an internal error code. The error message
 will contain a default value.
 @param code The error code defined by 3MF
 */
+ (NSError *)errorForCode:(NSUInteger)code;
/**
 Creates an error object based on an internal error code and a customized message.
 @param code The error code defined by 3MF
 @param message The message used for this error code
 */
+ (NSError *)errorForCode:(NSUInteger)code message:(NSString *)message;
/**
 Creates an error object based on an internal error code, a customized message 
 and a custom userInfo dictionary.
 @param code The error code defined by 3MF
 @param message The message used for this error code
 @param userInfo The dictionary holding further user information describing the error.
 */
+ (NSError *)errorForCode:(NSUInteger)code message:(NSString *)message userInfo:(NSDictionary *)userInfo;
@end
