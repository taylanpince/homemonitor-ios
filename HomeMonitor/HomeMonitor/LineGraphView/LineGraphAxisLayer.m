//
//  LineGraphAxisLayer.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-28.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphAxisLayer.h"
#import "LineGraphUtils.h"
#import "LineGraphAxisAnimator.h"
#import "CALayer+LineGraphAnimation.h"

static NSUInteger TICK_PADDING = 2;



@interface LineGraphAxisLayer () {
    
}

@property (nonatomic) NSArray *currentTickValues;
@property (nonatomic) NSArray *currentLabels;
@property (nonatomic, strong) CAShapeLayer *tickLayer;

@end

@implementation LineGraphAxisLayer

- (id)init {
    self = [super init];
    
    if (self) {
        self.masksToBounds = TRUE;
        self.fillColor = nil;
        self.axisPosition = kLineGraphAxisPositionNone;
        
        self.textLayers = [NSMutableArray array];
        self.currentTickValues = [NSArray array];
        self.currentLabels = [NSArray array];
        self.currentPlotArea = CGRectZero;
        self.currentValueRange = CGRectZero;
        self.currentTickLength = 0;
        
        self.tickLayer = [CAShapeLayer layer];
        self.tickLayer.masksToBounds = TRUE;
        [self addSublayer:self.tickLayer];
    }
    
    return self;
}

- (id<CAAction>)actionForKey:(NSString *)event {
    return nil;
}

- (BOOL)isHorizontal {
    return (self.axisPosition == kLineGraphAxisPositionTop || self.axisPosition == kLineGraphAxisPositionBottom);
}

- (CGMutablePathRef)pathForPlotArea:(CGRect)plotArea valueRange:(CGRect)valueRange tickValues:(NSArray *)tickValues {
    if (self.axisPosition == kLineGraphAxisPositionNone)
        return nil;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    if ([self isHorizontal]) {
        CGPathMoveToPoint(path, NULL, CGRectGetMinX(plotArea), self.axisPosition == kLineGraphAxisPositionTop ? CGRectGetMaxY(self.bounds) - 1 : 1);
        CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(plotArea), self.axisPosition == kLineGraphAxisPositionTop ? CGRectGetMaxY(self.bounds) - 1 : 1);
    } else {
        
        CGPathMoveToPoint(path, NULL, self.axisPosition == kLineGraphAxisPositionLeft ? CGRectGetMaxX(self.bounds)-1 : 1, CGRectGetMinY(plotArea));
        CGPathAddLineToPoint(path, NULL, self.axisPosition == kLineGraphAxisPositionLeft ? CGRectGetMaxX(self.bounds)-1 : 1, CGRectGetMaxY(plotArea));
    }
    
    
    return path;
}

- (CGMutablePathRef)tickPathForPlotArea:(CGRect)plotArea valueRange:(CGRect)valueRange tickValues:(NSArray *)tickValues {
    CGMutablePathRef path = CGPathCreateMutable();
    
    for (NSNumber *tickNumber in tickValues) {
        
        if ([self isHorizontal]) {
            float x = OffsetXForValue([tickNumber floatValue], plotArea, valueRange);
            
            if (x >= 0 && x <= CGRectGetWidth(plotArea)) {
                
                if (self.axisPosition == kLineGraphAxisPositionTop) {
                    CGPathMoveToPoint(path, NULL, x+1, CGRectGetMaxY(self.bounds) - self.tickLength - 1);
                    CGPathAddLineToPoint(path, NULL, x+1, CGRectGetMaxY(self.bounds) - 1);
                } else {
                    CGPathMoveToPoint(path, NULL, x+1, 1);
                    CGPathAddLineToPoint(path, NULL, x+1, self.tickLength+1);
                }
            }
        } else {
            float y = OffsetYForValue([tickNumber floatValue], plotArea, valueRange);
            
            if (y >= 0 && y <= CGRectGetHeight(plotArea)) {
                if (self.axisPosition == kLineGraphAxisPositionLeft) {
                    CGPathMoveToPoint(path, NULL, CGRectGetMaxX(self.bounds) - self.tickLength - 1, y+1);
                    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(self.bounds) - 1, y+1);
                } else {
                    CGPathMoveToPoint(path, NULL, 1, y+1);
                    CGPathAddLineToPoint(path, NULL, self.tickLength + 1, y+1);
                }
            }
        }
    }
    
    return path;
}

