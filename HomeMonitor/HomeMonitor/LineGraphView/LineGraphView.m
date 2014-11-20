//
//  LineGraphView.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-09.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphView.h"
#import "LineGraphUtils.h"
#import "CALayer+LineGraphAnimation.h"
#import "LineGraphPlotAnimation.h"

#define CLAMP(min, value, max) (MIN(max, MAX(min, value)))

/** Defines which ends of paths need to be anchored to a different range for smoothing insert/delete animations */
typedef NS_ENUM(NSInteger, LineGraphAnchorLocation) {
    /** Anchor the left end of the plot range */
    kLineGraphAnchorLeft = 1,
    /** Anchor the right end of the plot range */
    kLineGraphAnchorRight = 2
};

@interface LineGraphView () {
    NSUInteger _plotCount;
    NSMutableArray *_plotPoints;
    CGRect _plotArea;
    CGRect _valueRange;
    NSArray *_yTicks;
    NSArray *_yLabels;
    NSArray *_xTicks;
    NSArray *_xLabels;
    CGFloat _xAxisHeight;
    CGFloat _yAxisWidth;
    NSDictionary *_yLabelHeightsByValue;
    NSDictionary *_xLabelWidthsByValue;
    NSMutableArray *_lineWidths;
    NSMutableArray *_lineCaps;
    NSMutableArray *_lineJoins;
    NSMutableArray *_strokeColors;
    NSMutableArray *_dashPatterns;
    NSMutableArray *_gestureRecognizers;
    NSMutableArray *_touchHandlers;
    
    LineGraphAxisLayer *_xAxisLayer;
    LineGraphAxisLayer *_yAxisLayer;
    
    NSMutableArray *_plotLayers;
    NSMutableArray *_xTextLayers;
    NSMutableArray *_yTextLayers;
    
    NSMutableArray *_beginUpdatePlotPoints;
    NSArray *_beginUpdateTicksX;
    NSArray *_beginUpdateTicksY;
    CGRect _beginUpdateValueRange;
    CGRect _beginUpdatePlotArea;
    NSMutableArray *_updateOperations;
    NSMutableArray *_deletePlots;
    NSMutableArray *_insertPlots;
    
    NSMutableArray *_plotMasks;
    
    NSMutableArray *_layersToRemove;
    NSUInteger _animatingLayerCount;
    
    BOOL _dataSourceLoaded;
}

- (CGPoint)findClosestDataPointForX:(float)x plot:(NSUInteger)plot;
- (void)handleGesture:(UIGestureRecognizer *)gesture;
- (CGMutablePathRef)pathForPlot:(NSUInteger)plot;

@end

@implementation LineGraphView

@synthesize valueRange = valueRange_;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.contentMode = UIViewContentModeRedraw;
        
        self.xAxisPosition = kLineGraphAxisPositionNone;
        self.yAxisPosition = kLineGraphAxisPositionNone;
        self.graphInsets = UIEdgeInsetsZero;
        self.labelFont = [UIFont systemFontOfSize:16.f];
        self.axisColor = [UIColor lightGrayColor];
        self.valueRange = CGRectZero;
        self.tickLength = 2.f;
        self.xAlignment = kLineGraphXAlignCenter;
        self.touchesEnabled = FALSE;
        self.animationDuration = 0.25f;
        self.axisAnimator = nil;
        
        _plotShouldOverlayAxes = TRUE;
        
        _plotLayers = [NSMutableArray array];
        
        _xTextLayers = [NSMutableArray array];
        _yTextLayers = [NSMutableArray array];
        
        _xAxisLayer = [[LineGraphAxisLayer alloc] init];
        [self.layer addSublayer:_xAxisLayer];
        
        _yAxisLayer = [[LineGraphAxisLayer alloc] init];
        [self.layer addSublayer:_yAxisLayer];
        
        _touchHandlers = [NSMutableArray array];
        _layersToRemove = [NSMutableArray array];
        
        _dataSourceLoaded = FALSE;
    }
    
    return self;
}
- (void)layoutSubviews {
    //NSLog(@"layoutSubviews");
    if (_dataSource && !_dataSourceLoaded) {
        _dataSourceLoaded = TRUE;
        [self reloadData];
    } else {
        [self resizePlotArea];
        [self updatePlotLayers];
        [self resizeAxisLayersWithDuration:0];
    }
}

- (void)setDataSource:(id<LineGraphViewDataSource>)dataSource {
    _dataSource = dataSource;
    _dataSourceLoaded = FALSE;
    [self setNeedsLayout];
}

- (void)updatePlotLayers {
    for (NSInteger plot = 0; plot < _plotCount; plot++) {
        CAShapeLayer *layer = _plotLayers[plot];
        layer.frame = _plotArea;
        
        CGPathRef path = [self pathForPlot:plot];
        layer.path = path;
        CGPathRelease(path);
    }
}

- (void)setPlotShouldOverlayAxes:(BOOL)plotShouldOverlayAxes {
    for (CALayer *plotLayer in _plotLayers) {
        plotLayer.masksToBounds = !plotShouldOverlayAxes;
    }
    
    // Arbitrary values
    _xAxisLayer.zPosition = plotShouldOverlayAxes ? -50 : 50;
    _yAxisLayer.zPosition = plotShouldOverlayAxes ? -50 : 50;
    
    _plotShouldOverlayAxes = plotShouldOverlayAxes;
}

- (void)reloadData {
    [self loadData];
    [self resizePlotArea];
    
    for (CALayer *plotLayer in _plotLayers) {
        [plotLayer removeFromSuperlayer];
    }
    
    [_plotLayers removeAllObjects];
    
    for (int plot = 0; plot < _plotCount; plot++) {
        CAShapeLayer *layer = [self layerForPlot:plot];

        CGPathRef path = [self pathForPlot:plot];
        layer.path = path;
        CGPathRelease(path);
        
        [self.layer addSublayer:layer];
        
        [_plotLayers addObject:layer];
    }
    
    [self resizeAxisLayersWithDuration:0];
}

- (void)setTouchesEnabled:(BOOL)touchesEnabled {
    if (touchesEnabled) {
        if (!_gestureRecognizers) {
            _gestureRecognizers = [NSMutableArray array];
        }
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
        [longPressGesture setMinimumPressDuration:0.2];
        [self addGestureRecognizer:longPressGesture];
        [_gestureRecognizers addObject:longPressGesture];
        
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
        [self addGestureRecognizer:pinchGesture];
        [_gestureRecognizers addObject:pinchGesture];
    } else {
        for (UIGestureRecognizer *gesture in _gestureRecognizers) {
            [self removeGestureRecognizer:gesture];
        }
        [_gestureRecognizers removeAllObjects];
    }
}

- (void)maskPlot:(NSUInteger)maskedPlot toPlot:(NSUInteger)targetPlot {
    if (_plotMasks == nil) {
        _plotMasks = [NSMutableArray array];
    }
    
    for (NSMutableArray *plotMask in _plotMasks) {
        if ([plotMask[0] intValue] == maskedPlot) {
            plotMask[1] = @(targetPlot);
            return;
        }
    }
    
    [_plotMasks addObject:[NSMutableArray arrayWithArray:@[@(maskedPlot), @(targetPlot)]]];
}

- (void)removeMaskForPlot:(NSUInteger)maskedPlot {
    for (NSMutableArray *plotMask in _plotMasks) {
        if ([plotMask[0] intValue] == maskedPlot) {
            [_plotMasks removeObjectIdenticalTo:plotMask];
            return;
        }
    }
}

