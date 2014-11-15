//
//  WBCGraphNode.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCGraphNode.h"

@interface WBCGraphNode ()
@property (readonly, nonatomic) NSMutableArray *neighbors;
@end

@implementation WBCGraphNode

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithNodeValue:(NSString *)value indexPath:(WBCIndexPath *)indexPath owner:(WBCTileOwner)owner {
	if (self = [super init]) {
		_value = value;
		_indexPath = indexPath;
		_owner = owner;
	}
	
	return self;
}

+ (instancetype)nodeWithValue:(NSString *)value indexPath:(WBCIndexPath *)indexPath owner:(WBCTileOwner)owner {
	return [[[self class] alloc] initWithNodeValue:value indexPath:indexPath owner:owner];
}

#pragma mark -
#pragma mark Public Methods

- (void)addNeighbor:(WBCGraphNode *)neighbor {
	if (!_neighbors) {
		_neighbors = [NSMutableArray new];
	}
	
	if (![_neighbors containsObject:neighbor]) {
		[_neighbors addObject:neighbor];
	}
}

@end
