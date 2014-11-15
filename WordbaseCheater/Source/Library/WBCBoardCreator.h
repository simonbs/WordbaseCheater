//
//  WBCBoardCreator.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WBCBoard;

@interface WBCBoardCreator : NSObject

- (instancetype)initWithImage:(UIImage *)image;
+ (instancetype)boardCreatorWithImage:(UIImage *)image;
- (void)createBoard:(void(^)(WBCBoard *board))completion;

@end
