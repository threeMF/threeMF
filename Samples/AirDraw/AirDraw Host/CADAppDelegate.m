//
//  CADAppDelegate.m
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

#import "CADAppDelegate.h"
#import "CADDrawingController.h"

@interface CADAppDelegate() {
    CADDrawingController *_drawingController;
    NSMenu *_statusBarMenu;
    NSStatusItem *_statusBarItem;    
}
@end

@implementation CADAppDelegate

//............................................................................
#pragma mark -
#pragma mark Memory Management
//............................................................................
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//............................................................................
#pragma mark -
#pragma mark Public
//............................................................................


//............................................................................
#pragma mark -
#pragma mark Override
//............................................................................
- (void)awakeFromNib {
    _statusBarMenu = [[NSMenu alloc] initWithTitle:@"AirDraw"];
    [_statusBarMenu addItemWithTitle:NSLocalizedString(@"Connected Devices", @"Status bar menu item") action:nil keyEquivalent:@""];

    _statusBarItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusBarItem setMenu:_statusBarMenu];
    [_statusBarItem setTitle:@"AirDraw"];
    [_statusBarItem setHighlightMode:YES];
}

//............................................................................
#pragma mark NSApplicationDelegate
//............................................................................
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _drawingController = [[CADDrawingController alloc] initWithView:_window.drawingView];
    _drawingController.statusMenu = _statusBarMenu;

    [[_window animator] setFrame:[[_window screen] visibleFrame] display:YES];
    [_window setLevel:NSFloatingWindowLevel];
    [_window setIgnoresMouseEvents:YES];    
}

- (void)applicationDidResignActive:(NSNotification *)notification {
    [_window setLevel:NSFloatingWindowLevel];
}

//............................................................................
#pragma mark -
#pragma mark Private
//............................................................................

@end
