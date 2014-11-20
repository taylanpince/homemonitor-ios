//
//  LineGraphAxisAnimatorTranslate.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-29.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphAxisAnimatorTranslate.h"
#import "CALayer+LineGraphAnimation.h"

@implementation LineGraphAxisAnimatorTranslate

- (BOOL)shouldCalculateRemovalFrame {
    return YES;
}

- (BOOL)shouldCalculateInsertionFrame {
    return YES;
}

- (void)animateTextLayer:(CATextLayer *)textLayer toFrame:(CGRect)frame duration:(CFTimeInterval)duration {
    if (duration > 0) {
        [textLayer animateFromFrame:textLayer.frame toFrame:frame duration:duration];
    }
    textLayer.frame = frame;
}

- (void)removeTextLayer:(CATextLayer *)textLayer toFrame:(CGRect)frame duration:(CFTimeInterval)duration {
    if (duration > 0) {
        [textLayer animateFromFrame:textLayer.frame toFrame:frame duration:duration];
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.duration = duration;
        animation.delegate = self;
        [animation setValue:textLayer forKey:@"animationLayer"];
        [textLayer addAnimation:animation forKey:nil];
    } else {
        [textLayer removeFromSuperlayer];
    }
}

@end
