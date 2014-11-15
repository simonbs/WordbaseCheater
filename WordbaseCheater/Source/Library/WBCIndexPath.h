//
//  WBCIndexPath.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 14/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WBCIndexPath : NSObject

- (instancetype)initWithRow:(NSUInteger)row column:(NSUInteger)column;
+ (instancetype)indexPathForRow:(NSUInteger)row column:(NSUInteger)column;

@property (nonatomic, readonly) NSUInteger row;
@property (nonatomic, readonly) NSUInteger column;

@end
