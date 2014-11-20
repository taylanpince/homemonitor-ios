//
//  LineGraphAxisAnimator.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-29.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LineGraphAxisLayer.h"

@interface LineGraphAxisAnimator : NSObject

// TODO find a better solution than passing around so many values
- (void)animateAxisLayer:(LineGraphAxisLayer *)axisLayer
              tickValues:(NSArray *)tickValues
                  labels:(NSArray *)labels
                plotArea:(CGRect)plotArea
              valueRange:(CGRect)valueRange
                toFrames:(NSArray *)labelFrames
                duration:(CFTimeInterval)duration;

- (void)animateTicksForLayer:(LineGraphAxisLayer *)axisLayer
                      toPath:(CGPathRef)path
                     toFrame:(CGRect)frame
                  tickValues:(NSArray *)tickValues
                    plotArea:(CGRect)plotArea
                  valueRange:(CGRect)valueRange
                    duration:(CFTimeInterval)duration;

@end
