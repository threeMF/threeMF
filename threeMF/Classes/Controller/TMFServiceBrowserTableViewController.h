//
// TMFServiceBrowserTableViewController.h
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
// This file is part of 3MF http://threemf.com
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "TMFConnector.h"

@class TMFServiceBrowserTableViewController, TMFPeer;

/**
 An instance of TMFServiceBrowserTableViewController uses methods in this protocol to inform the controller
 about peer selection.
 */
@protocol TMFServiceBrowserTableViewControllerDelegate
/**
 Gets called if a peer is selected
 @param browser The TMFServiceBrowserTableViewController instance calling the method
 @param host The selected TMFPeer
 */
- (void)serviceBrowser:(TMFServiceBrowserTableViewController *)browser didSelectPeer:(TMFPeer *)host;
@end

/**
 This class is a basic UITableViewController to display discovered peers.
 Use this class as example implementation to create your own peer browser
 or subclass it to extend functionality.
 */
@interface TMFServiceBrowserTableViewController : UITableViewController <TMFConnectorDelegate>

/**
 The delegate getting informed about peer selection via [TMFServiceBrowserTableViewControllerDelegate serviceBrowser:didSelectPeer:]
 */
@property (nonatomic, weak) NSObject <TMFServiceBrowserTableViewControllerDelegate> *delegate;

/**
 The list of capabilities each peer must at least fulfill to get displayed in the table view.
 */
@property (nonatomic, copy) NSArray *capabilities;

/**
 Creates as instance of TMFServiceBrowserTableViewController with a given delegate.
 @param delegate The delegate used for the new instance.
 */
+ (id)controllerWithDelgate:(NSObject<TMFServiceBrowserTableViewControllerDelegate> *)delegate;

/**
 UITableViewCell subclass used for table view cells.
 Default is UITableViewCell
 */
+ (Class)tableViewCellClass;

/**
 This method configures the table view cell displayed for a peer.
 Override this method to provide custom cell configurations.
 @param cell The cell to configure.
 @param indexPath The cells index path.
 */
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end
#endif
