//
//  GVUserDefaults+WBCSettings.h
//  
//
//  Created by Simon Støvring on 13/11/14.
//
//

#import <GVUserDefaults/GVUserDefaults.h>

static NSString* const WBCLanguageEnglish = @"en";
static NSString* const WBCLanguageDanish = @"da";

typedef NS_ENUM(NSInteger, WBCTileOwner) {
	WBCTileOwnerUnknown = -1,
	WBCTileOwnerOrange = 0,
	WBCTileOwnerBlue
};

@interface GVUserDefaults (WBCSettings)

@property (nonatomic) NSString *language;
@property (nonatomic) WBCTileOwner owner;

@end
