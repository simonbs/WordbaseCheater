//
//  GVUserDefaults+WBCSettings.m
//  
//
//  Created by Simon Støvring on 13/11/14.
//
//

#import "GVUserDefaults+WBCSettings.h"

@implementation GVUserDefaults (WBCSettings)

@dynamic language, owner;

#pragma mark -
#pragma mark Lifecycle

- (NSDictionary *)setupDefaults {
	return @{ @"language" : @(WBCLanguageEnglish),
			  @"owner" : @(WBCTileOwnerOrange) };
}

#pragma mark -
#pragma mark Public Methods

- (WBCLanguage)primitiveLanguage {
	return [self.language integerValue];
}

@end