/* Finds the closest data point to X, a data value, in the given plot.  For use with gestures.
*/
- (CGPoint)findClosestDataPointForX:(float)x plot:(NSUInteger)plot {
    NSMutableArray *pointValues = [NSMutableArray arrayWithArray:[_plotPoints objectAtIndex:plot]];

    // We start with the data points for the given plot, then add any data points in plots that are
    // masked to the plot.
    for (NSArray *plotMask in _plotMasks) {
        if ([plotMask[1] intValue] == plot) {
            for (NSValue *dataPoint in _plotPoints[[plotMask[0] intValue]]) {
                [pointValues addObject:dataPoint];
            }
        }
    }
    
    // Then, because we may have added masked values, we re-sort the pointValues array.
    NSArray *sortedPointValues = [pointValues sortedArrayUsingComparator:^(id a, id b) {
        float ax = [a CGPointValue].x;
        float bx = [b CGPointValue].x;
        
        if (ax > bx)
            return (NSComparisonResult)NSOrderedDescending;
        
        if (bx < ax)
            return (NSComparisonResult)NSOrderedAscending;
        
        return (NSComparisonResult)NSOrderedSame;
    }];

    // Then, we create an array with just the X values from sortedPointValues, so that we can
    // do a binary search to find the closest index value.
    NSMutableArray *xValues = [NSMutableArray arrayWithCapacity:sortedPointValues.count];
    
    for (NSValue *value in sortedPointValues) {
        [xValues addObject:@(value.CGPointValue.x)];
    }
    
    NSUInteger index = [xValues indexOfObject:@(x) inSortedRange:NSMakeRange(0, xValues.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:^(id a, id b) {
        return [a compare:b];
    }];
    
    // Now we should have an index of the lowest value that is higher than our desired X.  Figure out whether
    // index or index+1 is the closest, and return.
    if (index == 0) {
        index = 0;
    } else if (index == xValues.count) {
        --index;
    } else {
        CGFloat leftDifference = x - [xValues[index - 1] floatValue];
        CGFloat rightDifference = [xValues[index] floatValue] - x;
        if (leftDifference < rightDifference) {
            --index;
        }
    }
    
    return [(NSValue *)sortedPointValues[index] CGPointValue];
}

- (void)cancelTouches {
    for (NSArray *touchHandlerRecord in _touchHandlers) {
        LineGraphTouchHandler *touchHandler = [touchHandlerRecord objectAtIndex:0];
        [touchHandler touchEnded];
    }
}

- (void)handleGesture:(UIGestureRecognizer *)gesture {
    // Case 1: we want to deal with this gesture
    if ((gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) && (([gesture isMemberOfClass:[UILongPressGestureRecognizer class]] && gesture.numberOfTouches == 1) || ([gesture isMemberOfClass:[UIPinchGestureRecognizer class]] && gesture.numberOfTouches == 2))) {
        
        // Calculate the data X values for the touches, put them in ascending order
        NSMutableArray *values = [NSMutableArray arrayWithCapacity:gesture.numberOfTouches];
        for (int touchIndex = 0; touchIndex < gesture.numberOfTouches; touchIndex++) {
            CGPoint point = [gesture locationOfTouch:touchIndex inView:self];
            [values addObject:@(ValueForPlotX(point.x, _plotArea, _valueRange))];
        }
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [values sortUsingDescriptors:@[sortDescriptor]];
        
        // For each plot, find the closest (x) value for each touch, and store both the pointValue and the
        // screen coordinate of the point.  Notify any relevant attached handlers or the delegate, if set.
        for (int plot = 0; plot < _plotCount; plot++) {
            NSMutableArray *coordinates = [NSMutableArray arrayWithCapacity:gesture.numberOfTouches];
            NSMutableArray *pointValues = [NSMutableArray arrayWithCapacity:gesture.numberOfTouches];
            
            for (int touchIndex = 0; touchIndex < gesture.numberOfTouches; touchIndex++) {
                CGPoint closestPoint = [self findClosestDataPointForX:[values[touchIndex] floatValue] plot:plot];
                
                [coordinates addObject:[NSValue valueWithCGPoint:CGPointMake(OffsetXForValue(closestPoint.x, _plotArea, _valueRange), OffsetYForValue(closestPoint.y,_plotArea,_valueRange))]];
                [pointValues addObject:[NSValue valueWithCGPoint:closestPoint]];
            }
            
            for (NSArray *touchHandlerRecord in _touchHandlers) {
                if ([[touchHandlerRecord objectAtIndex:1] intValue] == plot) {
                    LineGraphTouchHandler *touchHandler = [touchHandlerRecord objectAtIndex:0];
                    
                    if (([gesture isMemberOfClass:[UILongPressGestureRecognizer class]] && touchHandler.touchType == kLineGraphTouchLongPress) || ([gesture isMemberOfClass:[UIPinchGestureRecognizer class]] && touchHandler.touchType == kLineGraphTouchPinch)) {
                        
                        [touchHandler updateAtCoordinates:coordinates values:pointValues];
                    }
                }
            }
            
            if ([gesture isMemberOfClass:[UILongPressGestureRecognizer class]]
                && [self.delegate respondsToSelector:@selector(lineGraphView:didPanToValue:plot:)]) {
                
                [self.delegate lineGraphView:self didPanToValue:pointValues[0] plot:plot];
                
            } else if ([gesture isMemberOfClass:[UIPinchGestureRecognizer class]]
                       && [self.delegate respondsToSelector:@selector(lineGraphView:didPinchWithValues:plot:)]) {
                
                [self.delegate lineGraphView:self didPinchWithValues:pointValues plot:plot];
            }
        }
    }  // Case 2: not a gesture state we care about, cancel anything we were tracking
    else {
        [self cancelTouches];
        
        if ([gesture isMemberOfClass:[UILongPressGestureRecognizer class]]
            && [self.delegate respondsToSelector:@selector(lineGraphView:didPanToValue:plot:)]) {
            
            for (int plot = 0; plot < _plotCount; plot++) {
                [self.delegate lineGraphView:self didPanToValue:nil plot:plot];
            }
        } else if ([gesture isMemberOfClass:[UIPinchGestureRecognizer class]]
                   && [self.delegate respondsToSelector:@selector(lineGraphView:didPinchWithValues:plot:)]) {
            
            for (int plot = 0; plot < _plotCount; plot++) {
                [self.delegate lineGraphView:self didPinchWithValues:nil plot:plot];
            }
        }
    }
    
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)gesture {
    [self handleGesture:gesture];
}

- (void)pinchGesture:(UIPinchGestureRecognizer *)gesture {
    [self handleGesture:gesture];
}

- (void)addTouchHandler:(LineGraphTouchHandler *)touchHandler plot:(NSUInteger)plot {
    [self.layer addSublayer:touchHandler.layer];
    touchHandler.layer.frame = _plotArea;
    touchHandler.layer.zPosition = 100; // Arbitrary value, touch layers should appear above plot layers.
    
    [_touchHandlers addObject:@[touchHandler, @(plot)]];
}

/* Compute the path for the given plot based on current data.
*/
- (CGMutablePathRef)pathForPlot:(NSUInteger)plot {
    return [self pathForPlotPoints:[_plotPoints objectAtIndex:plot] frame:_plotArea valueRange:_valueRange];
}

- (void)resizeAxisLayersWithDuration:(CFTimeInterval)duration {
    _xAxisLayer.strokeColor = self.axisColor.CGColor;
    _yAxisLayer.strokeColor = self.axisColor.CGColor;
    _xAxisLayer.tickLength = self.tickLength;
    _yAxisLayer.tickLength = self.tickLength;
    _xAxisLayer.axisPosition = self.xAxisPosition;
    _yAxisLayer.axisPosition = self.yAxisPosition;
    _xAxisLayer.labelFont = self.labelFont;
    _yAxisLayer.labelFont = self.labelFont;
    _xAxisLayer.xAlignment = self.xAlignment;
    _xAxisLayer.animator = self.axisAnimator;
    _yAxisLayer.animator = self.axisAnimator;
    
    [_xAxisLayer drawForPlotArea:_plotArea valueRange:_valueRange bounds:self.bounds tickValues:_xTicks labels:_xLabels duration:duration];
    [_yAxisLayer drawForPlotArea:_plotArea valueRange:_valueRange bounds:self.bounds tickValues:_yTicks labels:_yLabels duration:duration];
}

- (CGRect)calculatePlotArea {
    // First, calculate the default area for the plotArea, based on axis position,
    // dimensions calcuated during loadData, and manually set insets, if any.
    CGPoint origin = CGPointMake(0 + self.graphInsets.left + ((self.yAxisPosition == kLineGraphAxisPositionLeft) ? _yAxisWidth : 0), 0 + self.graphInsets.top + ((self.xAxisPosition == kLineGraphAxisPositionTop) ? _xAxisHeight : 0));
    
    CGSize plotSize = CGSizeMake(self.bounds.size.width - self.graphInsets.right - origin.x - ((self.yAxisPosition == kLineGraphAxisPositionRight) ? _yAxisWidth : 0), self.bounds.size.height - self.graphInsets.bottom - origin.y - ((self.xAxisPosition == kLineGraphAxisPositionBottom) ? _xAxisHeight : 0));
    
    CGRect plotArea = CGRectMake(origin.x, origin.y, plotSize.width, plotSize.height);
    
    // Next, shrink plot area to prevent thick lines from spilling outside of view
    CGFloat maxBufferWidth = 0;
    for (NSUInteger plot = 0; plot < _plotCount; plot++) {
        maxBufferWidth = MAX(maxBufferWidth, ceilf([_lineWidths[plot] floatValue] / 2.f));
    }

    plotArea = CGRectIntersection(plotArea, CGRectMake(maxBufferWidth, maxBufferWidth, CGRectGetWidth(self.bounds) - (maxBufferWidth * 2), CGRectGetHeight(self.bounds) - (maxBufferWidth * 2)));
    
    // Now, examine the label sizes, which were calculated in loadData, to see if the plotArea
    // needs to be further shrunk to fit labels.
    UIEdgeInsets minInsets = UIEdgeInsetsMake(0,0,0,0);
    
    if (_yLabelHeightsByValue != nil) {
        for (NSString *key in _yLabelHeightsByValue) {
            float y = PlotYForValue([key floatValue], plotArea, _valueRange);
            float height = [[_yLabelHeightsByValue objectForKey:key] floatValue] * 1.2;
            
            float topY = y - ceilf(height / 4);
            float bottomY = y + ceilf(height / 4);
            
            if (topY < 0) {
                minInsets.top = MAX(minInsets.top, ceil(abs(topY)));
            } else if (bottomY > CGRectGetMaxY(self.bounds)) {
                minInsets.bottom = MAX(minInsets.bottom, ceil(bottomY - CGRectGetMaxY(self.bounds)));
            }
        }
        
        if (minInsets.top > 0) {
            plotArea.origin.y += minInsets.top;
            plotArea.size.height -= minInsets.top;
        }
        
        if (minInsets.bottom > 0) {
            plotArea.size.height -= minInsets.bottom;
        }
    }
    
    
    if (_xLabelWidthsByValue != nil) {
        for (NSString *key in _xLabelWidthsByValue) {
            float x = PlotXForValue([key floatValue], plotArea, _valueRange);
            float width = [[_xLabelWidthsByValue objectForKey:key] floatValue];
            
            float leftX = x - ceilf(width / 2);
            
            if (self.xAlignment == kLineGraphXAlignCenter) {
                leftX = x - ceilf(width / 2);
            } else if (self.xAlignment == kLineGraphXAlignRight) {
                leftX = x - ceilf(width) - 2;
            } else if (self.xAlignment == kLineGraphXAlignLeft) {
                leftX = x + 2;
            }
            
            float rightX = leftX + ceilf(width);
            
            if (leftX < 0) {
                minInsets.left = MAX(minInsets.left, ceil(abs(leftX)));
            } else if (rightX > CGRectGetMaxX(self.bounds)) {
                minInsets.right = MAX(minInsets.right, ceil(rightX - CGRectGetMaxX(self.bounds)));
            }
        }
        
        if (minInsets.left > 0) {
            plotArea.origin.x += minInsets.left;
            plotArea.size.width -= minInsets.left;
        }
        
        if (minInsets.right > 0) {
            plotArea.size.width -= minInsets.right;
        }
    }
    
    return plotArea;
}


/** Resizes the plotArea, and any layers for touch handlers **/

- (void)resizePlotArea {
    for (NSArray *touchHandlerRecord in _touchHandlers) {
        LineGraphTouchHandler *touchHandler = [touchHandlerRecord objectAtIndex:0];
        touchHandler.layer.frame = _plotArea;
    }
    [self cancelTouches];
    
    _plotArea = [self calculatePlotArea];
}

/* Returns a layer with the required attributes for the given plot.  This is used both for
 the main plot area, as well as temporary animation layers for that plot.
*/
- (CAShapeLayer *)layerForPlot:(NSUInteger)plot {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = _plotArea;
    layer.masksToBounds = !self.plotShouldOverlayAxes;
    layer.fillColor = nil;
    layer.lineWidth = [_lineWidths[plot] floatValue];
    layer.strokeColor = [_strokeColors[plot] CGColor];
    
    NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"onOrderIn",
                                       [NSNull null], @"onOrderOut",
                                       [NSNull null], @"sublayers",
                                       [NSNull null], @"contents",
                                       [NSNull null], @"bounds",
                                       [NSNull null], @"position",
                                       [NSNull null], @"path",
                                       nil];
    layer.actions = newActions;
    
    if (_dashPatterns != nil) {
        NSArray *dashPattern = _dashPatterns[plot];
        
        if (![dashPattern isEqual:[NSNull null]] && dashPattern.count > 1) {
            layer.lineDashPattern = dashPattern;
        } else {
            layer.lineDashPattern = nil;
        }
    }

    if (_lineCaps == nil) {
        layer.lineCap = (layer.lineDashPattern == nil) ? kCALineCapRound : kCALineCapButt;
    } else {
        layer.lineCap = _lineCaps[plot];
    }
    
    if (_lineJoins == nil) {
        layer.lineJoin = kCALineJoinRound;
    } else {
        layer.lineJoin = _lineJoins[plot];
    }
    
    return layer;
}

