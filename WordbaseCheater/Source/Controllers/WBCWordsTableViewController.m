//
//  WBCWordsTableViewController.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 13/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCWordsTableViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WBCBoardCreator.h"
#import "WBCBoard.h"
#import "WBCGraphScanner.h"
#import "WBCGraphNode.h"
#import "WBCBoardViewController.h"
#import "UIColor+WBCWordbase.h"

static NSString* const WBCWordsCellIdentifier = @"Word";
static NSString* const WBCWordsBoardSegue = @"Board";
static NSString* const WBCWordsSettingsSegue = @"Settings";

@interface WBCWordsTableViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, WBCGraphScannerDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *ownerSegmentedControl;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIBarButtonItem *activityIndicatorBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *settingsBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *photosBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *cancelBarButtonItem;

@property (strong, nonatomic) NSArray *knownWords;
@property (strong, nonatomic) WBCBoard *board;
@property (strong, nonatomic) WBCGraphScanner *graphScanner;
@property (strong, nonatomic) NSMutableArray *results;
@property (strong, nonatomic) UIImage *selectedScreenshot;
@end

@implementation WBCWordsTableViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	NSArray *segmentViews = [self.ownerSegmentedControl subviews];
	((UIView *)[segmentViews objectAtIndex:0]).tintColor = [UIColor WBCWordbaseBlue];
	((UIView *)[segmentViews objectAtIndex:1]).tintColor = [UIColor WBCWordbaseDarkOrange];
	self.ownerSegmentedControl.selectedSegmentIndex = [GVUserDefaults standardUserDefaults].owner;
	
	self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.activityIndicatorView.hidesWhenStopped = YES;
	self.activityIndicatorView.color = self.navigationController.navigationBar.tintColor;
	self.activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView];
	
	UIImage *photosImage = [UIImage imageNamed:@"photos"];
	UIImage *settingsImage = [UIImage imageNamed:@"settings"];
	UIImage *cancelImage = [UIImage imageNamed:@"cancel"];
	
	self.photosBarButtonItem = [[UIBarButtonItem alloc] initWithImage:photosImage style:UIBarButtonItemStylePlain target:self action:@selector(presentImagePicker:)];
	self.settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImage style:UIBarButtonItemStylePlain target:self action:@selector(presentSettings:)];
	self.cancelBarButtonItem = [[UIBarButtonItem alloc] initWithImage:cancelImage style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
	
	self.navigationItem.leftBarButtonItem = self.settingsBarButtonItem;
	self.navigationItem.rightBarButtonItem = self.photosBarButtonItem;
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)ownerSegmentedControlValueChanged:(id)sender {
	if (self.selectedScreenshot) {
		[self.navigationItem setLeftBarButtonItem:nil animated:YES];
		[self.navigationItem setRightBarButtonItem:nil animated:YES];
		
		[self processScreenshot:self.selectedScreenshot];
	}
	
	[GVUserDefaults standardUserDefaults].owner = self.ownerSegmentedControl.selectedSegmentIndex;
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)presentImagePicker:(id)sender {
	UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.delegate = self;
	imagePickerController.mediaTypes = @[ (NSString *)kUTTypeImage ];
	imagePickerController.editing = NO;
	imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	[self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)presentSettings:(id)sender {
	[self performSegueWithIdentifier:WBCWordsSettingsSegue sender:self];
}

- (void)cancel:(id)sender {
	[self stopGraphScanner];
	
	[self.navigationItem setLeftBarButtonItem:self.settingsBarButtonItem animated:YES];
	[self.navigationItem setRightBarButtonItem:self.photosBarButtonItem animated:YES];
}

- (void)stopGraphScanner {
	if (self.graphScanner) {
		if (self.graphScanner.isSearching) {
			[self.graphScanner stop];
		}
		
		self.graphScanner = nil;
	}
}

- (void)prepareKnownWords {
	NSString *language = [GVUserDefaults standardUserDefaults].language;
	NSString *filename = [NSString stringWithFormat:@"words_%@", language];
	NSString *wordsPath = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
	NSString *wordsText = [NSString stringWithContentsOfFile:wordsPath encoding:NSUTF8StringEncoding error:nil];
	self.knownWords = [wordsText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void)processScreenshot:(UIImage *)screenshot {
	[self stopGraphScanner];

	self.results = nil;
	[self.tableView reloadData];
	
	[self.activityIndicatorView startAnimating];
	[self.navigationItem setLeftBarButtonItem:self.activityIndicatorBarButtonItem animated:YES];
	
	WBCBoardCreator *boardCreator = [WBCBoardCreator boardCreatorWithImage:screenshot];
	[boardCreator createBoard:^(WBCBoard *board) {
		self.board = board;
		self.graphScanner = [WBCGraphScanner scannerWithBoard:board];
		self.graphScanner.delegate = self;
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			[self.graphScanner createGraph];
		});
	}];
}

- (WBCTileOwner)selectedOwner {
	if (self.ownerSegmentedControl.selectedSegmentIndex == 0) {
		return WBCTileOwnerOrange;
	}
	
	return WBCTileOwnerBlue;
}

- (void)addWord:(NSString *)word path:(NSArray *)path {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		NSMutableArray *results = [NSMutableArray arrayWithArray:self.results];
		NSDictionary *result = @{ @"word": word, @"path": path };
		[results addObject:result];
		
		NSSortDescriptor *lengthSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"word.length" ascending:NO];
		NSSortDescriptor *alphabeticalSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"word" ascending:YES];
		[results sortUsingDescriptors:@[ lengthSortDescriptor, alphabeticalSortDescriptor ]];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.results = results;
			[self.tableView reloadData];
		});
	});
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
	
	[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	[self.navigationItem setRightBarButtonItem:nil animated:YES];
	
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	self.selectedScreenshot = image;
	[self processScreenshot:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Graph Scanner Delegate

- (void)graphScannerDidCreateGraph:(WBCGraphScanner *)scanner {
	self.results = [NSMutableArray new];
	[self.tableView reloadData];
	
	[self.graphScanner searchGraphAsOwner:[self selectedOwner]];
	
	[self.navigationItem setRightBarButtonItem:self.cancelBarButtonItem animated:YES];
}

- (void)graphScanner:(WBCGraphScanner *)scanner shouldContinueDownPath:(NSArray *)path handler:(void (^)(BOOL))handler {
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

- (void)graphScannerDidCompleteScan:(WBCGraphScanner *)scanner {
	[self.activityIndicatorView stopAnimating];
	
	[self.navigationItem setLeftBarButtonItem:self.settingsBarButtonItem animated:YES];
	[self.navigationItem setRightBarButtonItem:self.photosBarButtonItem animated:YES];
}

#pragma mark -
#pragma mark Lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:WBCWordsBoardSegue]) {
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		NSDictionary *result = self.results[indexPath.row];
		NSArray *path = result[@"path"];
		WBCBoardViewController *boardController = segue.destinationViewController;
		boardController.board = self.board;
		boardController.selectedPath = path;
	}
}

@end