- (BOOL)checkValue:(float)floatValue withinRange:(CGRect)valueRange {
    if ([self isHorizontal]) {
        return (floatValue >= CGRectGetMinX(valueRange) && floatValue <= CGRectGetMaxX(valueRange));
    } else {
        return (floatValue >= CGRectGetMinY(valueRange) && floatValue <= CGRectGetMaxY(valueRange));
    }
}

- (float)calculateLabelPositionForX:(float)value withSize:(CGSize)size {
    switch (self.xAlignment) {
        case kLineGraphXAlignLeft:
            return value + 2;
        case kLineGraphXAlignRight:
            return value - size.width - 2;
        default:
            return value - size.width / 2;
    }
}

- (float)calculateLabelPositionForY:(float)value withSize:(CGSize)size {
    return value - size.height / 2;
}

- (CGRect)frameForValue:(float)floatValue label:(NSString *)label plotArea:(CGRect)plotArea valueRange:(CGRect)valueRange {
    CGRect labelRect = [label boundingRectWithSize:CGSizeMake(0,0) options:NSStringDrawingUsesDeviceMetrics attributes:@{NSFontAttributeName:self.labelFont} context:nil];
    
    CGFloat labelPositionX, labelPositionY;
    
    if ([self isHorizontal]) {
        float x = PlotXForValue(floatValue, plotArea, valueRange);
        
        labelPositionX = [self calculateLabelPositionForX:x withSize:labelRect.size];
        
        if (self.axisPosition == kLineGraphAxisPositionTop) {
            labelPositionY = CGRectGetMaxY(self.bounds) - labelRect.size.height - labelRect.origin.y - TICK_PADDING - (self.xAlignment == kLineGraphXAlignCenter ? self.tickLength : 0) - 1;
        } else {
            labelPositionY = TICK_PADDING + (self.xAlignment == kLineGraphXAlignCenter ? self.tickLength : 0) + labelRect.origin.y + 1;
        }
    } else {
        float y = PlotYForValue(floatValue, plotArea, valueRange);
        
        if (self.axisPosition == kLineGraphAxisPositionLeft) {
            labelPositionX = CGRectGetMaxX(self.bounds) - self.tickLength - TICK_PADDING - labelRect.size.width - 1;
        } else {
            labelPositionX = self.tickLength + TICK_PADDING + 1;
        }
        
        labelPositionY = [self calculateLabelPositionForY:y withSize:labelRect.size];
    }
    
    return CGRectMake(labelPositionX, labelPositionY, labelRect.size.width, labelRect.size.height);
}

