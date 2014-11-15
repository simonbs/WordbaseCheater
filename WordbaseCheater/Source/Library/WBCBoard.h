//
//  WBCBoard.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 14/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WBCBoard : NSObject

- (instancetype)initWithTiles:(NSArray *)tiles;
+ (instancetype)boardWithTiles:(NSArray *)tiles;
- (NSString *)stringRepresentation;

@property (nonatomic, readonly) NSArray *tiles;

@end
