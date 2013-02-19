//
//  UIImage+Scaling.h
//  MultiAirCam
//
//  Created by Martin Gratzer on 21.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Scaling)
- (UIImage *)scaleToSize:(CGSize)size;
- (CGSize)proportionalImageSizeWithTargetSize:(CGSize)targetSize;
@end
