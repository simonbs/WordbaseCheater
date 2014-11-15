//
//  WBCAppDelegate.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 13/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCAppDelegate.h"

@interface WBCAppDelegate ()
@end

@implementation WBCAppDelegate

#pragma mark -
#pragma mark Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window.tintColor = [UIColor darkGrayColor];
	
	return YES;
}

@end
