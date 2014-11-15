//
//  WBCGraphScanner.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBCTile.h"

@class WBCBoard;
@protocol WBCGraphScannerDelegate;

@interface WBCGraphScanner : NSObject

@property (weak, nonatomic) id<WBCGraphScannerDelegate>delegate;
@property (readonly, nonatomic) WBCBoard *board;
@property (readonly, nonatomic, getter=isSearching) BOOL searching;

- (instancetype)initWithBoard:(WBCBoard *)board;
+ (instancetype)scannerWithBoard:(WBCBoard *)board;
- (void)createGraph;
- (void)searchGraphAsOwner:(WBCTileOwner)owner;
- (void)stop;

@end

@protocol WBCGraphScannerDelegate <NSObject>
@required
- (void)graphScanner:(WBCGraphScanner *)scanner shouldContinueDownPath:(NSArray *)path handler:(void(^)(BOOL shouldContinue))handler;
@optional
- (void)graphScannerDidCreateGraph:(WBCGraphScanner *)scanner;
- (void)graphScannerDidCompleteScan:(WBCGraphScanner *)scanner;
@end