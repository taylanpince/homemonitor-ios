//
//  LineGraphTouchHandler.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-18.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** Defines the type of gesture the touch handler is active for */
typedef NS_ENUM(NSInteger, LineGraphTouchType) {
    /** UIGestureRecognizerLongPress */
    kLineGraphTouchLongPress,
    /** UIGestureRecognizerPinch */
    kLineGraphTouchPinch
};

/** Abstract class for defining a touchHandler that may be added to a LineGraphView.

layer will be added as a sublayer to the graph and resized to match plotArea by the LineGraphView.
*/
@interface LineGraphTouchHandler : NSObject

@property (nonatomic) LineGraphTouchType touchType;
@property (nonatomic, strong) CALayer *layer;

- (void)updateAtCoordinates:(NSArray *)coordinates values:(NSArray *)values;
- (void)clear;
- (void)touchEnded;

@end
