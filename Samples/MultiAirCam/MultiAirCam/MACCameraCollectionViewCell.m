//
//  MACCameraCollectionViewCell.m
//  MultiAirCam
//
//  Created by Martin Gratzer on 09.12.12.
//  Copyright (c) 2012 Martin Gratzer. All rights reserved.
//

#import "MACCameraCollectionViewCell.h"
#import <QuartzCore/QuartzCore.h>    
#import "threeMF.h"

#define TITLE_LABEL_HEIGTH 32.0f
#define BTN_WH 44.0f
#define BTN_MARGIN 4.0f

@interface MACCameraCollectionViewCell() {
    UILabel *_titleLabel;
    UIImageView *_imageView;
    UIButton *_shutterButton;
    UIButton *_flashButton;
    UIButton *_flipButton;
    UIActivityIndicatorView *_activityIndicator;    
}
@end

@implementation MACCameraCollectionViewCell
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.clipsToBounds = YES;
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.layer.cornerRadius = 10.0f;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowRadius = 3.0f;
        self.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
        self.layer.shadowOpacity = 0.5f;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.layer.shouldRasterize = YES;
        [self setupImageView];        
        [self setupTitleLabel];
        [self setupButtons];
        [self setupActivityIndicator];
        [self disable];
    }
    return self;
}
//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)reload {
    _titleLabel.text = _camera ? _camera.name : @"";
    _imageView.image = nil;
}

- (void)disable {
    [self setUIDiabled:YES];    
    [_activityIndicator startAnimating];
}

- (void)enable {
    [self setUIDiabled:NO];
    [_activityIndicator stopAnimating];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)setCamera:(TMFPeer *)camera {
    if(_camera != camera) {
        _camera = camera;
    }
    [self reload];
}

- (UIImageView *)imageView {
    return _imageView;
}

- (void)prepareForReuse {
    _titleLabel.text = @"";
}

//............................................................................
#pragma mark -
#pragma mark Delegates
//............................................................................

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)setUIDiabled:(BOOL)disable {
    _shutterButton.enabled = !disable;
    _flashButton.enabled = !disable;
    _flipButton.enabled = !disable;
}

- (void)takePicture:(UIButton *)sender {
    if(sender == _shutterButton) {
        [self.delegate takePictureWithCell:self];
    }
}

- (void)toggleFlash:(UIButton *)sender {
    if(sender == _flashButton) {
        [self.delegate toggleFlashWithCell:self];
    }
}

- (void)flipCamera:(UIButton *)sender {
    if(sender == _flipButton) {
        [self.delegate flipCameraWithCell:self];
    }
}

- (void)setupTitleLabel {
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, height - TITLE_LABEL_HEIGTH, width - 8.0f, TITLE_LABEL_HEIGTH)];
    _titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.opaque = NO;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;

    [self.contentView addSubview:_titleLabel];

    UIView *labelBackground = [[UIView alloc] initWithFrame:CGRectMake(0.0f, height - TITLE_LABEL_HEIGTH, width, TITLE_LABEL_HEIGTH)];
    labelBackground.backgroundColor = [UIColor blackColor];
    labelBackground.alpha = 0.6f;
    [self.contentView insertSubview:labelBackground belowSubview:_titleLabel];
}

- (void)setupImageView {
    _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.opaque = YES;
    [self.contentView addSubview:_imageView];
}

- (void)setupButtons {
    _shutterButton = [self addCameraUIButtonWithImage:@"PLCameraButtonIcon" action:@selector(takePicture:)];
    _shutterButton.bounds = CGRectMake(0.0f, 0.0f, BTN_WH, BTN_WH);
    _shutterButton.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMinY(_titleLabel.frame) - CGRectGetHeight(_shutterButton.bounds) * 0.5f - BTN_MARGIN);

    _flipButton = [self addCameraUIButtonWithImage:@"PLCameraToggleIcon" action:@selector(flipCamera:)];
    _flipButton.frame = CGRectMake(BTN_MARGIN, BTN_MARGIN, BTN_WH, BTN_WH);

    _flashButton = [self addCameraUIButtonWithImage:@"PLCameraFlashIcon_2only_" action:@selector(toggleFlash:)];
    _flashButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - (BTN_WH + BTN_MARGIN), BTN_MARGIN, BTN_WH, BTN_WH);
}

- (void)setupActivityIndicator {
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    [self addSubview:_activityIndicator];
}

- (UIButton *)addCameraUIButtonWithImage:(NSString *)image action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 10.0f;
    button.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.1f];
    [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:button];
    return button;
}

@end
