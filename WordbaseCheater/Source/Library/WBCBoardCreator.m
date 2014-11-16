//
//  WBCBoardCreator.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 15/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import "WBCBoardCreator.h"
#import <GPUImage/GPUImage.h>
#import <TesseractOCR/TesseractOCR.h>
#import <TesseractOCR/Tesseract.h>
#import "WBCBoard.h"
#import "WBCTile.h"
#import "WBCIndexPath.h"
#import "WBCPreparationFilter.h"
#import "UIImage+WBCPicker.h"
#import "UIColor+WBCWordbase.h"

#define WBCBoardColumnsCount 10
#define WBCBoardRowsCount 13
#define WBCBlackColorThreshold 0.10f
#define WBCTileOwnerColorDifference 0.50f

@interface WBCBoardCreator () <TesseractDelegate>
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSString *traineddata;
@property (strong, nonatomic) NSString *whitelist;
@property (strong, nonatomic) UIImage *croppedImage;
@property (strong, nonatomic) UIImage *preparedImage;
@property (strong, nonatomic) UIImage *invertedImage;
@property (assign, nonatomic) CGRect cropRect;
@end

@implementation WBCBoardCreator

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithImage:(UIImage *)image traineddata:(NSString *)traineddata whitelist:(NSString *)whitelist {
    if (self = [super init]) {
        _image = image;
		_traineddata = traineddata;
		_whitelist = whitelist;
		_cropRect = CGRectNull;
    }
    
    return self;
}

+ (instancetype)boardCreatorWithImage:(UIImage *)image traineddata:(NSString *)traineddata whitelist:(NSString *)whitelist {
    return [[[self class] alloc] initWithImage:image traineddata:traineddata whitelist:whitelist];
}

- (void)dealloc {
    _image = nil;
	_traineddata = nil;
	_whitelist = nil;
    _croppedImage = nil;
    _preparedImage = nil;
	_invertedImage = nil;
}

#pragma mark -
#pragma mark Public Methods

- (void)createBoard:(void(^)(WBCBoard *board))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        CGRect cropRect = [self cropRect];
        self.croppedImage = [self cropImage:self.image rect:cropRect];
        self.preparedImage = [self prepareImage];
		self.invertedImage = [self invertImage];
		
		[self saveImage:self.invertedImage name:@"inverted_image"];
		
		Tesseract *tesseract = [self createTesseractWithImage:self.preparedImage];
		[tesseract recognize];
		NSArray *allConfidences = [tesseract getConfidenceBySymbol];
		tesseract = nil;
		WBCBoard *board = [self boardFromConfidences:allConfidences];
		
		if (completion) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(board);
			});
		}
	});
}

#pragma mark -
#pragma mark Private Methods

- (WBCBoard *)boardFromConfidences:(NSArray *)allConfidences {
	CGFloat preparedImageHeight = self.preparedImage.size.height;
	CGSize tileSize = [self tileSize];
	NSMutableArray *tiles = [NSMutableArray array];
	
	NSMutableArray *bombRects = [NSMutableArray new];
	
	for (NSInteger c = 0; c < WBCBoardColumnsCount; c++) {
		for (NSInteger r = 0; r < WBCBoardRowsCount; r++) {
			CGRect tileRect = CGRectMake(c * tileSize.width, r * tileSize.height, tileSize.width, tileSize.height);
			CGPoint colorSamplePos = [self colorSamplePositionInTileRect:tileRect];
			
			UIColor *tileColor = [self.croppedImage WBCColorAtPosition:colorSamplePos];
			UIColor *preparedTileColor = [self.preparedImage WBCColorAtPosition:colorSamplePos];
			
			WBCIndexPath *indexPath = [WBCIndexPath indexPathForRow:r column:c];
			WBCTileOwner owner = [self ownerForColor:tileColor];
			BOOL isBomb = [self isBlackTileColor:preparedTileColor];
			CGFloat confidence = WBCTileUnkownConfidence;
			NSString *value = nil;
			
			if (isBomb) {
				// It's a bomb, we'll handle it later as characters recognized on bombs in the prepared image
				// is often incorrect.
				// Inset tile a bit to remove any weird borders
				CGRect insettedTile = CGRectInset(tileRect, 3, 3);
				NSDictionary *bombRect = @{ @"indexPath": indexPath,
											@"rect": [NSValue valueWithCGRect:insettedTile] };
				[bombRects addObject:bombRect];
			} else {
				// It's not a bomb, so we'll create a tile right away
				NSDictionary *confidenceBySymbol = [self confidenceBySymbolInTileRect:tileRect symbols:allConfidences imageHeight:preparedImageHeight];
				value = confidenceBySymbol[@"text"];
				confidence = [confidenceBySymbol[@"confidence"] floatValue];
				
				WBCTile *tile = [WBCTile new];
				tile.indexPath = indexPath;
				tile.bombTile = isBomb;
				tile.owner = owner;
				tile.value = value;
				tile.confidence = confidence;
				[tiles addObject:tile];
			}
		}
	}
	
	NSArray *bombTiles = [self bombTilesInRects:bombRects];
	[tiles addObjectsFromArray:bombTiles];
	
	return [WBCBoard boardWithTiles:tiles];
}

