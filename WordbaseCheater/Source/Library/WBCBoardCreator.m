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
}

#pragma mark -
#pragma mark Public Methods

- (void)createBoard:(void(^)(WBCBoard *board))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        CGRect cropRect = [self cropRect];
        UIImage *croppedImage = [self cropImage:self.image rect:cropRect];
        UIImage *preparedImage = [self prepareImage:croppedImage];
		UIImage *invertedImage = [self invertImage:preparedImage];
		NSArray *bombRects = [self bombRectsInImage:preparedImage];
		
		UIImage *imageWithoutBombs = [self removeTilesFromImage:preparedImage usingRects:bombRects removeTilesNotInRects:NO rectInset:-4.0f];
		UIImage *bombsOnlyImage = [self removeTilesFromImage:invertedImage usingRects:bombRects removeTilesNotInRects:YES rectInset:4.0f];
		
		[self saveImage:croppedImage name:@"cropped_image"];
		[self saveImage:preparedImage name:@"prepared_image"];
		[self saveImage:imageWithoutBombs name:@"no_bombs_image"];
		[self saveImage:bombsOnlyImage name:@"bombs_only_image"];
		
		WBCBoard *board = [self boardFromColoredImage:croppedImage imageWithoutBombs:imageWithoutBombs bombsOnlyImage:bombsOnlyImage];
		
		if (completion) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(board);
			});
		}
	});
}

#pragma mark -
#pragma mark Private Methods

- (WBCBoard *)boardFromColoredImage:(UIImage *)coloredImage imageWithoutBombs:(UIImage *)imageWithoutBombs bombsOnlyImage:(UIImage *)bombsOnlyImage {
	Tesseract *tesseract = [self createTesseractWithImage:imageWithoutBombs];
	[tesseract recognize];
	NSArray *tilesConfidences = [tesseract getConfidenceBySymbol];
	
	tesseract = [self createTesseractWithImage:bombsOnlyImage];
	[tesseract recognize];
	NSArray *bombsConfidences = [tesseract getConfidenceBySymbol];
	
	tesseract = nil;
	
	CGFloat preparedImageHeight = coloredImage.size.height;
	CGSize tileSize = [self tileSize];
	NSMutableArray *tiles = [NSMutableArray array];
	
	for (NSInteger c = 0; c < WBCBoardColumnsCount; c++) {
		for (NSInteger r = 0; r < WBCBoardRowsCount; r++) {
			CGRect tileRect = CGRectMake(c * tileSize.width, r * tileSize.height, tileSize.width, tileSize.height);
			CGPoint colorSamplePos = [self colorSamplePositionInTileRect:tileRect];
			
			UIColor *tileColor = [coloredImage WBCColorAtPosition:colorSamplePos];
			UIColor *preparedTileColor = [coloredImage WBCColorAtPosition:colorSamplePos];
			
			WBCIndexPath *indexPath = [WBCIndexPath indexPathForRow:r column:c];
			WBCTileOwner owner = [self ownerForColor:tileColor];
			BOOL isBomb = [self isBlackTileColor:preparedTileColor];
			CGFloat confidence = WBCTileUnkownConfidence;
			NSString *value = nil;
			
			NSArray *confidences = isBomb ? bombsConfidences : tilesConfidences;
			NSDictionary *confidenceBySymbol = [self confidenceBySymbolInTileRect:tileRect symbols:confidences imageHeight:preparedImageHeight];
			if (confidenceBySymbol) {
				value = confidenceBySymbol[@"text"];
				confidence = [confidenceBySymbol[@"confidence"] floatValue];
			}
			
			WBCTile *tile = [WBCTile new];
			tile.indexPath = indexPath;
			tile.bombTile = isBomb;
			tile.owner = owner;
			tile.value = value;
			tile.confidence = confidence;
			[tiles addObject:tile];
		}
	}
	
	return [WBCBoard boardWithTiles:tiles];
}

- (NSArray *)bombRectsInImage:(UIImage *)image {
	CGSize tileSize = [self tileSize];
	
	NSMutableArray *bombRects = [NSMutableArray new];
	
	for (NSInteger c = 0; c < WBCBoardColumnsCount; c++) {
		for (NSInteger r = 0; r < WBCBoardRowsCount; r++) {
			CGRect tileRect = CGRectMake(c * tileSize.width, r * tileSize.height, tileSize.width, tileSize.height);
			CGPoint colorSamplePos = [self colorSamplePositionInTileRect:tileRect];
			UIColor *preparedTileColor = [image WBCColorAtPosition:colorSamplePos];
			
			WBCIndexPath *indexPath = [WBCIndexPath indexPathForRow:r column:c];
			BOOL isBomb = [self isBlackTileColor:preparedTileColor];
			
			if (isBomb) {
				NSDictionary *bombRect = @{ @"indexPath": indexPath, @"rect": [NSValue valueWithCGRect:tileRect] };
				[bombRects addObject:bombRect];
			}
		}
	}
	
	return bombRects;
}

- (UIImage *)removeTilesFromImage:(UIImage *)image usingRects:(NSArray *)rects removeTilesNotInRects:(BOOL)removeNotInRects rectInset:(CGFloat)rectInset {
	CGMutablePathRef path = CGPathCreateMutable();
	for (NSDictionary *tile in rects) {
		CGRect rect = [tile[@"rect"] CGRectValue];
		CGRect expandedRect = CGRectInset(rect, rectInset, rectInset);
		CGPathAddPath(path, nil, CGPathCreateWithRect(expandedRect, nil));
	}
	
	CGRect canvasRect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
	UIGraphicsBeginImageContext(image.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	if (removeNotInRects) {
		CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
		CGContextFillRect(context, canvasRect);
		
		CGContextAddPath(context, path);
		CGContextClip(context);
		
		[image drawInRect:canvasRect];
	} else {
		[image drawInRect:canvasRect];
		
		CGContextAddPath(context, path);
		CGContextClip(context);
		
		CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
		CGContextFillRect(context, canvasRect);
	}
	
	UIImage *tilesRemovedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return tilesRemovedImage;
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

- (Tesseract *)createTesseractWithImage:(UIImage *)image pageSegmentationMode:(NSString *)pageSegmentationMode rect:(CGRect)rect {
#ifdef DEBUG
	NSLog(@"Recognizing with language '%@', page segmentation mode %@ and whitelist '%@'", self.traineddata, pageSegmentationMode, self.whitelist);
#endif
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

- (UIImage *)prepareImage:(UIImage *)image {
	return [self imageByApplyingFilter:[WBCPreparationFilter new] toImage:image];
}

- (UIImage *)invertImage:(UIImage *)image {
	return [self imageByApplyingFilter:[GPUImageColorInvertFilter new] toImage:image];
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