- (void)loadData {
    /* STEP 1: Collect the plot data
     */

    _plotCount = [self.dataSource numberOfPlotsInLineGraphView:self];
    _plotPoints = [NSMutableArray arrayWithCapacity:_plotCount];
    _lineWidths = [NSMutableArray arrayWithCapacity:_plotCount];
    _strokeColors = [NSMutableArray arrayWithCapacity:_plotCount];
    
    for (NSUInteger plot = 0; plot < _plotCount; plot++) {
        [_plotPoints addObject:[self.dataSource lineGraphView:self plotPointsForPlot:plot]];
        [_lineWidths addObject:@([self.dataSource lineGraphView:self lineWidthForPlot:plot])];
        [_strokeColors addObject:[self.dataSource lineGraphView:self lineColorForPlot:plot]];
    }
    
    if ([self.dataSource respondsToSelector:@selector(lineGraphView:lineCapForPlot:)]) {
        _lineJoins = [NSMutableArray arrayWithCapacity:_plotCount];
        for (NSUInteger plot = 0; plot < _plotCount; plot++) {
            [_lineJoins addObject:[self.dataSource lineGraphView:self lineJoinForPlot:plot]];
        }
    } else {
        _lineJoins = nil;
    }

    if ([self.dataSource respondsToSelector:@selector(lineGraphView:lineJoinForPlot:)]) {
        _lineCaps = [NSMutableArray arrayWithCapacity:_plotCount];
        for (NSUInteger plot = 0; plot < _plotCount; plot++) {
            [_lineCaps addObject:[self.dataSource lineGraphView:self lineCapForPlot:plot]];
        }
    } else {
        _lineCaps = nil;
    }
    
    if ([self.dataSource respondsToSelector:@selector(lineGraphView:dashPatternForPlot:)]) {
        _dashPatterns = [NSMutableArray arrayWithCapacity:_plotCount];
        for (NSUInteger plot = 0; plot < _plotCount; plot++) {
            NSArray *dashPattern = [self.dataSource lineGraphView:self dashPatternForPlot:plot];
            if (dashPattern == nil)
                [_dashPatterns addObject:[NSNull null]];
            else
                [_dashPatterns addObject:dashPattern];
        }
    } else {
        _dashPatterns = nil;
    }

    /* STEP 2: calculate the valueRange, if it's not being set by the user, and store in _valueRange
     */
    
    if (CGRectEqualToRect(self.valueRange, CGRectZero) || self.valueRangeObject != nil) {
        
        CGFloat xMin = [[[_plotPoints firstObject] firstObject] CGPointValue].x;
        CGFloat xMax = [[[_plotPoints firstObject] lastObject] CGPointValue].x;
        CGFloat yMin = [[[_plotPoints firstObject] firstObject] CGPointValue].y;
        CGFloat yMax = yMin;
        
        for (int i = 0; i < _plotCount; i++) {
            NSArray *dataPoints = [_plotPoints objectAtIndex:i];
            for (NSValue *point in dataPoints) {
                float y = [point CGPointValue].y;
                yMin = MIN(yMin, y);
                yMax = MAX(yMax, y);
            }
            
            xMin = MIN(xMin, [[dataPoints firstObject] CGPointValue].x);
            xMax = MAX(xMax, [[dataPoints lastObject] CGPointValue].x);
        }
        
        _valueRange = CGRectMake(xMin, yMin, xMax - xMin, yMax - yMin);
        
        if (self.valueRangeObject) {
            _valueRange = [self.valueRangeObject getValueRangeFromRange:_valueRange];
        }
        
    } else {
        _valueRange = self.valueRange;
    }

    /* STEP 3: Calculate the width and height required for the axes.
     Store label dimensions for future use by calculatePlotArea.
     */
    
    _yLabelHeightsByValue = nil;
    _xLabelWidthsByValue = nil;
    
    if (self.yAxisPosition != kLineGraphAxisPositionNone) {
        // Step 1: calculate the required width
        
        CGFloat maxWidth = 0;
        
        if ([self.dataSource respondsToSelector:@selector(yAxisTickIntervalInLineGraphView:)]) {
            LineGraphTickInterval *tickInterval = [self.dataSource yAxisTickIntervalInLineGraphView:self];
            _yTicks = [tickInterval ticksForStart:CGRectGetMinY(_valueRange) end:CGRectGetMaxY(_valueRange)];
            _yLabels = [tickInterval labelsForStart:CGRectGetMinY(_valueRange) end:CGRectGetMaxY(_valueRange)];
        } else {
            _yTicks = nil;
            _yLabels = nil;
        }
        
        if (_yTicks == nil) {
            if ([self.dataSource respondsToSelector:@selector(yAxisTickMarksInLineGraphView:)]) {
                _yTicks = [self.dataSource yAxisTickMarksInLineGraphView:self];
            } else {
                _yTicks = @[];
            }
        }
    
        if (_yLabels == nil) {
            if ([self.dataSource respondsToSelector:@selector(labelsForYAxisTickMarksInGraphView:)]) {
                _yLabels = [self.dataSource labelsForYAxisTickMarksInGraphView:self];
            } else {
                _yLabels = @[];
            }
        }
        
        if (_yTicks.count > 0) {
            for (int i = 0; i < _yTicks.count; i++) {
                float tickValue = [[_yTicks objectAtIndex:i] floatValue];
                
                if (tickValue >= CGRectGetMinY(_valueRange) && tickValue <= CGRectGetMaxY(_valueRange)) {
                    NSString *label = [_yLabels objectAtIndex:i];
                    CGSize labelSize = [label sizeWithAttributes:@{NSFontAttributeName:self.labelFont}];
                    maxWidth = MAX(maxWidth, labelSize.width);
                    
                    if (_yLabelHeightsByValue == nil) {
                        _yLabelHeightsByValue = [NSMutableDictionary dictionary];
                    }
                    
                    [_yLabelHeightsByValue setValue:[NSNumber numberWithFloat:labelSize.height] forKey:[NSString stringWithFormat:@"%f", tickValue]];
                }
            }
            _yAxisWidth = ceil(maxWidth) + self.tickLength + 2;
        } else {
            _yAxisWidth = self.tickLength;
        }
    }
    
    if (self.xAxisPosition != kLineGraphAxisPositionNone) {
        CGFloat maxLabelHeight = 0;
        
        if ([self.dataSource respondsToSelector:@selector(xAxisTickIntervalInLineGraphView:)]) {
            LineGraphTickInterval *tickInterval = [self.dataSource xAxisTickIntervalInLineGraphView:self];
            _xTicks = [tickInterval ticksForStart:CGRectGetMinX(_valueRange) end:CGRectGetMaxX(_valueRange)];
            _xLabels = [tickInterval labelsForStart:CGRectGetMinX(_valueRange) end:CGRectGetMaxX(_valueRange)];
        } else {
            _xTicks = nil;
            _xLabels = nil;
        }
        
        if (_xTicks == nil) {
            if ([self.dataSource respondsToSelector:@selector(xAxisTickMarksInLineGraphView:)]) {
                _xTicks = [self.dataSource xAxisTickMarksInLineGraphView:self];
            } else {
                _xTicks = @[];
            }
        }
        
        if (_xLabels == nil) {
            if ([self.dataSource respondsToSelector:@selector(labelsForXAxisTickMarksInGraphView:)]) {
                _xLabels = [self.dataSource labelsForXAxisTickMarksInGraphView:self];
            } else {
                _xLabels = @[];
            }
        }
        
        if (_xTicks.count > 0) {
            for (int i = 0; i < _xTicks.count; i++) {
                if (i >= _xLabels.count)
                    break;
                
                float tickValue = [[_xTicks objectAtIndex:i] floatValue];
                
                if (tickValue >= CGRectGetMinX(_valueRange) && tickValue <= CGRectGetMaxX(_valueRange)) {
                    NSString *label = [_xLabels objectAtIndex:i];
                    CGSize labelSize = [label sizeWithAttributes:@{NSFontAttributeName:self.labelFont}];
                    maxLabelHeight = MAX(maxLabelHeight, labelSize.height * 1.2);
                    
                    if (_xLabelWidthsByValue == nil) {
                        _xLabelWidthsByValue = [NSMutableDictionary dictionary];
                    }
                    
                    [_xLabelWidthsByValue setValue:[NSNumber numberWithFloat:labelSize.width] forKey:[NSString stringWithFormat:@"%f", tickValue]];
                }
            }
            _xAxisHeight = ceil(maxLabelHeight / 2) + 3 + (self.xAlignment == kLineGraphXAlignCenter ? self.tickLength : 0);
        } else {
            _xAxisHeight = self.tickLength;
        }
    }
}

