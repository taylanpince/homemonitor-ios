//
//  HMOGraph.m
//  HomeMonitor
//
//  Created by Taylan Pince on 2014-11-19.
//  Copyright (c) 2014 Hipo. All rights reserved.
//

#import "HMOGraph.h"


@implementation HMOGraph

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    
    if (self) {
        _name = name;
        _values = [[NSMutableArray alloc] init];
        _valueRange = CGRectMake(0.0, 0.0, 20.0, 1.0);
        _lineColor = [UIColor blueColor];
    }
    
    return self;
}

- (void)addValue:(Float32)value {
    CGPoint lastPoint = CGPointZero;
    NSValue *lastPointValue = [_values lastObject];
    
    if (lastPointValue) {
        lastPoint = [lastPointValue CGPointValue];
    }
    
    CGPoint newPoint = CGPointMake(lastPoint.x + 1.0, value);

    [_values addObject:[NSValue valueWithCGPoint:newPoint]];
    
    if ([_values count] > 20) {
        [_values removeObjectAtIndex:0];
    }

    if ([_values count] == 1) {
        _valueRange.origin.y = newPoint.y;
    } else {
        _valueRange.origin.y = fminf(_valueRange.origin.y, newPoint.y);
    }
    
    CGFloat heightDelta = newPoint.y - _valueRange.origin.y;

    _valueRange.origin.x = fmaxf(newPoint.x - 20.0, 0.0);
    _valueRange.size.height = fmaxf(_valueRange.size.height, heightDelta);
}

@end
