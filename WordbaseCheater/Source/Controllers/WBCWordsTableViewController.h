//
//  WBCWordsTableViewController.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 13/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WBCWordsTableViewController : UITableViewController

@property (assign, nonatomic) WBCLanguage language;
@property (assign, nonatomic) WBCTileOwner owner;
@property (strong, nonatomic) UIImage *screenshot;

@end
