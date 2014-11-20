//
//  LineGraphPinchHandler.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-18.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphPinchHandler.h"

@implementation LineGraphPinchHandler

- (id)init {
    self = [super init];
    if (self) {
        self.touchType = kLineGraphTouchPinch;
        self.layer = [CAShapeLayer layer];
        self.layer.fillColor = [[UIColor whiteColor] CGColor];
        self.circleRadius = 5.f;
    }
    return self;
}

- (void)updateAtCoordinates:(NSArray *)coordinates values:(NSArray *)values {
    CGMutablePathRef path = CGPathCreateMutable();
    
    for (NSValue *value in coordinates) {
        CGPoint point = value.CGPointValue;
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - self.circleRadius, point.y - self.circleRadius, self.circleRadius * 2, self.circleRadius * 2)];
        CGPathAddPath(path, NULL, bezierPath.CGPath);
    }
    
    [self.layer setPath:path];
    
    CGPathRelease(path);
}

- (void)clear {
    self.layer.path = nil;
}


@end
