//
//  WBCBoardView.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCBoardView.h"
#import "WBCBoard.h"
#import "WBCTile.h"
#import "WBCIndexPath.h"
#import "UIColor+WBCWordbase.h"

@implementation WBCBoardView

#pragma mark -
#pragma mark Lifecycle

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	NSArray *tiles = self.board.tiles;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, rect);
	
	CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
	CGContextFillRect(context, rect);
	
	NSUInteger rowCount = [[tiles valueForKeyPath:@"@max.indexPath.row"] integerValue] + 1;
	NSUInteger columnCount = [[tiles valueForKeyPath:@"@max.indexPath.column"] integerValue] + 1;
	
	CGSize tileSize = CGSizeMake(CGRectGetWidth(rect) / columnCount, CGRectGetHeight(rect) / rowCount);
	
	for (WBCTile *tile in tiles) {
		CGRect tileRect = CGRectZero;
		tileRect.size = tileSize;
		tileRect.origin.x = tile.indexPath.column * tileSize.width;
		tileRect.origin.y = tile.indexPath.row * tileSize.height;
		tileRect = CGRectIntegral(tileRect);
		
		UIColor *fillColor = nil;
		UIColor *textColor = [UIColor blackColor];
		NSString *badgeText = nil;
		
		NSInteger index = [self.selectedPath indexOfObjectPassingTest:^BOOL(WBCTile *theTile, NSUInteger idx, BOOL *stop) {
			WBCIndexPath *indexPath = theTile.indexPath;
			BOOL match = indexPath.row == tile.indexPath.row && indexPath.column == tile.indexPath.column;
			*stop = match;
			return match;
		}];
		
		BOOL isTileSelected = index != NSNotFound;
		
		if (isTileSelected) {
			fillColor = [UIColor colorWithRed:22.0f/255.0f green:208.0f/255.0f blue:7.0f/255.0f alpha:1.0f];
			badgeText = [NSString stringWithFormat:@"%lu", index + 1];
		} else if (tile.owner == WBCTileOwnerOrange) {
			fillColor = [UIColor WBCWordbaseDarkOrange];
		} else if (tile.owner == WBCTileOwnerBlue) {
			fillColor = [UIColor WBCWordbaseBlue];
		} else if (tile.isBombTile) {
			fillColor = [UIColor blackColor];
			textColor = [UIColor whiteColor];
		} else {
			fillColor = [UIColor whiteColor];
		}
		
		CGContextSetFillColorWithColor(context, fillColor.CGColor);
		CGContextFillRect(context, tileRect);
		
		if (self.drawLetters) {
			NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			paragraphStyle.alignment = NSTextAlignmentCenter;
			
			NSDictionary *titleAttributes = @{ NSForegroundColorAttributeName : textColor,
											   NSFontAttributeName : [UIFont fontWithName:@"Gotham Bold" size:24.0f],
											   NSParagraphStyleAttributeName : paragraphStyle };
			
			CGSize titleSize = [tile.value sizeWithAttributes:titleAttributes];
			CGRect titleRect = CGRectZero;
			titleRect.size.width = CGRectGetWidth(tileRect);
			titleRect.size.height = titleSize.height;
			titleRect.origin.x = CGRectGetMinX(tileRect);
			titleRect.origin.y = CGRectGetMinY(tileRect) + (CGRectGetHeight(tileRect) - titleSize.height) * 0.50f;
			
			[tile.value drawInRect:titleRect withAttributes:titleAttributes];
		}

		if (self.drawBadges && badgeText) {
			NSDictionary *badgeAttributes = @{ NSForegroundColorAttributeName : textColor,
											   NSFontAttributeName : [UIFont fontWithName:@"Gotham Bold" size:10.0f] };
			
			CGPoint badgePoint = tileRect.origin;
			badgePoint.x += 3.0f;
			badgePoint.y += 3.0f;
			[badgeText drawAtPoint:badgePoint withAttributes:badgeAttributes];
		}
	}
}

@end
