//
//  WBCLanguages.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 16/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCLanguages.h"

@implementation WBCLanguages

#pragma mark -
#pragma mark Public Methods

+ (NSString *)nameForLanguage:(WBCLanguage)language {
	switch (language) {
		case WBCLanguageEnglish:
			return @"en";
		case WBCLanguageDanish:
			return @"da";
		case WBCLanguageFinnish:
			return @"fi";
		default:
			break;
	}
	
	return nil;
}

+ (NSString *)traineddataForLanguage:(WBCLanguage)language {
	switch (language) {
		case WBCLanguageEnglish:
			return @"enwordbase";
		case WBCLanguageDanish:
			return @"dawordbase";
		case WBCLanguageFinnish:
			return @"fiwordbase";
		default:
			break;
	}
	
	return nil;
}

+ (NSString *)whitelistForLanguage:(WBCLanguage)language {
	switch (language) {
		case WBCLanguageEnglish:
			return @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		case WBCLanguageDanish:
			return @"ABCDEFGHIJKLMNOPQRSTUVWXYZÆØÅ";
		case WBCLanguageFinnish:
			return @"ABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ";
		default:
			break;
	}
	
	return nil;
}

@end
