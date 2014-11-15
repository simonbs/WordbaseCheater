//
//  WBCGraphScanner.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCGraphScanner.h"
#import "WBCBoard.h"
#import "WBCDirectedGraph.h"
#import "WBCGraphNode.h"
#import "WBCIndexPath.h"

@interface WBCGraphScanner ()
@property (strong, nonatomic) WBCBoard *board;
@property (assign, nonatomic) NSInteger maxRow;
@property (assign, nonatomic) NSInteger maxColumn;
@property (strong, nonatomic) WBCDirectedGraph *graph;
@property (assign, nonatomic, getter=isStopped) BOOL stopped;
@property (strong, nonatomic) NSMutableArray *pathStack;
@property (assign, nonatomic) WBCTileOwner owner;
@end

@implementation WBCGraphScanner

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithBoard:(WBCBoard *)board {
	if (self = [super init]) {
		_board = board;
	}
	
	return self;
}

+ (instancetype)scannerWithBoard:(WBCBoard *)board {
	return [[[self class] alloc] initWithBoard:board];
}

- (void)dealloc {
	_board = nil;
	_graph = nil;
}

#pragma mark -
#pragma mark Public Methods

- (void)createGraph {
	NSAssert(self.board != nil, @"Must have board set before graph can be created. Initialize the scanner with a board.");
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[self findBoardSize];
		
		NSMutableArray *nodes = [NSMutableArray new];
		for (WBCTile *tile in self.board.tiles) {
			WBCGraphNode *node = [WBCGraphNode nodeWithValue:tile.value indexPath:tile.indexPath owner:tile.owner];
			[nodes addObject:node];
		}
		
		self.graph = [WBCDirectedGraph graphWithNodes:nodes];
		NSUInteger nodesCount = [nodes count];
		for (NSUInteger i = 0; i < nodesCount; i++) {
			WBCGraphNode *node = [nodes objectAtIndex:i];
			
			WBCIndexPath *indexPath = node.indexPath;
			if (indexPath.row > 0 && indexPath.column > 0) {
				WBCGraphNode *topLeft = [self searchNodes:nodes forNodeAtIndexPath:[WBCIndexPath indexPathForRow:indexPath.row - 1 column:indexPath.column - 1]];
				if (topLeft) {
					[self.graph addEdgeFromNode:node toNode:topLeft];
				}
			}
			
			if (indexPath.row > 0) {
				WBCGraphNode *topMiddle = [self searchNodes:nodes forNodeAtIndexPath:[WBCIndexPath indexPathForRow:indexPath.row - 1 column:indexPath.column]];
				if (topMiddle) {
					[self.graph addEdgeFromNode:node toNode:topMiddle];
				}
			}
			
			if (indexPath.row > 0 && indexPath.column < self.maxColumn) {
				WBCGraphNode *topRight = [self searchNodes:nodes forNodeAtIndexPath:[WBCIndexPath indexPathForRow:indexPath.row - 1 column:indexPath.column + 1]];
				if (topRight) {
					[self.graph addEdgeFromNode:node toNode:topRight];
				}
			}
			
			if (indexPath.column > 0) {
				WBCGraphNode *middleLeft = [self searchNodes:nodes forNodeAtIndexPath:[WBCIndexPath indexPathForRow:indexPath.row column:indexPath.column - 1]];
				if (middleLeft) {
					[self.graph addEdgeFromNode:node toNode:middleLeft];
				}
			}
			
			if (indexPath.column < self.maxColumn) {
				WBCGraphNode *middleRight = [self searchNodes:nodes forNodeAtIndexPath:[WBCIndexPath indexPathForRow:indexPath.row column:indexPath.column + 1]];
				if (middleRight) {
					[self.graph addEdgeFromNode:node toNode:middleRight];
				}
			}
			
			if (indexPath.row < self.maxRow && indexPath.column > 0) {
				WBCGraphNode *bottomLeft = [self searchNodes:nodes forNodeAtIndexPath:[WBCIndexPath indexPathForRow:indexPath.row + 1 column:indexPath.column - 1]];
				if (bottomLeft) {
					[self.graph addEdgeFromNode:node toNode:bottomLeft];
				}
			}
			
			if (indexPath.row < self.maxRow) {
				WBCGraphNode *bottomMiddle = [self searchNodes:nodes forNodeAtIndexPath:[WBCIndexPath indexPathForRow:indexPath.row + 1 column:indexPath.column]];
				if (bottomMiddle) {
					[self.graph addEdgeFromNode:node toNode:bottomMiddle];
				}
			}
			
			if (indexPath.row < self.maxRow && indexPath.column < self.maxColumn) {
				WBCGraphNode *bottomRight = [self searchNodes:nodes forNodeAtIndexPath:[WBCIndexPath indexPathForRow:indexPath.row + 1 column:indexPath.column + 1]];
				if (bottomRight) {
					[self.graph addEdgeFromNode:node toNode:bottomRight];
				}
			}
		}
		
		if ([self.delegate respondsToSelector:@selector(graphScannerDidCreateGraph:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.delegate graphScannerDidCreateGraph:self];
			});
		}
	});
}

