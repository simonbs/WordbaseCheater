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
		case WBCLanguageGerman:
			return @"de";
		default:
			break;
	}
	
	return nil;
}

+ (NSString *)displayNameForLanguage:(WBCLanguage)language {
	switch (language) {
		case WBCLanguageEnglish:
			return @"English";
		case WBCLanguageDanish:
			return @"Danish";
		case WBCLanguageFinnish:
			return @"Finnish";
		case WBCLanguageGerman:
			return @"German";
		default:
			break;
	}
	
	return nil;
}

+ (NSString *)traineddataForLanguage:(WBCLanguage)language {
	switch (language) {
		case WBCLanguageEnglish:
			return @"eng";
		case WBCLanguageDanish:
			return @"dan";
		case WBCLanguageFinnish:
			return @"fin";
		case WBCLanguageGerman:
			return @"deu";
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
		case WBCLanguageGerman:
			return @"ABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ";

		default:
			break;
	}
	
	return nil;
}

+ (UIImage *)flagForLanguage:(WBCLanguage)language {
	NSString *imageName = nil;
	switch (language) {
		case WBCLanguageEnglish:
			imageName = @"united-kingdom";
			break;
		case WBCLanguageDanish:
			imageName = @"denmark";
			break;
		case WBCLanguageFinnish:
			imageName = @"finland";
			break;
		case WBCLanguageGerman:
			imageName = @"germany";
			break;
		default:
			break;
	}
	
	if (imageName) {
		return [UIImage imageNamed:imageName];
	}
	
	return nil;
}

@end
