//
//  WBCSettingsTableViewController.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCSettingsTableViewController.h"

@interface WBCSettingsTableViewController ()
@property (weak, nonatomic) IBOutlet UITableViewCell *englishTableViewCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *danishTableViewCell;
@end

@implementation WBCSettingsTableViewController

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self selectCurrentLanguage];
}

#pragma mark -
#pragma mark Private Methods

- (IBAction)dismiss:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectCurrentLanguage {
	self.englishTableViewCell.accessoryType = UITableViewCellAccessoryNone;
	self.danishTableViewCell.accessoryType = UITableViewCellAccessoryNone;;
	
	WBCLanguage language = [[GVUserDefaults standardUserDefaults] primitiveLanguage];
	if (language == WBCLanguageEnglish) {
		self.englishTableViewCell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else if (language == WBCLanguageDanish) {
		self.danishTableViewCell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
}

- (void)useLanguage:(WBCLanguage)language {
	[GVUserDefaults standardUserDefaults].language = @(language);
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self selectCurrentLanguage];
}

#pragma mark -
#pragma mark Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if (cell == self.englishTableViewCell) {
		[self useLanguage:WBCLanguageEnglish];
	} else if (cell == self.danishTableViewCell) {
		[self useLanguage:WBCLanguageDanish];
	}
}

@end
