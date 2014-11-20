//
//  LineGraphPlotAnimator.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-08-06.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphPlotAnimation.h"

@interface LineGraphPlotAnimation () {
    CABasicAnimation *_animation;
}

- (id)initWithStyle:(LineGraphPlotAnimationType)animationStyle;

@end


@implementation LineGraphPlotAnimation

+ (LineGraphPlotAnimation *)animationOfType:(LineGraphPlotAnimationType)animationType {
    return [[LineGraphPlotAnimation alloc] initWithStyle:animationType];
}

- (id)initWithStyle:(LineGraphPlotAnimationType)animationType {
    self = [super init];
    
    if (self) {
        if (animationType == kLineGraphAnimationStroke) {
            _animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            _animation.fromValue = @0;
            _animation.toValue = @1;
        } else if (animationType == kLineGraphAnimationStrokeLeft) {
            _animation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
            _animation.fromValue = @1;
            _animation.toValue = @0;
        } else if (animationType == kLineGraphAnimationUnstroke) {
            _animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
            _animation.fromValue = @1;
            _animation.toValue = @0;
        } else if (animationType == kLineGraphAnimationUnstrokeLeft) {
            _animation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
            _animation.fromValue = @0;
            _animation.toValue = @1;
        } else if (animationType == kLineGraphAnimationFadeOut) {
            _animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            _animation.fromValue = @1;
            _animation.toValue = @0;
        } else if (animationType == kLineGraphAnimationFadeIn) {
            _animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            _animation.fromValue = @0;
            _animation.toValue = @1;
        } else {
            _animation = nil;
        }
        
    }
    
    return self;
}

- (void)animateLayer:(CALayer *)layer duration:(CFTimeInterval)duration {
    if (_animation && duration > 0) {
        [layer setValue:_animation.toValue forKeyPath:_animation.keyPath];
        [layer addAnimation:_animation forKey:nil];
    }
}

- (CAAnimation *)animation {
    return _animation;
}

@end
