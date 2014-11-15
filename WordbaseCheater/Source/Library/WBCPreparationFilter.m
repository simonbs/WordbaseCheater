//
//  WBCPreparationFilter.m
//  WordbaseCheater
//
//  Created by Simon Støvring on 14/12/13.
//  Copyright (c) 2013 Loïs Di Qual. All rights reserved.
//

#import "WBCPreparationFilter.h"

#define WBCBrightness 0.20f
#define WBCContrast 2.0f

@implementation WBCPreparationFilter

#pragma mark -
#pragma mark Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        GPUImageGrayscaleFilter *grayscaleFilter = [GPUImageGrayscaleFilter new];
        
        GPUImageBrightnessFilter *brightnessFilter = [GPUImageBrightnessFilter new];
        brightnessFilter.brightness = WBCBrightness;
        
        GPUImageContrastFilter *contrastFilter = [GPUImageContrastFilter new];
        contrastFilter.contrast = WBCContrast;
        
        [grayscaleFilter addTarget:brightnessFilter];
        [brightnessFilter addTarget:contrastFilter];
        
        self.initialFilters = @[ grayscaleFilter ];
        self.terminalFilter = contrastFilter;
    }
    
    return self;
}

@end
