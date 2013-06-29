//
//  MACViewController.h
//  MultiAirCam
//
//  Created by Martin Gratzer on 09.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "threeMF.h"
#import "MACPreviewCommand.h"
#import "MACCameraActionCommand.h"

typedef void (^alertViewCompletionBlock_t)(NSUInteger buttonIndex);

@interface MACViewController : UIViewController <TMFConnectorDelegate>
@property (nonatomic, readonly) TMFConnector *tmf;
+ (id)controller;
- (BOOL)iPad;
+ (BOOL)iPad;
- (void)displayErrorMessage:(NSString *)errorMessage completion:(alertViewCompletionBlock_t)completion;
@end