- (NSArray *)bombTilesInRects:(NSArray *)bombRects {
	NSMutableArray *rects = [NSMutableArray new];
	for (NSDictionary *bombRect in bombRects) {
		[rects addObject:bombRect[@"rect"]];
	}
	
	UIImage *linearBombsImage = [self linearTilesFromImage:self.invertedImage rects:rects];
	CGFloat linearBombsImageHeight = linearBombsImage.size.height;
	[self saveImage:linearBombsImage name:@"linear_bombs"];
	
	Tesseract *tesseract = [self createTesseractForLineRecognitionWithImage:linearBombsImage];
	[tesseract recognize];
	NSArray *allConfidences = [tesseract getConfidenceBySymbol];
	tesseract = nil;
	
	NSMutableArray *tiles = [NSMutableArray new];
	
	NSUInteger count = [bombRects count];
	for (NSUInteger i = 0; i < count; i++) {
		NSDictionary *bombRect = bombRects[i];
		CGRect rect = [bombRect[@"rect"] CGRectValue];
		
		CGFloat linearRectX = 0.0f;
		for (NSUInteger j = 0; j < i; j++) {
			linearRectX += CGRectGetWidth([bombRects[j][@"rect"] CGRectValue]);
		}
		
		CGRect linearRect = CGRectZero;
		linearRect.size = rect.size;
		linearRect.origin.x = linearRectX;
		
		WBCIndexPath *indexPath = bombRect[@"indexPath"];
		NSString *value = nil;
		CGFloat confidence = WBCTileUnkownConfidence;
		
		NSDictionary *confidenceBySymbol = [self confidenceBySymbolInTileRect:linearRect symbols:allConfidences imageHeight:linearBombsImageHeight];
		if (confidenceBySymbol) {
			value = confidenceBySymbol[@"text"];
			confidence = [confidenceBySymbol[@"confidence"] floatValue];
		}

		WBCTile *tile = [WBCTile new];
		tile.indexPath = indexPath;
		tile.bombTile = YES;
		tile.owner = WBCTileOwnerUnknown;
		tile.value = value;
		tile.confidence = confidence;
		[tiles addObject:tile];
	}
	
	return tiles;
}

- (UIImage *)linearTilesFromImage:(UIImage *)image rects:(NSArray *)rects {
	CGFloat totalWidth = 0.0f;
	CGFloat height = 0.0f;
	
	for (NSValue *value in rects) {
		CGRect rect = [value CGRectValue];
		totalWidth += CGRectGetWidth(rect);
		height = MAX(height, CGRectGetHeight(rect));
	}
	
	CGSize imageSize = CGSizeMake(totalWidth, height);
	UIGraphicsBeginImageContext(imageSize);
	
	CGFloat nextX = 0.0f;
	for (NSValue *value in rects) {
		CGRect rect = [value CGRectValue];
		UIImage *tileImage = [self cropImage:image rect:rect];
		CGRect drawRect = CGRectMake(nextX, 0, CGRectGetWidth(rect), CGRectGetHeight(rect));
		[tileImage drawInRect:drawRect];
		nextX += CGRectGetWidth(rect);
	}
	
	UIImage *linearImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return linearImage;
}

