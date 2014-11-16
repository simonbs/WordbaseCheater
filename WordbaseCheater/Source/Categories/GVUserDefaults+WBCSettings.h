//
//  GVUserDefaults+WBCSettings.h
//  
//
//  Created by Simon Støvring on 13/11/14.
//
//

#import <GVUserDefaults/GVUserDefaults.h>
#import "WBCLanguages.h"

typedef NS_ENUM(NSInteger, WBCTileOwner) {
	WBCTileOwnerUnknown = -1,
	WBCTileOwnerOrange = 0,
	WBCTileOwnerBlue
};

@interface GVUserDefaults (WBCSettings)

@property (nonatomic) NSNumber *language;
@property (nonatomic) WBCTileOwner owner;

- (WBCLanguage)primitiveLanguage;

@end
