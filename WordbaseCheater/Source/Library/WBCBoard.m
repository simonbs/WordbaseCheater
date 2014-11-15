//
//  WBCBoard.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 14/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import "WBCBoard.h"
#import "WBCTile.h"
#import "WBCIndexPath.h"

#define WBCTileValueUnknownRepresentation @"-"

@implementation WBCBoard

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithTiles:(NSArray *)tiles {
    if (self = [super init]) {
        _tiles = [tiles sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            WBCTile *tile1 = obj1;
            WBCTile *tile2 = obj2;
            NSInteger index1 = tile1.indexPath.row * 10 + tile1.indexPath.column;
            NSInteger index2 = tile2.indexPath.row * 10 + tile2.indexPath.column;
            return index1 > index2;
        }];
    }
    
    return self;
}

+ (instancetype)boardWithTiles:(NSArray *)tiles {
    return [[[self class] alloc] initWithTiles:tiles];
}

- (void)dealloc {
    _tiles = nil;
}

#pragma mark -
#pragma mark Public Methods

- (NSString *)stringRepresentation {
    NSInteger maxColumn = [[_tiles valueForKeyPath:@"@max.indexPath.column"] integerValue];
    NSMutableString *header = [NSMutableString stringWithFormat:@"\n  "];
    for (NSInteger i = 0; i <= maxColumn; i++) {
        [header appendFormat:@" %2li", (long)i];
    }
    
    NSInteger printRow = 0, currentRow = 0;
    NSMutableString *str = [NSMutableString stringWithFormat:@"%@\n%2li  ", header, (long)printRow];
    printRow++;
    
    for (WBCTile *tile in _tiles) {
        WBCIndexPath *indexPath = tile.indexPath;
        if (indexPath.row != currentRow) {
            [str appendFormat:@"\n%2li  ", (long)printRow];
            currentRow = indexPath.row;
            printRow++;
        }
        
        NSString *value = ([tile.value length] > 0) ? tile.value : WBCTileValueUnknownRepresentation;
        
        if (tile.owner == WBCTileOwnerOrange) {
            [str appendString:WBCColoredString(254, 136, 9, value)];
        } else if (tile.owner == WBCTileOwnerBlue) {
            [str appendString:WBCColoredString(0, 198, 231, value)];
        } else if (tile.isBombTile) {
            [str appendString:WBCColoredString(60, 231, 0, value)];
        } else {
            [str appendString:WBCColoredString(255, 255, 255, value)];
        }
        
        if (indexPath.row == currentRow) {
            [str appendString:@"  "];
        }
    }
    
    return str;
}

@end