- (void)animateToFrame:(CGRect)frame duration:(CFTimeInterval)duration {
    [self.layer animateFromFrame:self.frame toFrame:frame duration:duration];
    
    self.frame = frame;
    [self resizePlotArea];
    
    for (int plot = 0; plot < _plotCount; plot++) {
        CAShapeLayer *layer = [_plotLayers objectAtIndex:plot];
        CGPathRef path = [self pathForPlot:plot];
        [layer animateFromFrame:layer.frame toFrame:_plotArea duration:duration path:path];
        CGPathRelease(path);
    }
    
    [self resizeAxisLayersWithDuration:duration];
}

- (void)animateToFrame:(CGRect)frame {
    [self animateToFrame:frame duration:self.animationDuration];
}

//- (CAAnimation *)animationForKey:(LineGraphAnimation)animationType {
//    if (animationType == kLineGraphAnimationStroke) {
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
//        animation.fromValue = @0;
//        animation.toValue = @1;
//        animation.duration = self.animationDuration;
//        return animation;
//    } else if (animationType == kLineGraphAnimationStrokeLeft) {
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
//        animation.fromValue = @1;
//        animation.toValue = @0;
//        animation.duration = self.animationDuration;
//        return animation;
//    } else if (animationType == kLineGraphAnimationUnstroke) {
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
//        animation.fromValue = @1;
//        animation.toValue = @0;
//        animation.duration = self.animationDuration;
//        return animation;
//    } else if (animationType == kLineGraphAnimationUnstrokeLeft) {
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
//        animation.fromValue = @0;
//        animation.toValue = @1;
//        animation.duration = self.animationDuration;
//        return animation;
//    } else if (animationType == kLineGraphAnimationFadeOut) {
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//        animation.fromValue = @1;
//        animation.toValue = @0;
//        animation.duration = self.animationDuration;
//        return animation;
//    } else if (animationType == kLineGraphAnimationFadeIn) {
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//        animation.fromValue = @0;
//        animation.toValue = @1;
//        animation.duration = self.animationDuration;
//        return animation;
//    } else {
//        return nil;
//    }
//}

