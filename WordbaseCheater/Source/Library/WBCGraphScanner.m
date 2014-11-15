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
	NSLog(@"Dealloc graph scanner");
	
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
	self.stopped = NO;
	
	NSInteger nodesCount = [self.graph.nodes count];
	if (owner == WBCTileOwnerOrange) {
		for (NSInteger i = nodesCount - 1; i >= 0; i--) {
			WBCGraphNode *node = self.graph.nodes[i];
			[self attemptToSearchFromNode:node asOwner:owner];
		}
	} else if (owner == WBCTileOwnerBlue) {
		for (NSInteger i = 0; i < nodesCount; i++) {
			WBCGraphNode *node = self.graph.nodes[i];
			[self attemptToSearchFromNode:node asOwner:owner];
		}
	}
}

- (void)stop {
	self.stopped = YES;
}

#pragma mark -
#pragma mark Private Methods

- (void)attemptToSearchFromNode:(WBCGraphNode *)node asOwner:(WBCTileOwner)owner {
	if (node.owner == owner && !self.isStopped) {
		NSLog(@"Start on node with value: %@", node.value);
		[self searchFromNode:node];
	}
}

- (void)searchFromNode:(WBCGraphNode *)node {
	[self searchFromNode:node currentPath:[NSMutableArray new]];
}

- (void)searchFromNode:(WBCGraphNode *)node currentPath:(NSMutableArray *)currentPath {
	if (self.isStopped) {
		return;
	}
	
	[currentPath addObject:node];
	[self shouldContinueDownPath:currentPath handler:^(BOOL shouldContinue) {
		NSLog(@"- %@", [self wordFromPath:currentPath]);
		if (shouldContinue) {
			for (WBCGraphNode *neighbour in node.neighbors) {
				if (![currentPath containsObject:neighbour]) {
					NSMutableArray *newCurrentPath = [NSMutableArray arrayWithArray:currentPath];
					[self searchFromNode:neighbour currentPath:newCurrentPath];
				}
			}
		} else {
			NSLog(@" > Cancelled");
		}
	}];
}

- (NSString *)wordFromPath:(NSArray *)path {
	NSMutableString *word = [NSMutableString new];
	for (WBCGraphNode *node in path) {
		[word appendString:node.value];
	}
	
	return word;
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
