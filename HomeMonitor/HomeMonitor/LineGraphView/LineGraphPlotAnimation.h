//
//  LineGraphPlotAnimator.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-08-06.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LineGraphView.h"

/** Defines the type of animation used during an insertPoints or deletePoints operation */
typedef NS_ENUM(NSInteger, LineGraphPlotAnimationType) {
    /** No animation, graph section immediately appears or disappears */
    kLineGraphAnimationNone,
    /** Graph section draws in left-to-right */
    kLineGraphAnimationStroke,
    /** Graph section draws in right-to-left */
    kLineGraphAnimationStrokeLeft,
    /** Graph section draws out left-to-right */
    kLineGraphAnimationUnstroke,
    /** Graph section draws out right-to-left */
    kLineGraphAnimationUnstrokeLeft,
    /** Graph section opacity fades out */
    kLineGraphAnimationFadeOut,
    /** Graph section opacity fades in */
    kLineGraphAnimationFadeIn
};

@interface LineGraphPlotAnimation : NSObject <LineGraphPlotAnimator>

+ (LineGraphPlotAnimation *)animationOfType:(LineGraphPlotAnimationType)animationType;

@end