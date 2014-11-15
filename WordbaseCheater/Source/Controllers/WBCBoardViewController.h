//
//  WBCBoardViewController.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WBCBoardView.h"

@interface WBCBoardViewController : UIViewController

@property (strong, nonatomic) WBCBoard *board;
@property (strong, nonatomic) NSArray *selectedPath;

@end
