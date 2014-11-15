//
//  WBCDirectedGraph.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCDirectedGraph.h"
#import "WBCGraphNode.h"

@implementation WBCDirectedGraph

#pragma mark -
#pragma mark Public Methods

- (instancetype)initWithNodes:(NSArray *)nodes {
	if (self = [super init]) {
		_nodes = nodes;
	}
	
	return self;
}

+ (instancetype)graphWithNodes:(NSArray *)nodes {
	return [[[self class] alloc] initWithNodes:nodes];
}

- (void)addEdgeFromNode:(WBCGraphNode *)node1 toNode:(WBCGraphNode *)node2 {
	[node1 addNeighbor:node2];
}

- (void)addBidirectionalEdgeFromNode:(WBCGraphNode *)node1 toNode:(WBCGraphNode *)node2 {
	[node1 addNeighbor:node2];
	[node2 addNeighbor:node1];
}

@end
