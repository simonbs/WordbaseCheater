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
#import "WBCIndexPath.h"
#import "WBCBoardViewController.h"
#import "UIColor+WBCWordbase.h"
#import "WBCBoardView.h"
#import "WBCWordTableViewCell.h"

static NSString* const WBCWordsCellIdentifier = @"Word";
static NSString* const WBCWordsBoardSegue = @"Board";
static NSString* const WBCWordsSettingsSegue = @"Settings";

@interface WBCWordsTableViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, WBCGraphScannerDelegate>
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (strong, nonatomic) NSArray *knownWords;
@property (strong, nonatomic) WBCBoard *board;
@property (strong, nonatomic) WBCGraphScanner *graphScanner;
@property (strong, nonatomic) NSMutableArray *results;

@property (assign, nonatomic, getter=isStopped) BOOL stopped;
@end

@implementation WBCWordsTableViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	self.activityIndicatorView.hidesWhenStopped = YES;
	self.activityIndicatorView.color = self.navigationController.navigationBar.tintColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicatorView];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[self prepareKnownWords];
		
		if (!self.isStopped) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self processScreenshot:self.screenshot];
			});
		}
	});
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)startOverButtonPressed:(id)sender {
	[self stopGraphScanner];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)stopGraphScanner {
	self.stopped = YES;
	
	if (self.graphScanner) {
		if (self.graphScanner.isSearching) {
			[self.graphScanner stop];
		}
		
		self.graphScanner = nil;
	}
}

- (void)prepareKnownWords {
	NSString *language = [WBCLanguages nameForLanguage:self.language];
	NSString *filename = [NSString stringWithFormat:@"words_%@", language];
	NSString *wordsPath = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
	NSString *wordsText = [NSString stringWithContentsOfFile:wordsPath encoding:NSUTF8StringEncoding error:nil];
	self.knownWords = [[wordsText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)processScreenshot:(UIImage *)screenshot {
	[self stopGraphScanner];

	self.results = nil;
	[self.tableView reloadData];
	
	[self.activityIndicatorView startAnimating];
	
	NSString *traineddata = [WBCLanguages traineddataForLanguage:self.language];
	NSString *whitelist = [WBCLanguages whitelistForLanguage:self.language];
	
	WBCBoardCreator *boardCreator = [WBCBoardCreator boardCreatorWithImage:screenshot traineddata:traineddata whitelist:whitelist];
	[boardCreator createBoard:^(WBCBoard *board) {
#ifdef DEBUG
		NSLog(@"%@", [board stringRepresentation]);
#endif
		
		self.board = board;
		self.graphScanner = [WBCGraphScanner scannerWithBoard:board];
		self.graphScanner.delegate = self;
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			[self.graphScanner createGraph];
		});
	}];
}

- (void)addWord:(NSString *)word path:(NSArray *)path {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		NSInteger score = [self scoreForPath:path];
		
		NSMutableArray *results = [NSMutableArray arrayWithArray:self.results];
		NSDictionary *result = @{ @"word": word, @"path": path, @"score": @(score) };
		[results addObject:result];
		
		NSSortDescriptor *lengthSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO];
		NSSortDescriptor *alphabeticalSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"word" ascending:YES];
		[results sortUsingDescriptors:@[ lengthSortDescriptor, alphabeticalSortDescriptor ]];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!self.isStopped) {
				self.results = results;
				[self.tableView reloadData];
			}
		});
	});
}

- (NSUInteger)scoreForPath:(NSArray *)path {
	NSUInteger minRow = [[self.board.tiles valueForKeyPath:@"@min.indexPath.row"] integerValue];
	NSUInteger maxRow = [[self.board.tiles valueForKeyPath:@"@max.indexPath.row"] integerValue];
	
	NSPredicate *ownedPredicate = [NSPredicate predicateWithFormat:@"owner == %i", self.owner];
	NSArray *ownedTiles = [self.board.tiles filteredArrayUsingPredicate:ownedPredicate];
	
	NSUInteger minOwnedRow = [[ownedTiles valueForKeyPath:@"@min.indexPath.row"] integerValue];
	NSUInteger maxOwnedRow = [[ownedTiles valueForKeyPath:@"@max.indexPath.row"] integerValue];
	
	NSInteger score = 0;
	for (WBCGraphNode *node in path) {
		NSUInteger index = [self.board.tiles indexOfObjectPassingTest:^BOOL(WBCTile *tile, NSUInteger idx, BOOL *stop) {
			BOOL match = tile.indexPath.row == node.indexPath.row && tile.indexPath.column == node.indexPath.column;
			*stop = match;
			return match;
		}];
		
		WBCTile *tile = self.board.tiles[index];
		if (tile.owner == WBCTileOwnerUnknown) {
			// Add to score if tile is unused
			score += 2;
		} else if (tile.owner != self.owner) {
			// Add to score if this is the other players tile
			score += 10;
		}
		
		// Add to score if tile is in "the right direction"
		if ((self.owner == WBCTileOwnerOrange && node.indexPath.row > maxOwnedRow) ||
			(self.owner == WBCTileOwnerBlue && node.indexPath.row < minOwnedRow)) {
			score += 10;
		}
		
		// Add to score if it is a bomb tile
		if (tile.isBombTile) {
			score += 20;
		}
		
		// Check if this node reaches opponents base
		if ((self.owner == WBCTileOwnerOrange && node.indexPath.row == maxRow) ||
			(self.owner == WBCTileOwnerBlue && node.indexPath.row == minRow)) {
			score += 10000;
		}
	}
	
	return score;
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
	WBCWordTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:WBCWordsCellIdentifier];
	cell.wordLabel.text = result[@"word"];
	
	cell.boardView.board = self.board;
	cell.boardView.selectedPath = result[@"path"];
	[cell.boardView setNeedsDisplay];
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.results count];
}

#pragma mark -
#pragma mark Graph Scanner Delegate

- (void)graphScannerDidCreateGraph:(WBCGraphScanner *)scanner {
	self.results = [NSMutableArray new];
	[self.tableView reloadData];
	
	self.stopped = NO;
	[self.graphScanner searchGraphAsOwner:self.owner];
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
}

#pragma mark -
#pragma mark Segue

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
