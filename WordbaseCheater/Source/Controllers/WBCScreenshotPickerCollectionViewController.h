//
//  WBCScreenshotPickerCollectionViewController.h
//  WordbaseCheater
//
//  Created by Simon Støvring on 17/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WBCScreenshotPickerCollectionViewControllerDelegate;

@interface WBCScreenshotPickerCollectionViewController : UICollectionViewController

@property (weak, nonatomic) id<WBCScreenshotPickerCollectionViewControllerDelegate> delegate;

@end

@protocol WBCScreenshotPickerCollectionViewControllerDelegate <NSObject>
@optional
- (void)screenshotPickerCollectionViewController:(WBCScreenshotPickerCollectionViewController *)controller didPickScreenshot:(UIImage *)screenshot;
- (void)screenshotPickerCollectionViewControllerDidCancel:(WBCScreenshotPickerCollectionViewController *)controller;
@end