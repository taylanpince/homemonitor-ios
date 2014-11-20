//
//  LineGraphCirclePressHandler.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-18.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphCirclePressHandler.h"

@implementation LineGraphCirclePressHandler

- (id)init {
    self = [super init];
    if (self) {
        self.touchType = kLineGraphTouchLongPress;
        self.layer = [CAShapeLayer layer];
        self.layer.fillColor = [[UIColor whiteColor] CGColor];
        self.circleRadius = 5.f;
    }
    return self;
}

- (void)updateAtCoordinates:(NSArray *)coordinates values:(NSArray *)values {
    CGPoint point = [[coordinates objectAtIndex:0] CGPointValue];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - self.circleRadius, point.y - self.circleRadius, self.circleRadius * 2, self.circleRadius * 2)];
    
    [self.layer setPath:path.CGPath];
}

- (void)clear {
    self.layer.path = nil;
}

@end