- (void)drawForPlotArea:(CGRect)plotArea
             valueRange:(CGRect)valueRange
                 bounds:(CGRect)bounds
             tickValues:(NSArray *)tickValues
                 labels:(NSArray *)labels
               duration:(CFTimeInterval)duration {
    
    self.tickLayer.strokeColor = self.strokeColor;
    
    CGRect axisFrame = self.frame;
    CGRect frameNew = CGRectZero;
    CGRect tickFrameNew = CGRectZero;
    
    LineGraphAxisAnimator *animator;
    
    if (duration > 0 && self.animator) {
        animator = self.animator;
    } else {
        animator = [[LineGraphAxisAnimator alloc] init];
    }
    
    if (self.axisPosition == kLineGraphAxisPositionTop) {
        frameNew = CGRectMake(0,0,CGRectGetWidth(bounds),CGRectGetMinY(plotArea) + 1);
        tickFrameNew = CGRectMake(CGRectGetMinX(plotArea)-1,0,CGRectGetWidth(plotArea)+2,CGRectGetHeight(frameNew));
    }
    else if (self.axisPosition == kLineGraphAxisPositionBottom) {
        frameNew  = CGRectMake(0,CGRectGetMaxY(plotArea)-1,CGRectGetWidth(bounds),CGRectGetHeight(bounds)-CGRectGetMaxY(plotArea)+1);
        tickFrameNew = CGRectMake(CGRectGetMinX(plotArea)-1,0,CGRectGetWidth(plotArea)+2,CGRectGetHeight(frameNew));
    }
    else if (self.axisPosition == kLineGraphAxisPositionLeft) {
        frameNew = CGRectMake(0,0,CGRectGetMinX(plotArea)+1,CGRectGetHeight(bounds));
        tickFrameNew = CGRectMake(0,CGRectGetMinY(plotArea)-1,CGRectGetWidth(frameNew),CGRectGetHeight(plotArea)+2);
    }
    else if (self.axisPosition == kLineGraphAxisPositionRight) {
        frameNew = CGRectMake(CGRectGetMaxX(plotArea)-1,0,CGRectGetWidth(bounds)-CGRectGetMaxX(plotArea)+1,CGRectGetHeight(bounds));
        tickFrameNew = CGRectMake(0,CGRectGetMinY(plotArea)-1,CGRectGetWidth(frameNew),CGRectGetHeight(plotArea)+2);
    }
    
    self.frame = frameNew;
    
    CGPathRef path = [self pathForPlotArea:plotArea valueRange:valueRange tickValues:tickValues];
    CGPathRef tickPath = [self tickPathForPlotArea:plotArea valueRange:valueRange tickValues:tickValues];
    
    if (duration > 0) {
        if (!CGRectEqualToRect(axisFrame, CGRectZero) && !CGRectEqualToRect(frameNew, CGRectZero)) {
            [self animateFromFrame:axisFrame toFrame:frameNew duration:duration path:path];
            [animator animateTicksForLayer:self toPath:tickPath toFrame:tickFrameNew tickValues:tickValues plotArea:plotArea valueRange:valueRange duration:duration];
        } else {
            self.path = path;
        }
    } else {
        self.path = path;
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:TRUE];
    self.tickLayer.frame = tickFrameNew;
    self.tickLayer.path = tickPath;
    [CATransaction commit];
    
    CGPathRelease(path);
    CGPathRelease(tickPath);
    
    NSMutableArray *labelFrames = [NSMutableArray array];
    BOOL hasPlacedLabel = FALSE;
    float lastMax = 0;
    
    for (NSInteger i = 0; i < labels.count; i++) {
        if (i >= tickValues.count)
            break;
        
        float tickFloatValue = [[tickValues objectAtIndex:i] floatValue];
        
        NSString *labelString = [labels objectAtIndex:i];
        
        CGRect frame = [self frameForValue:tickFloatValue label:labelString plotArea:plotArea valueRange:valueRange];
        
        CGFloat primaryPosition;
        
        if ([self isHorizontal]) {
            primaryPosition = CGRectGetMinX(frame);
        } else {
            primaryPosition = CGRectGetMaxY(frame);
        }
        
        if (hasPlacedLabel && (([self isHorizontal] && primaryPosition <= lastMax) || (![self isHorizontal] && primaryPosition >= lastMax))) {
            [labelFrames addObject:[NSValue valueWithCGRect:CGRectZero]];
        } else {
            [labelFrames addObject:[NSValue valueWithCGRect:frame]];
            if ([self checkValue:tickFloatValue withinRange:valueRange]) {
                lastMax = [self isHorizontal] ? CGRectGetMaxX(frame) : CGRectGetMinY(frame);
                hasPlacedLabel = TRUE;
            }
        }
    }
    
    [animator animateAxisLayer:self
                    tickValues:tickValues
                        labels:labels
                      plotArea:plotArea
                    valueRange:valueRange
                      toFrames:labelFrames
                      duration:duration];
    
    self.currentTickValues = [tickValues copy];
    self.currentLabels = [labels copy];
    self.currentPlotArea = plotArea;
    self.currentValueRange = valueRange;
    self.currentTickLength = self.tickLength;
}

@end
