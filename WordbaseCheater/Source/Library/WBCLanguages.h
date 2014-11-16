//
//  WBCLanguages.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 16/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>

/* THE ORDER OF THIS CANNOT BE CHANGED */
typedef NS_ENUM(NSInteger, WBCLanguage) {
	WBCLanguageEnglish = 0,
	WBCLanguageDanish,
	WBCLanguageFinnish
};

@interface WBCLanguages : NSObject

+ (NSString *)nameForLanguage:(WBCLanguage)language;
+ (NSString *)displayNameForLanguage:(WBCLanguage)language;
+ (NSString *)traineddataForLanguage:(WBCLanguage)language;
+ (NSString *)whitelistForLanguage:(WBCLanguage)language;
+ (UIImage *)flagForLanguage:(WBCLanguage)language;

@end
