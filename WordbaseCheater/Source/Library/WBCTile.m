//
//  WBCTile.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 14/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import "WBCTile.h"

@implementation WBCTile

#pragma mark -
#pragma mark Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        _owner = WBCTileOwnerUnknown;
    }
    
    return self;
}

- (void)dealloc {
    _value = nil;
    _indexPath = nil;
}

@end
