//
//  LineGraphAxisAnimator.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-29.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphAxisAnimator.h"
#import "LineGraphUtils.h"
#import "CALayer+LineGraphAnimation.h"

@interface LineGraphAxisAnimator ()

/* Should the label layer be re-used or slated for deletion? */
- (BOOL)shouldUseTextLayer:(CATextLayer *)textLayer forLabel:(NSString *)labelString;
- (BOOL)shouldUseTextLayer:(CATextLayer *)textLayer withFont:(UIFont *)font;

/* Do we need to bother calcuating the frame for the new label based on where it would
 have been in the original value range? */
- (BOOL)shouldCalculateInsertionFrame;

/* Do we need to bother calculating the frame for the label that will no longer be present
 in the new value range? */
- (BOOL)shouldCalculateRemovalFrame;

@end

@implementation LineGraphAxisAnimator

- (CATextLayer *)textLayer {
    CATextLayer *textLayer = [CATextLayer layer];
    
    NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"onOrderIn",
                                       [NSNull null], @"onOrderOut",
                                       [NSNull null], @"sublayers",
                                       [NSNull null], @"contents",
                                       [NSNull null], @"bounds",
                                       [NSNull null], @"position",
                                       nil];
    textLayer.actions = newActions;
    textLayer.contentsScale = [[UIScreen mainScreen] scale];
    
    return textLayer;
}

- (BOOL)shouldUseTextLayer:(CATextLayer *)textLayer forLabel:(NSString *)labelString {
    return YES;
}

- (BOOL)shouldUseTextLayer:(CATextLayer *)textLayer withFont:(UIFont *)font {
    return YES;
}

- (BOOL)shouldCalculateInsertionFrame {
    return NO;
}

- (BOOL)shouldCalculateRemovalFrame {
    return NO;
}

- (void)animateTextLayer:(CATextLayer *)textLayer toFrame:(CGRect)frame duration:(CFTimeInterval)duration {
    textLayer.frame = frame;
}

- (void)removeTextLayer:(CATextLayer *)textLayer toFrame:(CGRect)frame duration:(CFTimeInterval)duration {
    [textLayer removeFromSuperlayer];
}

- (void)animateTicksForLayer:(LineGraphAxisLayer *)axisLayer
                      toPath:(CGPathRef)path
                     toFrame:(CGRect)frame
                  tickValues:(NSArray *)tickValues
                    plotArea:(CGRect)plotArea
                  valueRange:(CGRect)valueRange
                    duration:(CFTimeInterval)duration {
    
    CGMutablePathRef startPath = CGPathCreateMutable();
    CGMutablePathRef endPath = CGPathCreateMutable();
    
    for (NSNumber *tickNumber in tickValues) {
        
        CGFloat tickFloatValue = tickNumber.floatValue;
        
        if ([axisLayer isHorizontal]) {
            float origX = OffsetXForValue(tickFloatValue, axisLayer.currentPlotArea, axisLayer.currentValueRange);
            float newX = OffsetXForValue(tickFloatValue, plotArea, valueRange);
            
            if ((origX >= 0 && origX <= CGRectGetWidth(axisLayer.currentPlotArea)) ||
                (newX >= 0 && newX <= CGRectGetWidth(plotArea))) {
                
                if (axisLayer.axisPosition == kLineGraphAxisPositionTop) {
                    CGPathMoveToPoint(startPath, NULL, origX+1, CGRectGetMaxY(axisLayer.tickLayer.bounds) - axisLayer.currentTickLength - 1);
                    CGPathAddLineToPoint(startPath, NULL, origX+1, CGRectGetMaxY(axisLayer.tickLayer.bounds) - 1);
                    
                    CGPathMoveToPoint(endPath, NULL, newX+1, CGRectGetMaxY(frame) - axisLayer.tickLength - 1);
                    CGPathAddLineToPoint(endPath, NULL, newX+1, CGRectGetMaxY(frame) - 1);
                } else {
                    CGPathMoveToPoint(startPath, NULL, origX+1, 1);
                    CGPathAddLineToPoint(startPath, NULL, origX+1, axisLayer.currentTickLength+1);
                    
                    CGPathMoveToPoint(endPath, NULL, newX+1, 1);
                    CGPathAddLineToPoint(endPath, NULL, newX+1, axisLayer.tickLength+1);
                }
            }
        } else {
            float origY = OffsetYForValue(tickFloatValue, axisLayer.currentPlotArea, axisLayer.currentValueRange);
            float newY = OffsetYForValue(tickFloatValue, plotArea, valueRange);
            
            if ((origY >= 0 && origY <= CGRectGetHeight(axisLayer.currentPlotArea)) ||
                (newY >= 0 && newY <= CGRectGetHeight(plotArea))) {
                
                if (axisLayer.axisPosition == kLineGraphAxisPositionLeft) {
                    CGPathMoveToPoint(startPath, NULL, CGRectGetMaxX(axisLayer.tickLayer.bounds) - axisLayer.currentTickLength - 1, origY+1);
                    CGPathAddLineToPoint(startPath, NULL, CGRectGetMaxX(axisLayer.tickLayer.bounds) - 1, origY+1);
                    
                    CGPathMoveToPoint(endPath, NULL, CGRectGetMaxX(frame) - axisLayer.tickLength - 1, newY+1);
                    CGPathAddLineToPoint(endPath, NULL, CGRectGetMaxX(frame) - 1, newY+1);
                } else {
                    CGPathMoveToPoint(startPath, NULL, 1, origY+1);
                    CGPathAddLineToPoint(startPath, NULL, axisLayer.currentTickLength+1, origY+1);

                    CGPathMoveToPoint(endPath, NULL, 1, newY+1);
                    CGPathAddLineToPoint(endPath, NULL, axisLayer.tickLength+1, newY+1);

                }
            }
        }
    }
    
    axisLayer.tickLayer.path = startPath;
    [axisLayer.tickLayer animateFromFrame:axisLayer.tickLayer.frame toFrame:frame duration:duration path:endPath];
    
    CGPathRelease(startPath);
    CGPathRelease(endPath);
}

