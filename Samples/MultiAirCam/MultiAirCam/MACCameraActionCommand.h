//
//  MACCameraActionCommand.h
//  MultiAirCam
//
//  Created by Martin Gratzer on 21.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import "TMFRequestResponseCommand.h"

typedef enum MACCameraAction {
    MACCameraActionNone = 0,
    MACCameraActionToggleFlash,
    MACCameraActionToggleCamera,
    MACCameraActionTakePicture
} MACCameraAction;

@interface MACCameraActionCommand : TMFRequestResponseCommand

@end

@interface MACCameraActionCommandArguments : TMFArguments
@property (nonatomic) MACCameraAction action;
- (id)initWithAction:(MACCameraAction)action;
@end