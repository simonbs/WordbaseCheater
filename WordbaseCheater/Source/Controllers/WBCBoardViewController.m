//
//  WBCBoardViewController.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCBoardViewController.h"
#import "WBCBoardView.h"
#import "WBCGraphNode.h"

@interface WBCBoardViewController ()
@property (weak, nonatomic) IBOutlet WBCBoardView *boardView;
@end

@implementation WBCBoardViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = [self wordFromPath:self.selectedPath];
	
	self.boardView.drawLetters = YES;
	self.boardView.drawBadges = YES;
	self.boardView.board = self.board;
	self.boardView.selectedPath = self.selectedPath;
}

#pragma mark -
#pragma mark Private Methods

- (NSString *)wordFromPath:(NSArray *)path {
	NSMutableString *word = [NSMutableString new];
	for (WBCGraphNode *node in path) {
		[word appendString:node.value];
	}
	
	return word;
}

@end
