//
//  TMFImageCommand.h
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
#import "TMFPublishSubscribeCommand.h"
#import "TMFArguments.h"
/**
 Enum defining the provided image format.
 */
typedef enum {
    TMFImageFormatJpg   = 100,
    TMFImageFormatPng   = 101
} TMFImageFormat;


/**
 A command delivering a single image's data.
 The corresponding arguments class is TMFImageCommandArguments.
 
 - unique name: tmf_image
 - reliable 
 
 

 @warning Sending data via UDP can exceed the package size.
 @bug I had some problems sending big images from iOS. This issue is TMFTcpChannel related.
 */
@interface TMFImageCommand : TMFPublishSubscribeCommand
@end

// ------------------------------------------------------------------------------------------------------------------------------------------------- //

/**
 The arguments class for TMFImageCommand used to deliver a single image's data.
 */
@interface TMFImageCommandArguments : TMFArguments

/**
 Data representation of an image.
 */
@property (nonatomic, strong) NSData *data;

/**
 The corresponding image format.
 */
@property (nonatomic) TMFImageFormat format;

@end