- (void)saveImage:(UIImage *)image name:(NSString *)name {
	NSData *imageData = UIImagePNGRepresentation(image);
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsPath = [paths objectAtIndex:0];
	NSString *filename = [NSString stringWithFormat:@"%@.png", name];
	NSString *filePath = [documentsPath stringByAppendingPathComponent:filename];
	[imageData writeToFile:filePath atomically:YES];
}

- (CGPoint)colorSamplePositionInTileRect:(CGRect)tileRect {
	// Make sure we are not dealing with weird edges when taking the color sample,
	// go approximately half into the tile
	CGPoint colorSamplePos = tileRect.origin;
	colorSamplePos.x += CGRectGetWidth(tileRect) * 0.50f;
	return colorSamplePos;
}

- (NSDictionary *)confidenceBySymbolInTileRect:(CGRect)tileRect symbols:(NSArray *)symbols imageHeight:(CGFloat)imageHeight {
	NSPredicate *boxPredicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *obj, NSDictionary *bindings) {
		CGRect box = [obj[@"boundingbox"] CGRectValue];
		
		// Tesseract has (0, 0) in bottom left corner but UIKit has (0, 0) in top left corner.
		// We need to flip the coordinates.
		CGRect flippedBox = CGRectMake(CGRectGetMinX(box),
									   imageHeight - CGRectGetMaxY(box),
									   CGRectGetWidth(box),
									   CGRectGetHeight(box));
		
		return CGRectContainsPoint(tileRect, flippedBox.origin);
	}];
	
	NSArray *results = [symbols filteredArrayUsingPredicate:boxPredicate];
	return [results firstObject];
}

- (UIImage *)cropImage:(UIImage *)image rect:(CGRect)rect {
	CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
	UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
	CGImageRelease(imageRef);
	return croppedImage;
}

- (BOOL)isBlackTileColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat red = components[0];
    CGFloat green = components[1];
    CGFloat blue = components[2];
    return (red <= WBCBlackColorThreshold && green <= WBCBlackColorThreshold && blue <= WBCBlackColorThreshold);
}

- (WBCTileOwner)ownerForColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat red = components[0];
    CGFloat blue = components[2];
    
    WBCTileOwner owner = WBCTileOwnerUnknown;
    if ((red - blue) > WBCTileOwnerColorDifference) {
        owner = WBCTileOwnerOrange;
    } else if ((blue - red) > WBCTileOwnerColorDifference) {
        owner = WBCTileOwnerBlue;
    }
    
    return owner;
}

- (CGSize)tileSize {
	CGFloat width = CGRectGetWidth(self.cropRect);
	CGFloat height = CGRectGetHeight(self.cropRect);
	return CGSizeMake(roundf(width / WBCBoardColumnsCount), roundf(height / WBCBoardRowsCount));
}

- (NSArray *)boardRepresentationFromString:(NSString *)text {
    NSMutableArray *board = [NSMutableArray new];
    NSArray *lines = [text componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSUInteger length = [line length];
        if (length > 0) {
            NSMutableArray *characters = [NSMutableArray new];
            for (NSInteger c = 0; c < length; c++) {
                NSString *character = [NSString stringWithFormat:@"%c", [line characterAtIndex:c]];
                [characters addObject:character];
            }
            
            [board addObject:characters];
        }
    }
    
    return board;
}

- (CGRect)cropRect {
	if (CGRectEqualToRect(_cropRect, CGRectNull)) {
		CGRect rect = CGRectZero;
		rect.origin.y = [self minimumYForBoard];
		rect.size.width = self.image.size.width;
		rect.size.height = self.image.size.height - [self minimumYForBoard];
		_cropRect = rect;
	}
	
	return _cropRect;
}

- (Tesseract *)createTesseractWithImage:(UIImage *)image {
	return [self createTesseractWithImage:image pageSegmentationMode:@"6" rect:CGRectNull];
}

- (Tesseract *)createTesseractForSingleCharacterRecognitionWithImage:(UIImage *)image inRect:(CGRect)rect {
	return [self createTesseractWithImage:image pageSegmentationMode:@"6" rect:rect];
}

- (Tesseract *)createTesseractForLineRecognitionWithImage:(UIImage *)image {
	return [self createTesseractWithImage:image pageSegmentationMode:@"7" rect:CGRectNull];
}

