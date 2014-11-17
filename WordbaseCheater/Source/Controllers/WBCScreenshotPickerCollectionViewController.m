//
//  WBCScreenshotPickerCollectionViewController.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 17/11/14.
//  Copyright (c) 2014 SimonBS. All rights reserved.
//

#import "WBCScreenshotPickerCollectionViewController.h"
#import "WBCScreenshotPickerCollectionViewCell.h"
@import Photos;

static NSString* WBCScreenshotPickerCellIdentifier = @"ScreenshotPickerCell";

@interface WBCScreenshotPickerCollectionViewController () <PHPhotoLibraryChangeObserver>
@property (strong, nonatomic) PHFetchResult *fetchResult;
@property (strong, nonatomic) NSMutableIndexSet *screenshotIndices;
@property (assign, nonatomic, getter=isPhotoLibraryObserverRegistered) BOOL photoLibraryObserverRegistered;
@end

@implementation WBCScreenshotPickerCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

#pragma mark -
#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.collectionView registerClass:[WBCScreenshotPickerCollectionViewCell class] forCellWithReuseIdentifier:WBCScreenshotPickerCellIdentifier];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
    [self loadScreenshots];
}

- (void)dealloc {
    if (self.isPhotoLibraryObserverRegistered) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

#pragma mark -
#pragma mark Private Methods

- (void)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(screenshotPickerCollectionViewControllerDidCancel:)]) {
        [self.delegate screenshotPickerCollectionViewControllerDidCancel:self];
    }
}

- (void)loadScreenshots {
    self.screenshotIndices = [NSMutableIndexSet new];
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
//        CGFloat screenScale = [[UIScreen mainScreen] nativeScale];
        CGSize screenSize = [UIScreen mainScreen].nativeBounds.size;
//        screenSize.width *= screenScale;
//        screenSize.height *= screenScale;
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
        PHFetchOptions *options = [PHFetchOptions new];
        options.sortDescriptors = @[ sortDescriptor ];
        
        self.fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
        [self.fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            NSLog(@"%@", asset);
            
            if (asset.pixelWidth == screenSize.width && asset.pixelHeight == screenSize.height) {
                NSLog(@"Is screenshot");
                [self.screenshotIndices addIndex:idx];
            }
        }];
        
        if (!self.isPhotoLibraryObserverRegistered) {
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
            self.photoLibraryObserverRegistered = YES;
        }
    }];
}

#pragma mark -
#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WBCScreenshotPickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:WBCScreenshotPickerCellIdentifier forIndexPath:indexPath];
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.screenshotIndices count];
}

#pragma mark -
#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(screenshotPickerCollectionViewController:didPickScreenshot:)]) {
        [self.delegate screenshotPickerCollectionViewController:self didPickScreenshot:nil];
    }
}

#pragma mark -
#pragma mark PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    
}

@end