- (void)animateAxisLayer:(LineGraphAxisLayer *)axisLayer
              tickValues:(NSArray *)tickValues
                  labels:(NSArray *)labels
                plotArea:(CGRect)plotArea
              valueRange:(CGRect)valueRange
                toFrames:(NSArray *)labelFrames
                duration:(CFTimeInterval)duration {
    
    NSMutableArray *newLayers = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < labels.count; i++) {
        if (i >= tickValues.count)
            break;
        
        NSNumber *tickNumber = [tickValues objectAtIndex:i];
        float tickFloatValue = tickNumber.floatValue;
        NSString *labelString = [labels objectAtIndex:i];
        CGRect newFrame = [(NSValue *)[labelFrames objectAtIndex:i] CGRectValue];
        
        NSUInteger originalIndex = [axisLayer.currentTickValues indexOfObject:tickNumber];
        
        CATextLayer *textLayer = nil;
        
        if (originalIndex != NSNotFound && originalIndex < axisLayer.textLayers.count) {
            id textLayerObject = [axisLayer.textLayers objectAtIndex:originalIndex];
            if (![textLayerObject isEqual:[NSNull null]]
                && [self shouldUseTextLayer:textLayerObject withFont:axisLayer.labelFont]
                && [self shouldUseTextLayer:textLayerObject forLabel:labelString]) {
                
                textLayer = textLayerObject;
            }
        }
        
        if (!CGRectEqualToRect(newFrame, CGRectZero) && [axisLayer checkValue:[tickNumber floatValue] withinRange:valueRange]) {
            if (textLayer == nil) {
                textLayer = [self textLayer];
                
                if ([self shouldCalculateInsertionFrame] && duration > 0) {
                    textLayer.frame = [axisLayer frameForValue:tickFloatValue label:labelString plotArea:axisLayer.currentPlotArea valueRange:axisLayer.currentValueRange];
                }
            }
            
            textLayer.string = labelString;
            
            CGFontRef font = CGFontCreateWithFontName((CFStringRef)axisLayer.labelFont.fontName);
            textLayer.font = font;
            CGFontRelease(font);
            
            textLayer.fontSize = axisLayer.labelFont.pointSize;
            textLayer.foregroundColor = axisLayer.strokeColor;

            [axisLayer addSublayer:textLayer];

            [self animateTextLayer:textLayer toFrame:newFrame duration:duration];
            
            [newLayers addObject:textLayer];
        } else {
            if (textLayer) {
                [self removeTextLayer:textLayer toFrame:newFrame duration:duration];
                [axisLayer.textLayers replaceObjectAtIndex:originalIndex withObject:[NSNull null]];
            }
            
            [newLayers addObject:[NSNull null]];
        }
    }
    
    for (NSUInteger i = 0; i < axisLayer.textLayers.count; i++) {
        id textLayer = [axisLayer.textLayers objectAtIndex:i];

        if ([textLayer isEqual:[NSNull null]] == FALSE && [newLayers indexOfObjectIdenticalTo:textLayer] == NSNotFound) {
            CGRect endFrame = CGRectZero;
            
            if ([self shouldCalculateRemovalFrame]) {
                endFrame = [axisLayer frameForValue:[axisLayer.currentTickValues[i] floatValue] label:[(CATextLayer *)textLayer string] plotArea:plotArea valueRange:valueRange];
            }
            
            [self removeTextLayer:textLayer toFrame:endFrame duration:duration];
        }
    }
    
    axisLayer.textLayers = newLayers;

}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    CALayer *layer = [anim valueForKey:@"animationLayer"];
    if (layer) {
        [layer removeFromSuperlayer];
    }
}

@end