- (Tesseract *)createTesseractWithImage:(UIImage *)image pageSegmentationMode:(NSString *)pageSegmentationMode rect:(CGRect)rect {
	Tesseract *tesseract = [[Tesseract alloc] initWithLanguage:self.traineddata];
	tesseract.delegate = self;
	[tesseract setVariableValue:self.whitelist forKey:@"tessedit_char_whitelist"];
	[tesseract setVariableValue:pageSegmentationMode forKey:@"tessedit_pageseg_mode"];
	[tesseract setVariableValue:@"1" forKey:@"tessedit_single_match"];
	[tesseract setImage:image];
	if (!CGRectEqualToRect(rect, CGRectNull)) {
		[tesseract setRect:rect];
	}
	return tesseract;
}

- (UIImage *)prepareImage {
	return [self imageByApplyingFilter:[WBCPreparationFilter new] toImage:self.croppedImage];
}

- (UIImage *)invertImage {
	return [self imageByApplyingFilter:[GPUImageColorInvertFilter new] toImage:self.preparedImage];
}

- (UIImage *)imageByApplyingFilter:(GPUImageOutput *)filter toImage:(UIImage *)image {
	NSAssert([filter isKindOfClass:[GPUImageFilterGroup class]] || [filter isKindOfClass:[GPUImageFilter class]], @"Filter must be either an instance of GPUImageFilterGroup or GPUImageFilter");
	
	GPUImagePicture *picture = [[GPUImagePicture alloc] initWithImage:image];
	
	if ([filter isKindOfClass:[GPUImageFilterGroup class]]) {
		[picture addTarget:(GPUImageFilterGroup *)filter];
	} else if ([filter isKindOfClass:[GPUImageFilter class]]) {
		[picture addTarget:(GPUImageFilter *)filter];
	}
	
	
	[filter useNextFrameForImageCapture];
	[picture processImage];
	
	return [filter imageFromCurrentFramebuffer];
}

- (CGFloat)minimumYForBoard {
	CGImageRef imageRef = [self.image CGImage];
	NSUInteger width = CGImageGetWidth(imageRef);
	NSUInteger height = CGImageGetHeight(imageRef);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
	NSUInteger bytesPerPixel = 4;
	NSUInteger bytesPerRow = bytesPerPixel * width;
	NSUInteger bitsPerComponent = 8;
	
	CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
	CGContextRelease(context);
	
	CGFloat boardStartY = 0.0f;
	
	CGFloat lightRed, lightGreen, lightBlue, lightAlpha;
	CGFloat darkRed, darkGreen, darkBlue, darkAlpha;
	
	[[UIColor WBCWordbaseLightOrange] getRed:&lightRed green:&lightGreen blue:&lightBlue alpha:&lightAlpha];
	[[UIColor WBCWordbaseDarkOrange] getRed:&darkRed green:&darkGreen blue:&darkBlue alpha:&darkAlpha];
	
	for (int y = 0; y < height; y++) {
		BOOL darkOrangeFound = NO;
		BOOL lightOrangeFound = NO;
		BOOL shouldBreak = NO;
		for (int x = 0; x < width; x++) {
			NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
			
			CGFloat red   = (rawData[byteIndex]     * 1.0f) / 255.0f;
			CGFloat green = (rawData[byteIndex + 1] * 1.0f) / 255.0f;
			CGFloat blue  = (rawData[byteIndex + 2] * 1.0f) / 255.0f;
			CGFloat alpha = (rawData[byteIndex + 3] * 1.0f) / 255.0f;
			
			if (red == lightRed && green == lightGreen && blue == lightBlue && alpha == lightAlpha) {
				lightOrangeFound = YES;
			} else if (red == darkRed && green == darkGreen && blue == darkBlue && alpha == darkAlpha) {
				darkOrangeFound = YES;
			}
			
			if (darkOrangeFound && lightOrangeFound) {
				boardStartY = y;
				shouldBreak = YES;
				break;
			}
		}
		
		if (shouldBreak) {
			break;
		}
	}
	
	free(rawData);
	
	return boardStartY;
}

#pragma mark -
#pragma mark Tesseract Delegate

- (BOOL)shouldCancelImageRecognitionForTesseract:(Tesseract *)tesseract {
	return NO;
}

@end