/* Utility method for interpolating values for prettier replace path transformation. */
- (NSArray *)interpolateDataPointsForXValues:(NSOrderedSet *)values
                                  fromPoints:(NSArray *)points
                                    plotArea:(CGRect)plotArea
                                  valueRange:(CGRect)valueRange {
    
    NSUInteger lastIndex = 0;
    BOOL lastValueReached = FALSE;
    
    NSMutableArray *interpolatedPoints = [NSMutableArray array];
    [interpolatedPoints addObject:[points firstObject]];
    
    for (NSUInteger i = 1; i < values.count; i++) {
        float x = [(NSNumber *)values[i] floatValue];
        
        CGPoint lastPointValue = [points[lastIndex] CGPointValue];
        
        float lastPointX = PlotXForValue([points[lastIndex] CGPointValue].x, plotArea, valueRange);
        
        if (lastValueReached) {
            [interpolatedPoints addObject:[points lastObject]];
        } else if (x <= lastPointX) {
            [interpolatedPoints addObject:points[lastIndex]];
        } else {
            BOOL found = FALSE;
            for (NSUInteger nextIndex = lastIndex + 1; nextIndex < points.count; nextIndex++) {
                CGPoint nextPointValue = [points[nextIndex] CGPointValue];
                float nextPointX = PlotXForValue(nextPointValue.x, plotArea, valueRange);
                
                if (x < nextPointX) {
                    float xPoint = lastPointValue.x + ((nextPointValue.x - lastPointValue.x) * ((x - lastPointX) / (nextPointX - lastPointX)));
                    float y = lastPointValue.y + ((nextPointValue.y - lastPointValue.y) * ((xPoint - lastPointValue.x) / (nextPointValue.x - lastPointValue.x)));
                    [interpolatedPoints addObject:[NSValue valueWithCGPoint:CGPointMake(xPoint, y)]];
                    found = TRUE;
                    break;
                } else if (x == nextPointX) {
                    [interpolatedPoints addObject:points[nextIndex]];
                    lastIndex = nextIndex;
                    found = TRUE;
                    break;
                } else {
                    lastIndex = nextIndex;
                    lastPointValue = [points[lastIndex] CGPointValue];
                    lastPointX = PlotXForValue(lastPointValue.x, plotArea, valueRange);
                }
            }
            if (!found) {
                [interpolatedPoints addObject:[points lastObject]];
                lastValueReached = TRUE;
            }
        }
    }
    
    return [NSArray arrayWithArray:interpolatedPoints];
}

- (void)beginUpdates {
    _beginUpdatePlotPoints = [NSMutableArray arrayWithCapacity:_plotCount];
    _beginUpdateTicksX = [_xTicks copy];
    _beginUpdateTicksY = [_yTicks copy];
    
    for (NSInteger plot = 0; plot < _plotCount; plot++) {
        [_beginUpdatePlotPoints addObject:[_plotPoints[plot] mutableCopy]];
    }
    
    _beginUpdateValueRange = _valueRange;
    _beginUpdatePlotArea = _plotArea;
    _updateOperations = [NSMutableArray array];
    _deletePlots = [NSMutableArray array];
    _insertPlots = [NSMutableArray array];
    
}

