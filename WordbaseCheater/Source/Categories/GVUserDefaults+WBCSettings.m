//
//  GVUserDefaults+WBCSettings.m
//  
//
//  Created by Simon Støvring on 13/11/14.
//
//

#import "GVUserDefaults+WBCSettings.h"

@implementation GVUserDefaults (WBCSettings)

@dynamic language;

#pragma mark -
#pragma mark Lifecycle

- (NSDictionary *)setupDefaults {
	return @{ @"language" : @"da" };
}

@end
