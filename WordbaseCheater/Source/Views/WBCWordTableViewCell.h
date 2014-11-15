//
//  WBCWordTableViewCell.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WBCBoardView;

@interface WBCWordTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet WBCBoardView *boardView;
@property (weak, nonatomic) IBOutlet UILabel *wordLabel;

@end
