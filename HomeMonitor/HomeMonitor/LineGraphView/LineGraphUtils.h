//
//  LineGraphUtils.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-28.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef LineGraphView_LineGraphUtils_h
#define LineGraphView_LineGraphUtils_h

float OffsetXForValue(float value, CGRect bounds, CGRect valueRange);
float PlotXForValue(float value, CGRect bounds, CGRect valueRange);
float ValueForPlotX(float x, CGRect bounds, CGRect valueRange);
float OffsetYForValue(float value, CGRect bounds, CGRect valueRange);
float PlotYForValue(float value, CGRect bounds, CGRect valueRange);

#endif
