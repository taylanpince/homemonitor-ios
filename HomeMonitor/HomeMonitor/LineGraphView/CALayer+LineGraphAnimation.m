#import "CALayer+LineGraphAnimation.h"

@implementation CALayer (LineGraphAnimation)

- (void)animateFromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame duration:(CFTimeInterval)duration {
    CAAnimationGroup *animations = [CAAnimationGroup animation];
    
    CGPoint newPosition = CGPointMake(CGRectGetMidX(toFrame),CGRectGetMidY(toFrame));
    CGRect newBounds = CGRectMake(0,0,CGRectGetWidth(toFrame),CGRectGetHeight(toFrame));
    
    if (duration > 0) {
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(fromFrame),CGRectGetMidY(fromFrame))];
        positionAnimation.toValue = [NSValue valueWithCGPoint:newPosition];
        
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.fromValue = [NSValue valueWithCGRect:CGRectMake(0,0,CGRectGetWidth(fromFrame),CGRectGetHeight(fromFrame))];
        boundsAnimation.toValue = [NSValue valueWithCGRect:newBounds];
        
        [animations setDuration:duration];
        [animations setAnimations:@[positionAnimation,boundsAnimation]];
        
        [self addAnimation:animations forKey:nil];
    }
    
    self.bounds = newBounds;
    self.position = newPosition;
}

@end

@implementation CAShapeLayer (LineGraphAnimation)

- (void)animateFromFrame:(CGRect)fromFrame toFrame:(CGRect)toFrame duration:(CFTimeInterval)duration path:(CGPathRef)path {
    
    [super animateFromFrame:fromFrame toFrame:toFrame duration:duration];
    
    if (self.path) {
        if (duration > 0) {
            CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
            pathAnimation.values = @[(id)self.path, (__bridge id)path];
            pathAnimation.duration = duration;
            
            [self addAnimation:pathAnimation forKey:@"path"];
        }
        
        self.path = path;
    }
}

@end