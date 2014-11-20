//
//  LineGraphPinchHandler.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-18.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphTouchHandler.h"

@interface LineGraphPinchHandler : LineGraphTouchHandler

@property (nonatomic, strong) CAShapeLayer *layer;
@property (nonatomic) CGFloat circleRadius;

@end