- (void)searchGraphAsOwner:(WBCTileOwner)owner {
	_searching = YES;
	self.owner = owner;
	self.stopped = NO;
	self.pathStack = [NSMutableArray new];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		NSInteger nodesCount = [self.graph.nodes count];
		if (owner == WBCTileOwnerOrange) {
			for (NSInteger i = 0; i < nodesCount; i++) {
				WBCGraphNode *node = self.graph.nodes[i];
				if (node.owner == WBCTileOwnerOrange) {
					[self.pathStack addObject:@[ node ]];
				}
			}
		} else if (owner == WBCTileOwnerBlue) {
			for (NSInteger i = nodesCount - 1; i >= 0; i--) {
				WBCGraphNode *node = self.graph.nodes[i];
				if (node.owner == WBCTileOwnerBlue) {
					[self.pathStack addObject:@[ node ]];
				}
			}
		}
		
		[self searchNextPath];
	});
}

- (void)stop {
	self.stopped = YES;
	_searching = NO;
}

#pragma mark -
#pragma mark Private Methods

- (void)searchNextPath {
	if (self.isStopped) {
		return;
	}
	
	NSArray *path = [self popPath];
	if (!path) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if ([self.delegate respondsToSelector:@selector(graphScannerDidCompleteScan:)]) {
				[self.delegate graphScannerDidCompleteScan:self];
			}
		});
	} else {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self shouldContinueDownPath:path handler:^(BOOL shouldContinue) {
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
					if (shouldContinue) {
						WBCGraphNode *lastNode = [path lastObject];
						for (WBCGraphNode *neighbour in lastNode.neighbors) {
							if (![path containsObject:neighbour]) {
								NSMutableArray *mutablePath = [NSMutableArray arrayWithArray:path];
								[mutablePath addObject:neighbour];
								[self.pathStack addObject:[NSArray arrayWithArray:mutablePath]];
							}
						}
					}
					
					[self searchNextPath];
				});
			}];
		});
	}
}

- (NSArray *)popPath {
	// Sort the stack to work on the path that leads in the "right direction",
	// e.g. if the owner is orange we are generally interested in hitting rows at the bottom (rows with high index number),
	// and if the owner is blue we are generally interested in hitting rows at the top (rows with low index number),
	NSString *sortPath = [NSString stringWithFormat:@"%@.indexPath.row", (self.owner == WBCTileOwnerOrange) ? @"@max" : @"@min"];
	NSArray *sortedStack = [self.pathStack sortedArrayUsingComparator:^NSComparisonResult(NSArray *path1, NSArray *path2) {
		return [path1 valueForKeyPath:sortPath] < [path2 valueForKeyPath:sortPath];
	}];
	
	if (sortedStack && [sortedStack count] > 0) {
		NSArray *path = [sortedStack lastObject];
		[self.pathStack removeObject:path];
		return path;
	}
	
	return nil;
}

- (WBCGraphNode *)searchNodes:(NSArray *)nodes forNodeAtIndexPath:(WBCIndexPath *)indexPath {
	NSUInteger index = [nodes indexOfObjectPassingTest:^BOOL(WBCGraphNode *node, NSUInteger idx, BOOL *stop) {
		WBCIndexPath *thisIndexPath = node.indexPath;
		BOOL isFound = thisIndexPath.row == indexPath.row && thisIndexPath.column == indexPath.column;
		*stop = isFound;
		return *stop;
	}];
	
	return nodes[index];
}

- (void)findBoardSize {
	self.maxRow = [[self.board.tiles valueForKeyPath:@"@max.indexPath.row"] integerValue];
	self.maxColumn = [[self.board.tiles valueForKeyPath:@"@max.indexPath.column"] integerValue];
}

- (void)shouldContinueDownPath:(NSArray *)path handler:(void(^)(BOOL shouldContinue))handler {
	[self.delegate graphScanner:self shouldContinueDownPath:path handler:handler];
}

@end
