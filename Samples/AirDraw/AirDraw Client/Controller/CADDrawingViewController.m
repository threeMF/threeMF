//
//  CADDrawingViewController.m
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
#import "TMFKeyValueCommand.h"
#import "CADDrawingViewController.h"
#import "InfColorPickerController.h"
#import "UIBarButtonItem+ImageButton.h"
#import "CADServiceBrowserViewController.h"

#import "CADCommands.h"

@interface CADDrawingViewController () <TMFConnectorDelegate, InfColorPickerControllerDelegate, TMFServiceBrowserTableViewControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
    UIColor *_color;
    CADServiceBrowserViewController *_serviceBrowser;
    TMFConnector *_tmf;

    CADClientMetaInformationCommand *_clientMetaCommand;
    TMFKeyValueCommand *_keyValueCommand;
    CADGyroMouseCommand *_gyroMouseCommand;
    
    UIBarButtonItem *_undoButton;
    UIBarButtonItem *_redoButton;
    UIBarButtonItem *_clearButton;
    UIBarButtonItem *_centerButton;    
}
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *drawButton;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *hostButton;

@property (strong, nonatomic) TMFPeer *host;
@end

@implementation CADDrawingViewController

//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {        
        // set random color
        float random = arc4random() % 12;
        _color = [UIColor colorWithHue:(30.0f * random) / 360.0f saturation:0.5f brightness:0.8f alpha:1.0f];    
        
        _tmf = [TMFConnector new];
        _tmf.delegate = self;

        _clientMetaCommand = [CADClientMetaInformationCommand new];
        _gyroMouseCommand= [CADGyroMouseCommand new];
        _keyValueCommand = [TMFKeyValueCommand new];
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
+ (id)controller {
    return [[self alloc] initWithNibName:NSStringFromClass(self) bundle:nil];
}

- (void)setHost:(TMFPeer *)host {
    if(host != _host) {
        _host = host;
        [self updateUI];
    }
}

//............................................................................
#pragma mark View lifecycle
//............................................................................
- (void)viewDidLoad {
    [super viewDidLoad];

    if([CADGyroMouseCommand isGyroscopeAvailable]) {
        [_tmf publishCommands:@[_clientMetaCommand, _gyroMouseCommand, _keyValueCommand]];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not start", @"Error message title")
                                    message:NSLocalizedString(@"No gyroscope available", @"Error Message")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Ok", @"")
                          otherButtonTitles:nil] show];
        self.hostButton.enabled = NO;
        self.drawButton.enabled = NO;
    }

    self.title = @"AirDraw";    
    self.nameLabel.text = [[UIDevice currentDevice] name];
    self.hostButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self updateTintColor];
    [self setupNavigationBar];    
    [self setupToolBar];
    [self updateUI];
}

- (void)viewDidUnload {
    self.host = nil;    
    [self setNameLabel:nil];
    [self setDrawButton:nil];
    [self setInfoLabel:nil];   
    [self setHostButton:nil];
    [super viewDidUnload];
}

//............................................................................
#pragma mark TMFConnectorDelegate
//............................................................................
- (void)connector:(TMFConnector *)tmf didFailWithError:(NSError *)error {
    if(tmf == _tmf) {
        self.host = nil;
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:error.localizedDescription
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    }
}

- (void)connector:(TMFConnector *)tmf didRemoveSubscriber:(TMFPeer *)peer fromCommand:(TMFPublishSubscribeCommand *)command {
    if(peer == self.host) {
        self.host = nil;
    }
}

//............................................................................
#pragma mark InfColorPickerController
//............................................................................
- (void)colorPickerControllerDidFinish:(InfColorPickerController *)picker {
    _color = picker.resultColor;
    [self updateTintColor];
    [self broadcastMetaInfo];    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

//............................................................................
#pragma mark TMFServiceBrowserTableViewControllerDelegate
//............................................................................
- (void)serviceBrowser:(TMFServiceBrowserTableViewController *)browser didSelectPeer:(TMFPeer *)peer {
    CADAnnounceCommandArguments *args = [CADAnnounceCommandArguments new];
    args.name = self.nameLabel.text;
    args.color = _color;
    
    [_tmf sendCommand:[CADAnnounceCommand class]
            arguments:args
          destination:peer
             response:^(id response, NSError *error){
                 if(error) {
                     NSLog(@"%@", [error localizedDescription]);
                     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                 message:[error localizedDescription]
                                                delegate:nil
                                       cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                       otherButtonTitles:nil] show];
                 }
                 else {
                     [self closeServiceBrowser];
                     self.host = peer;
                     [self broadcastMetaInfo];
                 }
             }];
}

//............................................................................
#pragma mark UIAlertViewDelegate
//............................................................................
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UITextField *nameTextField = [alertView textFieldAtIndex:0];
    if(nameTextField && [nameTextField.text length]>0) {
        _nameLabel.text = nameTextField.text;
        [self broadcastMetaInfo];
    }
}

//............................................................................
#pragma mark UIActionSheedDelegate
//............................................................................
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        [_tmf disconnect:self.host completion:NULL];
    }
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

