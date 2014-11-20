//
//  LineGraphUtils.c
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-28.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphUtils.h"

float OffsetXForValue(float value, CGRect bounds, CGRect valueRange) {
    return CGRectGetWidth(bounds) * (value - CGRectGetMinX(valueRange)) / CGRectGetWidth(valueRange);
}

float PlotXForValue(float value, CGRect bounds, CGRect valueRange) {
    return CGRectGetMinX(bounds) + OffsetXForValue(value, bounds, valueRange);
}

float ValueForPlotX(float x, CGRect bounds, CGRect valueRange) {
    return CGRectGetMinX(valueRange) + (CGRectGetWidth(valueRange) * (x - CGRectGetMinX(bounds)) / CGRectGetWidth(bounds));
}

float OffsetYForValue(float value, CGRect bounds, CGRect valueRange) {
    return CGRectGetHeight(bounds) * (1.0f - (value - CGRectGetMinY(valueRange)) / CGRectGetHeight(valueRange));
}

float PlotYForValue(float value, CGRect bounds, CGRect valueRange) {
    return CGRectGetMinY(bounds) + OffsetYForValue(value, bounds, valueRange);
}