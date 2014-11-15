//
//  WBCIndexPath.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 14/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import "WBCIndexPath.h"

@implementation WBCIndexPath

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithRow:(NSUInteger)row column:(NSUInteger)column {
    if (self = [super init]) {
        _row = row;
        _column = column;
    }
    
    return self;
}

+ (instancetype)indexPathForRow:(NSUInteger)row column:(NSUInteger)column {
    return [[[self class] alloc] initWithRow:row column:column];
}

@end
