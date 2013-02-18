//
// TMFServiceBrowserTableViewController.m
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

#if TARGET_OS_IPHONE
#import "TMFServiceBrowserTableViewController.h"
#import "TMFConnector.h"
#import "TMFLog.h"

@interface TMFServiceBrowserTableViewController() {
    NSMutableArray *_peers;
}
@end

@implementation TMFServiceBrowserTableViewController
//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    NSParameterAssert([[[self class] tableViewCellClass] isSubclassOfClass:[UITableViewCell class]]);
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        _peers = [NSMutableArray new];
    }
    return self;
}

+ (id)controllerWithDelgate:(NSObject<TMFServiceBrowserTableViewControllerDelegate> *)delegate {
    TMFServiceBrowserTableViewController *controller = [[[self class] alloc] initWithNibName:nil bundle:nil];
    controller.delegate = delegate;
    return controller;
}

+ (Class)tableViewCellClass {
    return [UITableViewCell class];
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    TMFPeer *peer = [_peers objectAtIndex:indexPath.row];
    cell.textLabel.text = peer.name;
    cell.detailTextLabel.text = [peer.capabilities count]==0 ? @"-" : [peer.capabilities componentsJoinedByString:@","];
}

//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................

#pragma mark view lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];
}

//............................................................................
#pragma mark Table view data source
//............................................................................
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_peers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"peerCell"];
    if(!cell) {
        cell = [[[[self class] tableViewCellClass] alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"peerCell"];
    }
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

//............................................................................
#pragma mark Table view delegate
//............................................................................
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TMFPeer *peer = [_peers objectAtIndex:indexPath.row];
    if(_delegate && peer) {
        [_delegate serviceBrowser:self didSelectPeer:peer];
    }
}

- (void)discovery:(TMFDiscovery *)discovery didNotSearchWithError:(NSDictionary *)errorDict {
    TMFLogError(@"%@", errorDict);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Discovery Error", @"Service browser discovery error alert view title.") 
                                                    message:@"" 
                                                   delegate:nil 
                                          cancelButtonTitle:NSLocalizedString(@"Close", @"Service browser discovery error alert view cancel button.")
                                          otherButtonTitles:nil];
    [alert show];
}

//............................................................................
#pragma mark TMFConnectorDelegate
//............................................................................
- (void)connector:(TMFConnector *)tmf didChangeDiscoveringPeer:(TMFPeer *)peer forChangeType:(TMFPeerChangeType)type {
    NSUInteger idx = [_peers indexOfObject:peer];
    if(![_peers containsObject:peer] && type == TMFPeerChangeUpdate) {
        type = TMFPeerChangeFound;
    }

    [self.tableView beginUpdates];
    switch(type) {
        case TMFPeerChangeFound: {
            [_peers addObject:peer];
            NSUInteger idx = [_peers indexOfObject:peer];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;

        case TMFPeerChangeRemove: {
            [_peers removeObject:peer];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;

        case TMFPeerChangeUpdate: {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
    }
    
    [self.tableView endUpdates];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................
- (void)close {
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

@end
#endif
