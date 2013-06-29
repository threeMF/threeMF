//
//  SFScreenViewController.m
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

#import "threeMF.h"
#import "TMFMultiTouchCommand.h"
#import "TMFImageCommand.h"
#import "TMFKeyValueCommand.h"
#import "SFScreenViewController.h"
#import "SFServiceBrowserViewController.h"
#import "SFAnnounceCommand.h"

@interface SFScreenViewController()<TMFConnectorDelegate, TMFServiceBrowserTableViewControllerDelegate, UIScrollViewDelegate> {
    TMFPeer *_host;
    TMFConnector *_tmf;
    TMFMultiTouchView *_touchView;
    TMFMultiTouchCommand *_touchCommand;
    TMFKeyValueCommand *_keyValueCommand;

    UIScrollView *_scrollView;
    SFServiceBrowserViewController *_serviceBrowser;    
    UIImageView *_screenPortion;
    CGRect _recentVisibleRect;
}
@end

@implementation SFScreenViewController

//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {                
        _tmf = [[TMFConnector alloc] initWithCallBackQueue:dispatch_get_current_queue()];
        _tmf.delegate = self;
        _keyValueCommand = [TMFKeyValueCommand new];
        [_tmf publishCommand:_keyValueCommand];
    }
    return self;
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................


//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)loadView {
    [super loadView];
    _touchView = [[TMFMultiTouchView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];   
    _touchView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _screenPortion = [[UIImageView alloc] initWithFrame:_touchView.bounds];
    _screenPortion.autoresizingMask = _touchView.autoresizingMask;
    _screenPortion.contentMode = UIViewContentModeScaleAspectFit;
    [_touchView addSubview:_screenPortion];;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:_touchView.bounds];
    _scrollView.delegate = self;
    _scrollView.contentSize = _scrollView.frame.size;
    _scrollView.minimumZoomScale = 1.0f;
    _scrollView.maximumZoomScale = 4.0f;
    [_scrollView addSubview:_touchView];
    
    self.view = _scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _touchCommand = [TMFMultiTouchCommand new];
    _touchCommand.view = _touchView;
    [_tmf publishCommand:_touchCommand];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    _host = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(!_host) {
        [self openServiceBrowser];
    }
}

- (void)didRotateFromInterfaceOrientation:(__unused UIInterfaceOrientation)fromInterfaceOrientation {
    [self broadcastScreenResolution];
}

//............................................................................
#pragma mark UIScrollViewDelegate
//............................................................................
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if(scrollView == _scrollView) {
        return _touchView;
    }    
    return nil;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if(scrollView == _scrollView) {
        [self broadcastVisibleRect];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollView == _scrollView) {
        [self broadcastVisibleRect];
    }    
}

//............................................................................
#pragma mark TMFConnectorDelegate
//............................................................................
- (void)connector:(TMFConnector *)connector didRemoveSubscriber:(TMFPeer *)peer fromCommand:(TMFPublishSubscribeCommand *)command {
    if(_tmf == connector && self.presentedViewController == nil) {
        _host = nil;
        [[[UIAlertView alloc] initWithTitle:@"Connection closed"
                                    message:[NSString stringWithFormat:@"Conneciton to %@ closed.", peer.name]
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        [self openServiceBrowser];
    }
}

- (void)connector:(TMFConnector *)connector didAddSubscriber:(TMFPeer *)peer toCommand:(TMFPublishSubscribeCommand *)command {
    if([command isKindOfClass:[TMFKeyValueCommand class]]) {
        [self broadcastScreenResolution];
    }
}

//............................................................................
#pragma mark TMFServiceBrowserTableViewControllerDelegate
//............................................................................
- (void)serviceBrowser:(TMFServiceBrowserTableViewController *)browser didSelectPeer:(TMFPeer *)host {
    __weak __typeof(&*self)weakSelf = self;
    [_tmf sendCommand:[SFAnnounceCommand class] arguments:nil destination:host response:^(NSDictionary *result, TMFPeer *peer, NSError *error){
        if(error) {
            NSLog(@"%@", [error localizedDescription]);
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                        message:[error localizedDescription]
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                              otherButtonTitles:nil] show];
        }
        else {
            [weakSelf closeServiceBrowser];            
            [weakSelf subsribe:peer];
        }
    }];
}

- (void)subsribe:(TMFPeer *)peer {
    _host = peer;

    [_tmf subscribe:[TMFImageCommand class] peer:peer receive:^(TMFImageCommandArguments *arguments, TMFPeer *peer) {
        [_screenPortion setImage:[UIImage imageWithData:arguments.data]];
    }
         completion:^(NSError *error){
             if(error) {
                 [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                             message:[error localizedDescription]
                                            delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                   otherButtonTitles:nil] show];
             }
         }];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)broadcastScreenResolution {
    [self broadcastValue:[self resolutionString] forKey:@"resolution"];
}

- (void)broadcastVisibleRect {
    CGFloat scale = 1.0f / _scrollView.zoomScale;        
    CGRect visibleRect = _scrollView.bounds;
    if(scale < 1.0f) {
        visibleRect.origin = _scrollView.contentOffset;
        visibleRect.size = _scrollView.bounds.size;        
        visibleRect.origin.x *= scale;
        visibleRect.origin.y *= scale;
        visibleRect.size.width *= scale;
        visibleRect.size.height *= scale;        
    }
    
    CGFloat xdif = ABS(_recentVisibleRect.origin.x - visibleRect.origin.x);
    CGFloat ydif = ABS(_recentVisibleRect.origin.y - visibleRect.origin.y);
    CGFloat wdif = ABS(_recentVisibleRect.size.width - visibleRect.size.width);
    CGFloat hdif = ABS(_recentVisibleRect.size.height - visibleRect.size.height);
    
    if(xdif > 2 || ydif > 2 || (wdif > 2 && hdif > 2)) {
        CGFloat scale = [UIScreen mainScreen].scale;
        visibleRect = CGRectMake(visibleRect.origin.x * scale, visibleRect.origin.y * scale, visibleRect.size.width * scale, visibleRect.size.height * scale);
        _recentVisibleRect = visibleRect;
        [self broadcastValue:NSStringFromCGRect(visibleRect) forKey:@"visiblerect"];    
    }
}

- (void)broadcastValue:(NSString *)value forKey:(NSString *)key {
    TMFKeyValueCommandArguments *kvArguments = [[TMFKeyValueCommandArguments alloc] init];
    kvArguments.key = key;
    kvArguments.value = value;
    [_keyValueCommand sendWithArguments:kvArguments];
}

- (void)openServiceBrowser {
    _serviceBrowser = [SFServiceBrowserViewController controllerWithDelgate:self];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:_serviceBrowser];
    [self presentModalViewController:navi animated:YES];
    [_tmf startDiscoveryWithCapabilities:@[ [TMFImageCommand name], [SFAnnounceCommand name] ] delegate:_serviceBrowser];
}

- (void)closeServiceBrowser {
    [self dismissViewControllerAnimated:YES completion:^{
        [_tmf stopDiscoveryWithCapabilities:@[ [TMFImageCommand name], [SFAnnounceCommand name] ] delegate:_serviceBrowser];
        _serviceBrowser = nil;
    }];
}

- (CGSize)resolution {
    return CGSizeMake(self.view.bounds.size.width * [UIScreen mainScreen].scale, 
                      self.view.bounds.size.height * [UIScreen mainScreen].scale);    
}

- (NSString *)resolutionString {    
    return NSStringFromCGSize([self resolution]);
}
@end