- (void)endUpdates {
    float duration = self.animationDuration;
    
    BOOL plotAreaAnimated = FALSE;
    
    CGRect origPlotArea = _plotArea;
    
    /* If there are any current animation layers still present, get rid of them.
     */
    if ([_layersToRemove count] > 0) {
        for (CALayer *layer in _layersToRemove) {
            [layer removeFromSuperlayer];
        }
        
        [_layersToRemove removeAllObjects];
    }
    
    /* Next, reload data and do all of the usual calculations.
     */
    [self loadData];
    [self resizePlotArea];
    [self resizeAxisLayersWithDuration:duration];

    CGRect newPlotArea = _plotArea;
    
    /* Now we calculate a transformation from the previous plotArea and valueRange into the newly calculated ones.
     This will be used to transform partial paths.  Not sure if this is still useful with the changes to path
     calculation, but is still used in a couple places.  Probably slightly more efficient than calculating the
     opposing path with pathForPlotPoints.
     */
    CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformIdentity, OffsetXForValue(CGRectGetMinX(_beginUpdateValueRange), newPlotArea, _valueRange), OffsetYForValue(CGRectGetMaxY(_beginUpdateValueRange), newPlotArea, _valueRange));
    
    transform = CGAffineTransformScale(transform, newPlotArea.size.width / origPlotArea.size.width * CGRectGetWidth(_beginUpdateValueRange) / CGRectGetWidth(_valueRange), newPlotArea.size.height / origPlotArea.size.height * CGRectGetHeight(_beginUpdateValueRange) / CGRectGetHeight(_valueRange));
    
    /* Animate out any plots marked for deletion, in reverse index order.
    */
    NSArray *sortedDeletePlots = [_deletePlots sortedArrayUsingComparator:^(id a, id b) {
        return [[b objectAtIndex:0] compare:[a objectAtIndex:0]];
    }];
    
    for (NSArray *deletePlotInfo in sortedDeletePlots) {
        NSUInteger plot = [deletePlotInfo[0] intValue];
        id<LineGraphPlotAnimator>animator = deletePlotInfo[1];
        
        CAShapeLayer *plotLayer = _plotLayers[plot];
        
        [_plotLayers removeObjectAtIndex:plot];
        
        if (animator.animation != nil && duration > 0) {
            CGPathRef newPath = CGPathCreateCopyByTransformingPath(plotLayer.path, &transform);
            [plotLayer animateFromFrame:origPlotArea toFrame:newPlotArea duration:duration path:newPath];
            CGPathRelease(newPath);
            animator.animation.delegate = self;
            [_layersToRemove addObject:plotLayer];
            [animator animateLayer:plotLayer duration:duration];
        } else {
            [plotLayer removeFromSuperlayer];
        }
    }
    
    /* Animate in any plots marked for insertion, in index order.
     */
    NSArray *sortedInsertPlots = [_insertPlots sortedArrayUsingComparator:^(id a, id b) {
        return [[a objectAtIndex:0] compare:[b objectAtIndex:0]];
    }];
    
    for (NSArray *insertPlotInfo in sortedInsertPlots) {
        NSUInteger plot = [insertPlotInfo[0] intValue];
        id<LineGraphPlotAnimator>animator = insertPlotInfo[1];
        
        CAShapeLayer *plotLayer = [self layerForPlot:plot];
        [_plotLayers insertObject:plotLayer atIndex:plot];
        
        [self.layer addSublayer:plotLayer];
        
        if (animator.animation != nil && duration > 0) {
            CGPathRef newPath = [self pathForPlot:plot];
            CGAffineTransform invertedTransform = CGAffineTransformInvert(transform);
            CGPathRef origPath = CGPathCreateCopyByTransformingPath(newPath, &invertedTransform);
            plotLayer.path = origPath;
            [plotLayer animateFromFrame:origPlotArea toFrame:newPlotArea duration:duration path:newPath];
            [animator animateLayer:plotLayer duration:duration];
            CGPathRelease(newPath);
            CGPathRelease(origPath);
        }
    }
    
    /* For each entry in the operation queue, execute the given operation.
     */
    for (NSArray *operation in _updateOperations) {
        NSString *operTag = operation[0];
        
        if ([operTag isEqualToString:@"delete"]) {
            NSIndexPath *indexPath = operation[1];
            NSInteger count = [operation[2] intValue];
            id<LineGraphPlotAnimator>animator = operation[3];

            NSMutableArray *dataPoints = _beginUpdatePlotPoints[indexPath.section];

            if (duration > 0 && animator.animation != nil) {
                
                // First, find the start and end index values.
                NSInteger startIndex = indexPath.row;
                NSInteger endIndex = indexPath.row + count;
                if (startIndex > 0 && ![dataPoints[startIndex - 1] isEqual:[NSNull null]]) {
                    startIndex -= 1;
                }
                
                if (endIndex >= dataPoints.count || [dataPoints[endIndex] isEqual:[NSNull null]]) {
                    endIndex -= 1;
                }
                
                // Next, grab the start and end points.
                CGPoint startPoint = [(NSValue *)dataPoints[startIndex] CGPointValue];
                CGPoint endPoint = [(NSValue *)dataPoints[endIndex] CGPointValue];
                
                // Now, create value ranges that will correspond to the start and end frames of the animation layer.
                CGRect subValueRangeStart = CGRectMake(startPoint.x, CGRectGetMinY(_beginUpdateValueRange), endPoint.x - startPoint.x, CGRectGetHeight(_beginUpdateValueRange));
                CGRect subValueRangeEnd = CGRectMake(startPoint.x, CGRectGetMinY(_valueRange), endPoint.x - startPoint.x, CGRectGetHeight(_valueRange));
                
                CAShapeLayer *animationLayer = [self layerForPlot:indexPath.section];
                
                // Next, calculate the begin and end frames for the animation layer.
                CGFloat startX = PlotXForValue(startPoint.x, origPlotArea, _beginUpdateValueRange);
                CGFloat endX = PlotXForValue(startPoint.x, newPlotArea, _valueRange);
                CGRect startFrame = CGRectMake(startX, CGRectGetMinY(origPlotArea), PlotXForValue(endPoint.x, origPlotArea, _beginUpdateValueRange) - startX, CGRectGetHeight(origPlotArea));
                CGRect endFrame = CGRectMake(endX, CGRectGetMinY(newPlotArea), PlotXForValue(endPoint.x, newPlotArea, _valueRange) - endX, CGRectGetHeight(newPlotArea));
                
                // Intersect with the plot area to prevent animation outside of the bounds.
                endFrame = CGRectIntersection(endFrame, newPlotArea);
                
                animationLayer.frame = endFrame;
                
                /* Next we calculate the start and end paths for the animation, add the animation layer to the
                 view, add the animation, and mark the animation layer for deletion once the animation has completed.
                 */
                NSArray *subPlotPoints = [dataPoints subarrayWithRange:NSMakeRange(startIndex,endIndex-startIndex+1)];
                
                NSInteger anchorLocation = 0;
                
                if (startIndex > 0) {
                    anchorLocation |= kLineGraphAnchorLeft;
                }
                
                if ((endIndex+1) < dataPoints.count) {
                    anchorLocation |= kLineGraphAnchorRight;
                }
                
                CGPathRef startPath = [self pathForPlotPoints:subPlotPoints frame:startFrame valueRange:subValueRangeStart];
                animationLayer.path = startPath;
                CGPathRelease(startPath);
                
                CGPathRef endPath = [self pathForPlotPoints:subPlotPoints frame:endFrame valueRange:subValueRangeStart anchorRange:subValueRangeEnd anchorLocation:anchorLocation];
                [animationLayer animateFromFrame:startFrame toFrame:endFrame duration:duration path:endPath];
                CGPathRelease(endPath);
                
                [self.layer addSublayer:animationLayer];
                
                animator.animation.delegate = self;
                [_layersToRemove addObject:animationLayer];
                [animator animateLayer:animationLayer duration:duration];
                
                plotAreaAnimated = TRUE;
            }
            
            // Create a new path without the deleted points based on original data, and set the plot area to
            // this new path.  This could probably be done once at the end instead.
            
            for (NSInteger i = indexPath.row; i < indexPath.row + count; i++) {
                dataPoints[i] = [NSNull null];
            }
            
            CGMutablePathRef newMainPath = [self pathForPlotPoints:dataPoints frame:origPlotArea valueRange:_beginUpdateValueRange];
            
            [(CAShapeLayer *)_plotLayers[indexPath.section] setPath:newMainPath];
            CGPathRelease(newMainPath);
            
        } else if ([operTag isEqualToString:@"insert"]) {
            if (duration > 0) {
                
                NSIndexPath *indexPath = operation[1];
                NSInteger count = [operation[2] intValue];
                id<LineGraphPlotAnimator>animator = operation[3];
                
                NSArray *dataPoints = _plotPoints[indexPath.section];
                
                // First, find the start and end index values.
                NSInteger startIndex = indexPath.row > 0 ? indexPath.row - 1 : 0;
                NSInteger endIndex = indexPath.row + count;
                if (endIndex >= dataPoints.count) {
                    endIndex = dataPoints.count - 1;
                }
                
                // Next, grab the start and end points.
                CGPoint startPoint = [(NSValue *)dataPoints[startIndex] CGPointValue];
                CGPoint endPoint = [(NSValue *)dataPoints[endIndex] CGPointValue];
                
                // Now, create value ranges that will correspond to the start and end frames of the animation layer.
                CGRect subValueRangeStart = CGRectMake(startPoint.x, CGRectGetMinY(_beginUpdateValueRange), endPoint.x - startPoint.x, CGRectGetHeight(_beginUpdateValueRange));
                CGRect subValueRangeEnd = CGRectMake(startPoint.x, CGRectGetMinY(_valueRange), endPoint.x - startPoint.x, CGRectGetHeight(_valueRange));
                
                CAShapeLayer *animationLayer = [self layerForPlot:indexPath.section];
                
                // Next, calculate the begin and end frames for the animation layer.
                CGFloat startX = CLAMP(CGRectGetMinX(origPlotArea), PlotXForValue(startPoint.x, origPlotArea, _beginUpdateValueRange),
                                       CGRectGetMaxX(origPlotArea));
                CGFloat endX = PlotXForValue(startPoint.x, newPlotArea, _valueRange);
                CGRect startFrame = CGRectMake(startX, CGRectGetMinY(origPlotArea), CLAMP(CGRectGetMinX(origPlotArea), PlotXForValue(endPoint.x, origPlotArea, _beginUpdateValueRange), CGRectGetMaxX(origPlotArea)) - startX, CGRectGetHeight(origPlotArea));
                CGRect endFrame = CGRectMake(endX, CGRectGetMinY(newPlotArea), PlotXForValue(endPoint.x, newPlotArea, _valueRange) - endX, CGRectGetHeight(newPlotArea));
                
                /* Next we calculate the start and end paths for the animation, add the animation layer to the
                 view, add the animation, and mark the animation layer for deletion once the animation has completed.
                 */
                NSArray *subPlotPoints = [dataPoints subarrayWithRange:NSMakeRange(startIndex,endIndex-startIndex+1)];
                
                NSInteger anchorLocation = 0;
                
                if (startIndex > 0) {
                    anchorLocation |= kLineGraphAnchorLeft;
                }
                
                if ((endIndex+1) < dataPoints.count) {
                    anchorLocation |= kLineGraphAnchorRight;
                }
                
                CGPathRef startPath = [self pathForPlotPoints:subPlotPoints frame:startFrame valueRange:subValueRangeEnd anchorRange:subValueRangeStart anchorLocation:anchorLocation];
                animationLayer.path = startPath;
                CGPathRelease(startPath);
                
                CGPathRef endPath = [self pathForPlotPoints:subPlotPoints frame:endFrame valueRange:subValueRangeEnd];
                [animationLayer animateFromFrame:startFrame toFrame:endFrame duration:duration path:endPath];
                CGPathRelease(endPath);
                
                [self.layer addSublayer:animationLayer];
                
                if (animator.animation == nil) {
                    // If this layer is not animated, we still want to trigger the removal after duration using
                    // the delegate function, so let's use an animation that doesn't do anything.
                    // this is a very edge case
                    CABasicAnimation *animation = [CABasicAnimation animation];
                    animation.duration = duration;
                    animation.delegate = self;
                    [animationLayer addAnimation:animation forKey:nil];
                } else {
                    animator.animation.delegate = self;
                    [animator animateLayer:animationLayer duration:duration];
                }
                
                [_layersToRemove addObject:animationLayer];
                
                plotAreaAnimated = TRUE;
            }
        } else if ([operTag isEqualToString:@"replace"]) {
            NSRange fromRange = [(NSValue *)operation[1] rangeValue];
            NSRange toRange = [(NSValue *)operation[2] rangeValue];
            NSUInteger plot = [operation[3] intValue];
            LineGraphReplaceStyle animationStyle = [operation[4] intValue];
            
            NSInteger fromStartIndex = fromRange.location > 0 ? fromRange.location - 1 : 0;
            NSInteger fromEndIndex = fromRange.location + fromRange.length;
            NSInteger toStartIndex = toRange.location > 0 ? toRange.location - 1 : 0;
            NSInteger toEndIndex = toRange.location + toRange.length;
            
            NSMutableArray *fromDataPoints = _beginUpdatePlotPoints[plot];
            
            if (fromEndIndex >= fromDataPoints.count || [fromDataPoints[fromEndIndex] isEqual:[NSNull null]]) {
                fromEndIndex -= 1;
            }
            
            if (toEndIndex == [_plotPoints[plot] count]) {
                toEndIndex -= 1;
            }
            
            // Collect the dataPoints used for the before and after.
            NSArray *fromSubrange = [fromDataPoints subarrayWithRange:NSMakeRange(fromStartIndex,fromEndIndex-fromStartIndex+1)];
            NSArray *toSubrange = [_plotPoints[plot] subarrayWithRange:NSMakeRange(toStartIndex,toEndIndex-toStartIndex+1)];
            
            // If we're using an interpolated style, then for both ranges we need to interpolate the values that
            // there are corresponding X values for in the other data set.
            if (animationStyle == kLineGraphReplaceStyleInterpolate) {
                NSMutableOrderedSet *combinedX = [[NSMutableOrderedSet alloc] init];
                
                for (NSValue *value in fromSubrange) {
                    [combinedX addObject:@(PlotXForValue(value.CGPointValue.x, origPlotArea, _beginUpdateValueRange))];
                }
                
                for (NSValue *value in toSubrange) {
                    [combinedX addObject:@(PlotXForValue(value.CGPointValue.x, newPlotArea, _valueRange))];
                }
                
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
                [combinedX sortUsingDescriptors:@[sortDescriptor]];
                
                fromSubrange = [self interpolateDataPointsForXValues:combinedX fromPoints:fromSubrange plotArea:origPlotArea valueRange:_beginUpdateValueRange];
                toSubrange = [self interpolateDataPointsForXValues:combinedX fromPoints:toSubrange plotArea:newPlotArea valueRange:_valueRange];
            }
            
            CGPoint fromStartPoint = [(NSValue *)fromDataPoints[fromStartIndex] CGPointValue];
            CGPoint fromEndPoint = [(NSValue *)fromDataPoints[fromEndIndex] CGPointValue];
            CGPoint toStartPoint = [(NSValue *)_plotPoints[plot][toStartIndex] CGPointValue];
            CGPoint toEndPoint = [(NSValue *)_plotPoints[plot][toEndIndex] CGPointValue];
            
            // Calculate the value ranges that correspond to the start and end frames.
            CGRect fromValueRange = CGRectMake(fromStartPoint.x, CGRectGetMinY(_beginUpdateValueRange), fromEndPoint.x - fromStartPoint.x, CGRectGetHeight(_beginUpdateValueRange));
            CGRect toValueRange = CGRectMake(toStartPoint.x, CGRectGetMinY(_valueRange), toEndPoint.x - toStartPoint.x, CGRectGetHeight(_valueRange));
            
            CAShapeLayer *animationLayer = [self layerForPlot:plot];
            
            // Calculate the start and end frames.
            CGFloat startX = PlotXForValue(fromStartPoint.x, origPlotArea, _beginUpdateValueRange);
            CGFloat endX = PlotXForValue(toStartPoint.x, newPlotArea, _valueRange);
            
            CGRect startFrame = CGRectMake(startX, CGRectGetMinY(origPlotArea), PlotXForValue(fromEndPoint.x, origPlotArea, _beginUpdateValueRange) - startX, CGRectGetHeight(origPlotArea));
            
            CGRect endFrame = CGRectMake(endX, CGRectGetMinY(newPlotArea), PlotXForValue(toEndPoint.x, newPlotArea, _valueRange) - endX, CGRectGetHeight(newPlotArea));
            
            /* Calculate the start and end paths, animate, mark animation layer for removal once complete.
             */
            CGPathRef startPath = [self pathForPlotPoints:fromSubrange frame:startFrame valueRange:fromValueRange];
            animationLayer.path = startPath;
            CGPathRelease(startPath);
            
            CGPathRef endPath = [self pathForPlotPoints:toSubrange frame:endFrame valueRange:toValueRange];
            [animationLayer animateFromFrame:startFrame toFrame:endFrame duration:duration path:endPath];
            CGPathRelease(endPath);
            
            [self.layer addSublayer:animationLayer];
            
            CABasicAnimation *animation = [CABasicAnimation animation];
            animation.duration = duration;
            animation.delegate = self;
            [_layersToRemove addObject:animationLayer];
            [animationLayer addAnimation:animation forKey:nil];
            
            /* Much like in a delete operation, remove the replaced data points from the original data points,
             so they won't be animated in the interim.
             */
            for (NSInteger i = fromRange.location; i < fromRange.location + fromRange.length; i++) {
                fromDataPoints[i] = [NSNull null];
            }
            
            CGMutablePathRef newMainPath = [self pathForPlotPoints:fromDataPoints frame:origPlotArea valueRange:_beginUpdateValueRange];
            
            [(CAShapeLayer *)_plotLayers[plot] setPath:newMainPath];
            CGPathRelease(newMainPath);
            
            plotAreaAnimated = TRUE;
        }
    }
    
    /* Any data points that haven't been removed by delete/replace actions need to be animated into the
     new value range, unless no animations were called at all, in which case we can just directly place
     the new path.
    */
    for (NSInteger plot = 0; plot < _plotCount; plot++) {
        CAShapeLayer *layer = _plotLayers[plot];
        CGPathRef newPath = CGPathCreateCopyByTransformingPath(layer.path, &transform);
        if (plotAreaAnimated) {
            [layer animateFromFrame:origPlotArea toFrame:newPlotArea duration:duration path:newPath];
        } else {
            layer.path = newPath;
        }
        CGPathRelease(newPath);
    }
    
    /* Keep track of how many animation layers are active, so we can remove all of the layers at once
     later on to cut down on how many times layoutSubviews gets called.
     */
    _animatingLayerCount = [_layersToRemove count];
}

