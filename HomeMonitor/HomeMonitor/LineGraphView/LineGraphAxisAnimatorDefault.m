//
//  LineGraphAxisAnimatorDefault.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-29.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphAxisAnimatorDefault.h"
#import "CALayer+LineGraphAnimation.h"

/* This was originally the default axis animation, but is not particularly visually pleasing,
 using a combination of translations and fades.  Use LineGraphAxisAnimatorTranslate.
*/

@implementation LineGraphAxisAnimatorDefault

- (BOOL)shouldUseTextLayer:(CATextLayer *)textLayer forLabel:(NSString *)labelString {
    return [textLayer.string isEqualToString:labelString];
}

- (BOOL)shouldUseTextLayer:(CATextLayer *)textLayer withFont:(UIFont *)font {
    return [(__bridge NSString *)CGFontCopyFullName((CGFontRef)textLayer.font) isEqualToString:font.familyName];
}

- (void)animateTextLayer:(CATextLayer *)textLayer toFrame:(CGRect)frame duration:(CFTimeInterval)duration {
    if (duration > 0) {
        if (CGRectEqualToRect(textLayer.frame, CGRectZero)) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.fromValue = @0;
            animation.toValue = @1;
            animation.duration = duration;
            [textLayer addAnimation:animation forKey:@"opacity"];
        } else {
            [textLayer animateFromFrame:textLayer.frame toFrame:frame duration:duration];
        }
    }
    textLayer.frame = frame;
}

- (void)removeTextLayer:(CATextLayer *)textLayer toFrame:(CGRect)frame duration:(CFTimeInterval)duration {
    if (duration > 0) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animation.fromValue = @1;
        animation.toValue = @0;
        animation.duration = duration;
        animation.delegate = self;
        [animation setValue:textLayer forKey:@"animationLayer"];
        [textLayer addAnimation:animation forKey:@"opacity"];
    } else {
        [textLayer removeFromSuperlayer];
    }
}

@end
