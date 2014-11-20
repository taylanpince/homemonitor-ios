//
//  LineGraphRangeCalculator.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-08-06.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphRangeCalculator.h"

@interface LineGraphRangeCalculator () {
    BOOL _xMinSet, _xMaxSet, _yMinSet, _yMaxSet;
}

@end

@implementation LineGraphRangeCalculator

- (id)init {
    self = [super init];
    
    if (self) {
        _xMinSet = _xMaxSet = _yMinSet = _yMaxSet = FALSE;
        [self setInsets:UIEdgeInsetsZero];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LineGraphRangeCalculator *copy = [[LineGraphRangeCalculator allocWithZone:zone] init];
    copy->_xMinValue = _xMinValue;
    copy->_xMaxValue = _xMaxValue;
    copy->_yMinValue = _yMinValue;
    copy->_yMaxValue = _yMaxValue;
    copy->_xLeftInset = _xLeftInset;
    copy->_xRightInset = _xRightInset;
    copy->_yTopInset = _yTopInset;
    copy->_yBottomInset = _yBottomInset;
    copy->_xMinSet = _xMinSet;
    copy->_xMaxSet = _xMaxSet;
    copy->_yMinSet = _yMinSet;
    copy->_yMaxSet = _yMaxSet;
    
    return copy;
}

- (void)setXMinValue:(CGFloat)xMinValue {
    _xMinValue = xMinValue;
    _xMinSet = TRUE;
}

- (void)setXMaxValue:(CGFloat)xMaxValue {
    _xMaxValue = xMaxValue;
    _xMaxSet = TRUE;
}

- (void)setYMinValue:(CGFloat)yMinValue {
    _yMinValue = yMinValue;
    _yMinSet = TRUE;
}

- (void)setYMaxValue:(CGFloat)yMaxValue {
    _yMaxValue = yMaxValue;
    _yMaxSet = TRUE;
}

- (void)setInsets:(UIEdgeInsets)insets {
    _xLeftInset = insets.left;
    _xRightInset = insets.right;
    _yTopInset = insets.top;
    _yBottomInset = insets.bottom;
}

- (void)setAutoCalculateX {
    _xMinSet = _xMaxSet = FALSE;
}

- (void)setAutoCalculateY {
    _yMinSet = _yMaxSet = FALSE;
}

- (CGRect)getValueRangeFromRange:(CGRect)originalRange {
    CGFloat xMin = (_xMinSet ? _xMinValue : CGRectGetMinX(originalRange)) - _xLeftInset;
    CGFloat xMax = (_xMaxSet ? _xMaxValue : CGRectGetMaxX(originalRange)) + _xRightInset;
    CGFloat yMin = (_yMinSet ? _yMinValue : CGRectGetMinY(originalRange)) - _yBottomInset;
    CGFloat yMax = (_yMaxSet ? _yMaxValue : CGRectGetMaxY(originalRange)) + _yTopInset;
    
    return CGRectMake(xMin, yMin, xMax - xMin, yMax - yMin);
}

@end