/* Creates a path with the given points.  Anchor range is provided to allow
 the ends of the path to be part of a different value range, for use with
 animations.
*/
- (CGMutablePathRef)pathForPlotPoints:(NSArray *)dataPoints
                                frame:(CGRect)frame
                           valueRange:(CGRect)valueRange
                          anchorRange:(CGRect)anchorRange
                       anchorLocation:(NSInteger)anchorLocation {
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    BOOL skipNext = TRUE;
    for (id value in dataPoints) {
        if ([value isEqual:[NSNull null]]) {
            skipNext = TRUE;
            continue;
        }

        CGPoint point = [(NSValue *)value CGPointValue];

        CGFloat x, y;
        
        if ((anchorLocation & kLineGraphAnchorLeft && value == dataPoints.firstObject)
            || (anchorLocation & kLineGraphAnchorRight && value == dataPoints.lastObject)) {
            x = OffsetXForValue(point.x, frame, anchorRange);
            y = OffsetYForValue(point.y, frame, anchorRange);
        } else {
            x = OffsetXForValue(point.x, frame, valueRange);
            y = OffsetYForValue(point.y, frame, valueRange);
        }
        
        if (skipNext) {
            CGPathMoveToPoint(path, NULL, x, y);
            skipNext = FALSE;
        } else {
            CGPathAddLineToPoint(path, NULL, x, y);
        }
    }
    
    return path;
}

