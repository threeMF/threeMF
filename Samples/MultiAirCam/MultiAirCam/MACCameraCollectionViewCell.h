//
//  MACCameraCollectionViewCell.h
//  MultiAirCam
//
//  Created by Martin Gratzer on 09.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MACCameraCollectionViewCell, TMFPeer;

@protocol MACCameraCollectionViewCellDelegate <NSObject>
- (void)takePictureWithCell:(MACCameraCollectionViewCell *)cell;
- (void)toggleFlashWithCell:(MACCameraCollectionViewCell *)cell;
- (void)flipCameraWithCell:(MACCameraCollectionViewCell *)cell;
@end

@interface MACCameraCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) TMFPeer *camera;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, weak) NSObject<MACCameraCollectionViewCellDelegate> *delegate;
- (void)reload;
- (void)disable;
- (void)enable;
@end
