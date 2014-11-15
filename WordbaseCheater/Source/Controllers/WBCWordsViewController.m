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
#import "WBCGraphScanner.h"
#import "WBCGraphNode.h"

static NSString* const WBCWordsCellIdentifier = @"Word";

@interface WBCWordsViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, WBCGraphScannerDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *ownerSegmentedControl;
@property (strong, nonatomic) NSArray *knownWords;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) WBCGraphScanner *graphScanner;
@property (strong, nonatomic) NSMutableArray *results;
@end

@implementation WBCWordsViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.activityIndicatorView.hidesWhenStopped = YES;
	self.activityIndicatorView.color = self.view.tintColor;
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView];
}

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

- (void)processScreenshot:(UIImage *)screenshot {
	self.navigationItem.rightBarButtonItem.enabled = NO;
	if (self.graphScanner) {
		[self.graphScanner stop];
		self.graphScanner = nil;
	}
	
	[self scanScreenshot:screenshot];
}

- (void)scanScreenshot:(UIImage *)screenshot {
	self.results = [NSMutableArray new];
	[self.tableView reloadData];
	
	[self.activityIndicatorView startAnimating];
	WBCBoardCreator *boardCreator = [WBCBoardCreator boardCreatorWithImage:screenshot];
	[boardCreator createBoard:^(WBCBoard *board) {
		self.graphScanner = [WBCGraphScanner scannerWithBoard:board];
		self.graphScanner.delegate = self;
		[self.graphScanner createGraph];
	}];
}

- (WBCTileOwner)selectedOwner {
	if (self.ownerSegmentedControl.selectedSegmentIndex == 0) {
		return WBCTileOwnerOrange;
	}
	
	return WBCTileOwnerBlue;
}

- (void)addWord:(NSString *)word path:(NSArray *)path {
	NSDictionary *result = @{ @"word": word, @"path": path };
	[self insertResult:result atIndex:[self.results count]];
}

- (void)insertResult:(NSDictionary *)result atIndex:(NSUInteger)index {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
	[self.tableView beginUpdates];
	[self.results insertObject:result atIndex:index];
	[self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
	[self.tableView endUpdates];
}

- (BOOL)isKnownWord:(NSString *)word {
	NSRange searchRange = NSMakeRange(0, [self.knownWords count]);
	NSInteger index = [self.knownWords indexOfObject:word inSortedRange:searchRange options:NSBinarySearchingFirstEqual usingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [obj1 compare:obj2];
	}];
	
	return index != NSNotFound;
}

- (BOOL)knownWordBeginsWithLetterSequence:(NSString *)letterSequence {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF beginswith %@", letterSequence];
	NSArray *results = [self.knownWords filteredArrayUsingPredicate:predicate];
	return [results count] > 0;
}

- (NSString *)wordFromPath:(NSArray *)path {
	NSMutableString *word = [NSMutableString new];
	for (WBCGraphNode *node in path) {
		[word appendString:node.value];
	}
	
	return word;
}

#pragma mark -
#pragma mark Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *result = self.results[indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:WBCWordsCellIdentifier];
	cell.textLabel.text = result[@"word"];
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.results count];
}

#pragma mark -
#pragma mark Image Picker Controller Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[picker dismissViewControllerAnimated:YES completion:nil];
	
	[self prepareKnownWords];
	
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	[self processScreenshot:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Graph Scanner Delegate

- (void)graphScannerDidCreateGraph:(WBCGraphScanner *)scanner {
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[self.activityIndicatorView stopAnimating];
	[scanner searchGraphAsOwner:[self selectedOwner]];
}

- (void)graphScanner:(WBCGraphScanner *)scanner shouldContinueDownPath:(NSArray *)path handler:(void (^)(BOOL))handler {
	if ([path count] == 1) {
		handler(YES);
		return;
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		NSString *letterSequence = [self wordFromPath:path];
		BOOL continueDownPath = [self knownWordBeginsWithLetterSequence:letterSequence];
		handler(continueDownPath);
		
		if (continueDownPath) {
			if ([self isKnownWord:letterSequence]) {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self addWord:letterSequence path:path];
				});
			}
		}
	});
}

@end