- (CGMutablePathRef)pathForPlotPoints:(NSArray *)dataPoints frame:(CGRect)frame valueRange:(CGRect)valueRange {
    return [self pathForPlotPoints:dataPoints frame:frame valueRange:valueRange anchorRange:CGRectZero anchorLocation:0];
}

- (void)insertPointsAtIndexPath:(NSIndexPath *)indexPath count:(NSInteger)count animator:(id<LineGraphPlotAnimator>)animator {
    [_updateOperations addObject:@[@"insert", indexPath, @(count), animator]];
}

- (void)insertPointsAtIndexPath:(NSIndexPath *)indexPath count:(NSInteger)count {
    
    [self insertPointsAtIndexPath:indexPath
                            count:count
                         animator:[LineGraphPlotAnimation animationOfType:kLineGraphAnimationFadeIn]];
}

- (void)deletePointsAtIndexPath:(NSIndexPath *)indexPath count:(NSUInteger)count animator:(id<LineGraphPlotAnimator>)animator {
    [_updateOperations addObject:@[@"delete", indexPath, @(count), animator]];
}

- (void)deletePointsAtIndexPath:(NSIndexPath *)indexPath count:(NSUInteger)count {
    
    [self deletePointsAtIndexPath:indexPath
                            count:count
                         animator:[LineGraphPlotAnimation animationOfType:kLineGraphAnimationFadeOut]];
}

- (void)replacePointsInRange:(NSRange)startRange
                   withRange:(NSRange)endRange
                        plot:(NSUInteger)plot
              animationStyle:(LineGraphReplaceStyle)animationStyle {
    
    [_updateOperations addObject:@[@"replace", [NSValue valueWithRange:startRange], [NSValue valueWithRange:endRange], @(plot), @(animationStyle)]];
}

- (void)replacePointsInRange:(NSRange)startRange withRange:(NSRange)endRange plot:(NSUInteger)plot {
    [self replacePointsInRange:startRange withRange:endRange plot:plot animationStyle:kLineGraphReplaceStyleInterpolate];
}

- (void)reloadDataAtIndexPath:(NSIndexPath *)indexPath count:(NSUInteger)count {
    [self reloadDataAtIndexPath:indexPath count:count animationStyle:kLineGraphReplaceStyleInterpolate];
}

- (void)reloadDataAtIndexPath:(NSIndexPath *)indexPath
                        count:(NSUInteger)count
               animationStyle:(LineGraphReplaceStyle)animationStyle {
    
    [self replacePointsInRange:NSMakeRange(indexPath.row, count) withRange:NSMakeRange(indexPath.row, count) plot:indexPath.section animationStyle:animationStyle];
}

- (void)insertPlot:(NSUInteger)plot animator:(id<LineGraphPlotAnimator>)animator {
    [_insertPlots addObject:@[@(plot), animator]];
}

- (void)deletePlot:(NSUInteger)plot animator:(id<LineGraphPlotAnimator>)animator {
    [_deletePlots addObject:@[@(plot), animator]];
}

#pragma mark - CAAnimationDelegate

// only animations meant to remove a layer should delegate to this class
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (_animatingLayerCount > 0)  // just a sanity check, should always be true
        _animatingLayerCount -= 1;
    
    if (_animatingLayerCount == 0) {
        for (CALayer *layer in _layersToRemove) {
            if (layer.superlayer)
                [layer removeFromSuperlayer];
        }
    }
}

@end
