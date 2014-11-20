//
//  CALayer_LineGraphAnimation.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-29.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CALayer (LineGraphAnimation)

- (void)animateFromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame duration:(CFTimeInterval)duration;

@end

@interface CAShapeLayer (LineGraphAnimation)

- (void)animateFromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame duration:(CFTimeInterval)duration path:(CGPathRef)path;

@end

