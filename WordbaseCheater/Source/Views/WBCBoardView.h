//
//  WBCBoardView.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WBCBoard;

@interface WBCBoardView : UIView

@property (strong, nonatomic) WBCBoard *board;
@property (strong, nonatomic) NSArray *selectedPath;

@end
