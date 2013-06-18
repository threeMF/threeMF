//
//  UIImage+Scaling.m
//  MultiAirCam
//
//  Created by Martin Gratzer on 21.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import "UIImage+Scaling.h"

@implementation UIImage (Scaling)
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (UIImage *)scaleToSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (CGSize)proportionalImageSizeWithTargetSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(self.size, targetSize) == NO && (self.size.width > targetSize.width || self.size.height > targetSize.height)) {
        CGFloat widthFactor = targetSize.width / self.size.width;
        CGFloat heightFactor = targetSize.height / self.size.height;
        CGFloat scaleFactor = (widthFactor < heightFactor) ? widthFactor : heightFactor;
        CGFloat scaledWidth  = self.size.width * scaleFactor;
        CGFloat scaledHeight = self.size.height * scaleFactor;
        return CGSizeMake(scaledWidth, scaledHeight);
    }
    return self.size;
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
@end
