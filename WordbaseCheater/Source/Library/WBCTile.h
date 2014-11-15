//
//  WBCTile.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 14/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat WBCTileUnkownConfidence = -1;

typedef NS_ENUM(NSInteger, WBCTileOwner) {
    WBCTileOwnerUnknown = -1,
    WBCTileOwnerOrange = 0,
    WBCTileOwnerBlue
};

@class WBCIndexPath;

@interface WBCTile : NSObject

@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign, getter = isBombTile) BOOL bombTile;
@property (nonatomic, strong) WBCIndexPath *indexPath;
@property (nonatomic, assign) WBCTileOwner owner;
@property (nonatomic, assign) CGFloat confidence;

@end
