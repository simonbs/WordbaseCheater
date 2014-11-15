//
//  WBCGraphNode.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBCTile.h"

@class WBCIndexPath;

@interface WBCGraphNode : NSObject

@property (readonly, nonatomic) NSString *value;
@property (readonly, nonatomic) WBCIndexPath *indexPath;
@property (readonly, nonatomic) WBCTileOwner owner;

- (instancetype)initWithNodeValue:(NSString *)value indexPath:(WBCIndexPath *)indexPath owner:(WBCTileOwner)owner;
+ (instancetype)nodeWithValue:(NSString *)value indexPath:(WBCIndexPath *)indexPath owner:(WBCTileOwner)owner;
- (void)addNeighbor:(WBCGraphNode *)neighbor;
- (NSArray *)neighbors;

@end
