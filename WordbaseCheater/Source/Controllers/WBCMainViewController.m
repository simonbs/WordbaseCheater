//
//  WBCMainViewController.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 16/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCMainViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WBCWordsTableViewController.h"

static NSString* const WBCMainWordsSegue = @"Words";

@interface WBCMainViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *languageButton;
@property (weak, nonatomic) IBOutlet UIButton *colorButton;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UIView *continueButtonSeparatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *screenshotBottomMarginConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *continueTopMarginConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *continueHeightConstraint;

@property (assign, nonatomic) CGFloat defaultScreenshotBottomMargin;
@property (assign, nonatomic) CGFloat defaultContinueTopMargin;
@property (assign, nonatomic) CGFloat defaultContinueHeight;

@property (assign, nonatomic) WBCTileOwner selectedOwner;
@property (strong, nonatomic) UIImage *selectedScreenshot;
@end

@implementation WBCMainViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[GVUserDefaults standardUserDefaults] addObserver:self forKeyPath:NSStringFromSelector(@selector(language)) options:0 context:nil];
	
	self.defaultScreenshotBottomMargin = self.screenshotBottomMarginConstraint.constant;
	self.defaultContinueTopMargin = self.continueTopMarginConstraint.constant;
	self.defaultContinueHeight = self.continueHeightConstraint.constant;
	
	UIEdgeInsets buttonInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 30.0f);
	UIImage *lightButtonBackground = [[UIImage imageNamed:@"light-button"] resizableImageWithCapInsets:buttonInsets];
	UIImage *lightButtonIndicatorBackground = [[UIImage imageNamed:@"light-button-indicator"] resizableImageWithCapInsets:buttonInsets];
	UIImage *greenButtonIndicatorBackground = [[UIImage imageNamed:@"green-button-indicator"] resizableImageWithCapInsets:buttonInsets];
	[self.languageButton setBackgroundImage:lightButtonIndicatorBackground forState:UIControlStateNormal];
	[self.colorButton setBackgroundImage:lightButtonBackground forState:UIControlStateNormal];
	[self.imageButton setBackgroundImage:lightButtonIndicatorBackground forState:UIControlStateNormal];
	[self.continueButton setBackgroundImage:greenButtonIndicatorBackground forState:UIControlStateNormal];
	
	self.languageButton.backgroundColor = [UIColor clearColor];
	self.colorButton.backgroundColor = [UIColor clearColor];
	self.imageButton.backgroundColor = [UIColor clearColor];
	self.continueButton.backgroundColor = [UIColor clearColor];
	
	[self setContinueButtonVisible:NO animated:NO];
	
	[self updateColorButton];
	[self updateLanguageButton];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	// This can be the case when the user continues,
	// we reset the view to prepare for a new screenshot
	if (!self.selectedScreenshot) {
		[self updateImageButton];
		[self setContinueButtonVisible:NO animated:NO];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == [GVUserDefaults standardUserDefaults] && [keyPath isEqualToString:NSStringFromSelector(@selector(language))]) {
		[self updateLanguageButton];
	}
}

- (void)dealloc {
	[[GVUserDefaults standardUserDefaults] removeObserver:self forKeyPath:NSStringFromSelector(@selector(language))];
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)colorButtonPressed:(id)sender {
	WBCTileOwner currentOwner = [GVUserDefaults standardUserDefaults].owner;
	[GVUserDefaults standardUserDefaults].owner = (currentOwner == WBCTileOwnerOrange) ? WBCTileOwnerBlue : WBCTileOwnerOrange;
	[self updateColorButton];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)imageButtonPressed:(id)sender {
	[self presentImagePicker];
}

- (void)updateColorButton {
	if ([GVUserDefaults standardUserDefaults].owner == WBCTileOwnerOrange) {
		[self.colorButton setImage:[UIImage imageNamed:@"orange"] forState:UIControlStateNormal];
	} else {
		[self.colorButton setImage:[UIImage imageNamed:@"blue"] forState:UIControlStateNormal];
	}
}

- (void)updateLanguageButton {
	WBCLanguage language = [[[GVUserDefaults standardUserDefaults] language] integerValue];
	NSString *displayName = [WBCLanguages displayNameForLanguage:language];
	UIImage *flag = [WBCLanguages flagForLanguage:language];
	[self.languageButton setTitle:displayName forState:UIControlStateNormal];
	[self.languageButton setImage:flag forState:UIControlStateNormal];
}

- (void)updateImageButton {
	if (self.selectedScreenshot) {
		UIImage *thumbnail = [self thumbnailFromScreenshot:self.selectedScreenshot];
		[self.imageButton setImage:thumbnail forState:UIControlStateNormal];
	} else {
		UIImage *placeholderImage = [UIImage imageNamed:@"select-screenshot"];
		[self.imageButton setImage:placeholderImage forState:UIControlStateNormal];
	}
}

- (void)setContinueButtonVisible:(BOOL)visible animated:(BOOL)animated {
	self.continueHeightConstraint.constant = visible ? self.defaultContinueHeight : 0.0f;
	self.continueTopMarginConstraint.constant = visible ? self.defaultContinueTopMargin : 0.0f;
	self.screenshotBottomMarginConstraint.constant = visible ? self.defaultScreenshotBottomMargin : 0.0f;
	
	if (animated) {
		[UIView animateWithDuration:0.30f animations:^{
			[self.view layoutIfNeeded];;
			
			self.continueButtonSeparatorView.alpha = visible;
			self.continueButton.alpha = visible;
		}];
	} else {
		[self.view layoutIfNeeded];;
		
		self.continueButtonSeparatorView.alpha = visible;
		self.continueButton.alpha = visible;
	}
}

- (void)presentImagePicker {
	UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.delegate = self;
	imagePickerController.mediaTypes = @[ (NSString *)kUTTypeImage ];
	imagePickerController.editing = NO;
	imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	[self presentViewController:imagePickerController animated:YES completion:nil];
}

- (UIImage *)thumbnailFromScreenshot:(UIImage *)screenshot {
	CGSize size = CGSizeMake(70.0f, 47.0f);
	
	CGFloat scaleFactor = MAX(size.width / screenshot.size.width, size.height / screenshot.size.height);
	CGSize scaledSize = screenshot.size;
	scaledSize.width *= scaleFactor;
	scaledSize.height *= scaleFactor;
	
	UIGraphicsBeginImageContext(scaledSize);
	[screenshot drawInRect: CGRectMake(0.0f, 0.0f, scaledSize.width, scaledSize.height)];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	CGRect cropRegion = CGRectZero;
	cropRegion.size = size;
	cropRegion.origin.y = (image.size.height - size.height) * 0.50f;
	
	CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRegion);
	UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationUp];
	CGImageRelease(imageRef);
	
	CGRect roundRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	
	UIGraphicsBeginImageContext(size);
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:roundRect cornerRadius:5.0f];
	[path addClip];
	[croppedImage drawInRect:roundRect];
	UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return roundedImage;
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[picker dismissViewControllerAnimated:YES completion:^{
		[self setContinueButtonVisible:YES animated:YES];
	}];
	
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.selectedScreenshot = image;
	[self updateImageButton];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:WBCMainWordsSegue]) {
		WBCWordsTableViewController *wordsTableController = segue.destinationViewController;
		wordsTableController.owner = self.selectedOwner;
		wordsTableController.screenshot = self.selectedScreenshot;
		wordsTableController.language = [[GVUserDefaults standardUserDefaults] primitiveLanguage];
		self.selectedScreenshot = nil;
	}
}

@end
