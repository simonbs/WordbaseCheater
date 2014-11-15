//
//  WBCWordsViewController.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 13/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCWordsViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WBCBoardCreator.h"
#import "WBCBoard.h"

@interface WBCWordsViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) NSArray *knownWords;
@end

@implementation WBCWordsViewController

#pragma mark -
#pragma mark Private Methods

- (IBAction)photosButtonPressed:(id)sender {
	[self presentImagePicker];
}

- (void)presentImagePicker {
	UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.delegate = self;
	imagePickerController.mediaTypes = @[ (NSString *)kUTTypeImage ];
	imagePickerController.editing = NO;
	imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	[self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)prepareKnownWords {
	NSString *language = [GVUserDefaults standardUserDefaults].language;
	NSString *filename = [NSString stringWithFormat:@"words_%@", language];
	NSString *wordsPath = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
	NSString *wordsText = [NSString stringWithContentsOfFile:wordsPath encoding:NSUTF8StringEncoding error:nil];
	self.knownWords = [wordsText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void)processImage:(UIImage *)image {
	WBCBoardCreator *boardCreator = [WBCBoardCreator boardCreatorWithImage:image];
	[boardCreator createBoard:^(WBCBoard *board) {
		NSLog(@"%@", [board stringRepresentation]);
	}];
}

#pragma mark -
#pragma mark Image Picker Controller Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[picker dismissViewControllerAnimated:YES completion:nil];
	
	[self prepareKnownWords];
	
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	[self processImage:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

@end
