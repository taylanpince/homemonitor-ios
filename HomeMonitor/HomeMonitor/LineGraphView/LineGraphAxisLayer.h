//
//  LineGraphAxisLayer.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-28.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LineGraphAxisAnimator;

/** Defines the position of an axis layer */
typedef NS_ENUM(NSInteger, LineGraphAxisPosition) {
    /** Axis layer will not appear */
    kLineGraphAxisPositionNone,
    /** x-axis layer along the top of the plot area */
    kLineGraphAxisPositionTop,
    /** x-axis layer along the bottom of the plot area */
    kLineGraphAxisPositionBottom,
    /** y-axis layer along the left of the plot area */
    kLineGraphAxisPositionLeft,
    /** y-axis layer along the right of the plot area */
    kLineGraphAxisPositionRight
};

/** Defines where the x-axis labels can appear in relation to the tick marks */
typedef NS_ENUM(NSInteger, LineGraphXAlignment) {
    /** Center-aligned */
    kLineGraphXAlignCenter,
    /** Left-aligned, appears to the right of the tick marks */
    kLineGraphXAlignLeft,
    /** Right-aligned, appears to the left of the tick marks */
    kLineGraphXAlignRight
};

@interface LineGraphAxisLayer : CAShapeLayer

@property (nonatomic) LineGraphAxisPosition axisPosition;
@property (nonatomic) LineGraphXAlignment xAlignment;
@property (nonatomic) CGFloat tickLength;
@property (nonatomic, strong) UIFont *labelFont;
@property (nonatomic, strong) NSMutableArray *textLayers;
@property (nonatomic) CGRect currentPlotArea;
@property (nonatomic) CGRect currentValueRange;
@property (nonatomic) CGFloat currentTickLength;
@property (nonatomic, readonly) NSArray *currentTickValues;
@property (nonatomic, readonly) NSArray *currentLabels;
@property (nonatomic, strong) LineGraphAxisAnimator *animator;
@property (nonatomic, readonly) CAShapeLayer *tickLayer;

- (void)drawForPlotArea:(CGRect)plotArea
             valueRange:(CGRect)valueRange
                 bounds:(CGRect)bounds
             tickValues:(NSArray *)tickValues
                 labels:(NSArray *)labels
               duration:(CFTimeInterval)duration;

- (BOOL)isHorizontal;

// TODO should find a better way than passing all of these values around
- (BOOL)checkValue:(float)floatValue withinRange:(CGRect)valueRange;
- (CGRect)frameForValue:(float)floatValue label:(NSString *)label plotArea:(CGRect)plotArea valueRange:(CGRect)valueRange;
- (CGMutablePathRef)tickPathForPlotArea:(CGRect)plotArea valueRange:(CGRect)valueRange tickValues:(NSArray *)tickValues;

@end
