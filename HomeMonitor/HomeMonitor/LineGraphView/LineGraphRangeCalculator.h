//
//  LineGraphRangeCalculator.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-08-06.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** Instantiated object to control how the value range for a graph view is generated.
 
 Usage note: if you set both a value and an inset, the inset will be applied after the provided
 value has been set.
*/

@interface LineGraphRangeCalculator : NSObject <NSCopying>

/** Minimum value for the x-axis. */
@property (nonatomic) CGFloat xMinValue;
/** Maximum value for the x-axis. */
@property (nonatomic) CGFloat xMaxValue;
/** Minimum value for the y-axis. */
@property (nonatomic) CGFloat yMinValue;
/** Maximum value for the y-axis. */
@property (nonatomic) CGFloat yMaxValue;

/** Extra value range provided at the low end of the x-axis. */
@property (nonatomic) CGFloat xLeftInset;
/** Extra value range provided at the high end of the x-axis. */
@property (nonatomic) CGFloat xRightInset;
/** Extra value range provided at the hight end of the y-axis. */
@property (nonatomic) CGFloat yTopInset;
/** Extra value range provided at the low end of the y-axis. */
@property (nonatomic) CGFloat yBottomInset;

/** Convenience method for setting all inset values at once.  Used during init
 to set UIEdgeInsetsZero.
 
 @param insets Insets to be added to the value range.
*/
- (void)setInsets:(UIEdgeInsets)insets;

/** Set auto-calculation of the x-axis.  Resets any values previously provided to xMinValue or xMaxValue. */
- (void)setAutoCalculateX;
/** Set auto-calculation of the x-axis.  Resets any values previously provided to yMinValue or yMaxValue. */
- (void)setAutoCalculateY;

/** The main function of the calculator, returns a new range based on the range calculated by the graph view.
 
 @param originalRange The minimum value range to contain the plot points.
*/
- (CGRect)getValueRangeFromRange:(CGRect)originalRange;

@end
