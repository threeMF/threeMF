//
//  MACViewController.m
//  MultiAirCam
//
//  Created by Martin Gratzer on 09.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import "MACViewController.h"

static BOOL __ipad;

@interface MACViewController () <UIAlertViewDelegate>{
    TMFConnector *_tmf;
    alertViewCompletionBlock_t _alertViewCompletionBlock;
}
@end

@implementation MACViewController
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __ipad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    });
}

- (id)init {
    self = [super init];
    if (self) {
        [self threeMFinit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self threeMFinit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self threeMFinit];
    }
    return self;
}

+ (id)controller  {
    return [[self class] new];
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (BOOL)iPad {
    return [MACViewController iPad];
}

+ (BOOL)iPad {
    return __ipad;
}

- (void)displayErrorMessage:(NSString *)errorMessage completion:(alertViewCompletionBlock_t)completion {
    _alertViewCompletionBlock = [completion copy];
    [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(_alertViewCompletionBlock) {
        _alertViewCompletionBlock(buttonIndex);
    }
    _alertViewCompletionBlock = NULL;
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    if(_alertViewCompletionBlock) {
        _alertViewCompletionBlock(0);
    }
    _alertViewCompletionBlock = NULL;
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)threeMFinit {
    if(!_tmf) {
        _tmf = [[TMFConnector alloc] initWithCallBackQueue:dispatch_get_main_queue()];
        _tmf.delegate = self;
    }
}

@end
