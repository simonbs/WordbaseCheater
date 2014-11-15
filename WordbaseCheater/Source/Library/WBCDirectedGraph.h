//
//  WBCDirectedGraph.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WBCGraphNode;

@interface WBCDirectedGraph : NSObject

@property (readonly, nonatomic) NSArray *nodes;

- (instancetype)initWithNodes:(NSArray *)nodes;
+ (instancetype)graphWithNodes:(NSArray *)nodes;
- (void)addEdgeFromNode:(WBCGraphNode *)node1 toNode:(WBCGraphNode *)node2;
- (void)addBidirectionalEdgeFromNode:(WBCGraphNode *)node1 toNode:(WBCGraphNode *)node2;

@end