#pragma mark Button actions
- (IBAction)draw:(id)sender {
    if(!self.host) {
        [self openServiceBrowser];
    }
    else {
        [self broadcastValue:@"end" forKey:@"draw"];
    }
}

- (IBAction)drawBegin:(id)sender {
    if(self.host) {
        [self broadcastValue:@"begin" forKey:@"draw"];
    }
}

- (IBAction)hostButtonPressed:(id)sender {
    if(!self.host) {
        [self openServiceBrowser];
    }
    else {
        [[[UIActionSheet alloc] initWithTitle:self.host.name
                                     delegate:self
                            cancelButtonTitle:NSLocalizedString(@"Cancle", @"Disconnect from host cancle button title")
                       destructiveButtonTitle:NSLocalizedString(@"Disconnect", @"Disconnect from host disconnect button title")
                            otherButtonTitles:nil] showFromToolbar:self.navigationController.toolbar];
    }
}

//............................................................................
#pragma mark 3MF command helper
//............................................................................
- (void)broadcastMetaInfo {
    CADClientMetaInformationCommandArguments *metaArgs = [[CADClientMetaInformationCommandArguments alloc] init];
    metaArgs.name = _nameLabel.text;
    metaArgs.color = _color;
    [_clientMetaCommand sendWithArguments:metaArgs];
}

- (void)broadcastValue:(NSString *)value forKey:(NSString *)key {
    TMFKeyValueCommandArguments *kvArguments = [[TMFKeyValueCommandArguments alloc] init];
    kvArguments.key = key;
    kvArguments.value = value;
    [_keyValueCommand sendWithArguments:kvArguments];
}

- (void)undo {
    // using cmd as key and undo as value would make more sense
    [self broadcastValue:@"undo" forKey:@"do"];
}

- (void)redo {
    // using cmd as key and redo as value would make more sense
    [self broadcastValue:@"redo" forKey:@"do"];
}

- (void)clear {
    // using cmd as key and clear as value would make more sense        
    [self broadcastValue:@"clear" forKey:@"do"];
}

- (void)center {
    [self broadcastValue:@"center" forKey:@"do"];
    [_gyroMouseCommand center];
}

//............................................................................
#pragma mark Helper
//............................................................................
- (void)updateTintColor {
    self.navigationController.navigationBar.tintColor = _color;
    self.navigationController.toolbar.tintColor = _color;
}

- (void)changeColor {
    InfColorPickerController* picker = [InfColorPickerController colorPickerViewController];
    picker.sourceColor = _color;
    picker.delegate = self;
    [picker presentModallyOverViewController:self tintColor:_color];
}

- (void)changeNameTag {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"How should I call you?", @"Title of name collecting alert view")
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Call me this way", @"Name collecting alert view done button")
                                              otherButtonTitles:nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alertView show];
}

- (void)updateUI {
    if(self.host != nil) {
        self.infoLabel.text = NSLocalizedString(@"Tap and hold to draw. \n Release to stop.", @"Infolabel when connected to canvas.");
        self.hostButton.titleLabel.text = self.host.name; //[NSString stringWithFormat:NSLocalizedString(@"Connected to: %@.", @"Host button when connected to canvas."), self.host.name];
    }
    else {
        self.infoLabel.text = NSLocalizedString(@"Tap to search for a cavnas.", @"Infolabel without connected canvas.");
        self.hostButton.titleLabel.text = NSLocalizedString(@"not connected", @"Host button when not connected to canvas.");

    }

    _undoButton.enabled = self.host != nil;
    _redoButton.enabled = self.host != nil;
    _clearButton.enabled = self.host != nil;
    _centerButton.enabled = self.host != nil;
}

- (void)openServiceBrowser {
    _serviceBrowser = [CADServiceBrowserViewController controllerWithDelgate:self];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:_serviceBrowser];
    navi.navigationBar.tintColor = _color;
    [self presentViewController:navi animated:YES completion:NULL];
    [_tmf startDiscoveryWithCapabilities:@[ [CADAnnounceCommand name] ] delegate:_serviceBrowser];
}

- (void)closeServiceBrowser {
    [self dismissViewControllerAnimated:YES completion:^{
        [_tmf stopDiscoveryWithCapabilities:@[ [CADAnnounceCommand name] ] delegate:_serviceBrowser];
        _serviceBrowser = nil;
    }];
}

- (void)setupNavigationBar {
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"98-palette.png"]  target:self action:@selector(changeColor)];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"14-tag.png"]  target:self action:@selector(changeNameTag)];
}

- (void)setupToolBar {
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];    
    fixedSpace.width = 30.0f;
    
    _undoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(undo)];
    _redoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRedo target:self action:@selector(redo)];
    _clearButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(clear)];    
    _centerButton = [UIBarButtonItem barItemWithImage:[UIImage imageNamed:@"13-target.png"]  target:self action:@selector(center)];
    _centerButton.tintColor = [UIColor whiteColor];
    
    self.toolbarItems = [NSArray arrayWithObjects:flexSpace, _undoButton, fixedSpace, _clearButton, fixedSpace, _centerButton, fixedSpace, _redoButton, flexSpace, nil];
}

@end
