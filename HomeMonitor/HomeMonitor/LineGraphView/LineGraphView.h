//
//  LineGraphView.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-07-09.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LineGraphTouchHandler.h"
#import "LineGraphAxisLayer.h"
#import "LineGraphTickInterval.h"
#import "LineGraphRangeCalculator.h"

@class LineGraphView;

/** Defines the animation style used in replacePointsInRange:withRange:plot: */
typedef NS_ENUM(NSInteger, LineGraphReplaceStyle) {
    /** Interpolates the points in start and destination paths for a smooth vertical transition */
    kLineGraphReplaceStyleInterpolate,
    /** Simple path replacement, uses default CAShapeLayer path transition */
    kLineGraphReplaceStyleSimple
};

@protocol LineGraphPlotAnimator <NSObject>

- (void)animateLayer:(CALayer *)layer duration:(CFTimeInterval)duration;
- (CAAnimation *)animation;

@end

/**
 Defines the data source for a LineGraphView.
*/
@protocol LineGraphViewDataSource <NSObject>

/** Number of data sets to be plotted in the view.
 
 @param lineGraphView The line graph view requesting the information.
*/
- (NSUInteger)numberOfPlotsInLineGraphView:(LineGraphView *)lineGraphView;

/** Array of CGPoints stored as NSValues.  Must be in ascending x-axis order.
 
 @param lineGraphView The view requesting the information.
 @param plot Index of the requested plot.
*/
- (NSArray *)lineGraphView:(LineGraphView *)lineGraphView plotPointsForPlot:(NSUInteger)plot;

/** Defines the color of the specified data plot.
 
 @param lineGraphView The view requesting the information.
 @param plot Index of the requested plot.
*/
- (UIColor *)lineGraphView:(LineGraphView *)lineGraphView lineColorForPlot:(NSUInteger)plot;

/** Defines the line width of the specified data plot.
 
 @param lineGraphView The view requesting the information.
 @param plot Index of the requested plot.
*/
- (CGFloat)lineGraphView:(LineGraphView *)lineGraphView lineWidthForPlot:(NSUInteger)plot;

@optional
/** Return a LineGraphTickInterval object describing how the x-axis of the view should be labeled.
 If this method returns an object, xAxisTickMarksInLineGraphView: and labelsForXAxisTickMarksInGraphView:
 will not be called.
 
 @param lineGraphView The view requesting the information.
*/
- (LineGraphTickInterval *)xAxisTickIntervalInLineGraphView:(LineGraphView *)lineGraphView;

/** Return a LineGraphTickInterval object describing how the y-axis of the view should be labeled.
 If this method returns an object, yAxisTickMarksInLineGraphView: and labelsForYAxisTickMarksInGraphView:
 will not be called.
 
 @param lineGraphView The view requesting the information.
*/
- (LineGraphTickInterval *)yAxisTickIntervalInLineGraphView:(LineGraphView *)lineGraphView;

/** X values for where tick marks should appear on the x-axis.  Should be an array of NSNumber.
 Values falling outside of the valueRange of the graph will not appear.
 
 @param lineGraphView The view requesting the information.
*/
- (NSArray *)xAxisTickMarksInLineGraphView:(LineGraphView *)lineGraphView;

/** Y values for where tick marks should appear on the y-axis.  Should be an array of NSNumber.
 Values falling outside of the valueRange of the graph will not appear.
 
 @param lineGraphView The view requesting the information.
*/
- (NSArray *)yAxisTickMarksInLineGraphView:(LineGraphView *)lineGraphView;

/** Array of NSString for labels.  Indexes should match those provided in xAxisTickMarksInLineGraphView:
 
 @param lineGraphView The view requesting the information.
*/
- (NSArray *)labelsForXAxisTickMarksInGraphView:(LineGraphView *)lineGraphView;

/** Array of NSString for labels.  Indexes should match those provided in yAxisTickMarksInLineGraphView:
 
 @param lineGraphView The view requesting the information.
*/
- (NSArray *)labelsForYAxisTickMarksInGraphView:(LineGraphView *)lineGraphView;

/** Defines the dash pattern for the plot.  See CAShapeLayer for acceptable values.
 
 @param lineGraphView The view requesting the dash pattern.
 @param plot Plot index.
*/
- (NSArray *)lineGraphView:(LineGraphView *)lineGraphView dashPatternForPlot:(NSUInteger)plot;

/** Defines the line cap for the plot.  See CAShapeLayer for acceptable values.  If not provided (or nil), default is
 kCALineCapRound for graphs with no dash pattern, otherwise kCALineCapButt.
 
 @param lineGraphView Line graph view.
 @param plot Plot index.
*/
- (NSString *)lineGraphView:(LineGraphView *)lineGraphView lineCapForPlot:(NSUInteger)plot;

/** Defines the line cap for the plot.  See CAShapeLayer for acceptable values.  If not provided (or nil), default is
 kCALineJoinRound.
 
 @param lineGraphView Line graph view.
 @param plot Plot index.
*/
- (NSString *)lineGraphView:(LineGraphView *)lineGraphView lineJoinForPlot:(NSUInteger)plot;

@end

/**
 Receieves information about LineGraphView gestures when touchesEnabled is set to true.  Delegate is separate from the concept
 of touch handlers on the view, and should be used to render information outside of the view, whereas touch handlers are used
 to render layers on or within the view itself.
*/
@protocol LineGraphViewDelegate <NSObject>

@optional
/** When touchesEnabled is set on a LineGraphView, this delegate method will be called during start or movement of a
 long press gesture.
 
 @param lineGraphView The view receiving the gesture.
 @param value The CGPoint of the nearest data point.
 @param plot The plot receiving the touch.
*/
- (void)lineGraphView:(LineGraphView *)lineGraphView didPanToValue:(NSValue *)value plot:(NSUInteger)plot;

/** When touchesEnabled is set on a LineGraphView, this delegate method will be called during the start of movement of a
 pinch gesture.
 
 @param lineGraphView The view receing the gesture.
 @param values Array of two NSValue (CGPoint) with the two nearest data points.
 @param plot Index of the plot receiving the touch.
*/
- (void)lineGraphView:(LineGraphView *)lineGraphView didPinchWithValues:(NSArray *)values plot:(NSUInteger)plot;

@end

/**
 LineGraphView.
*/
@interface LineGraphView : UIView

/** dataSource defines which object is providing data for the line graph.  Initial load is done when this property is set. */
@property (nonatomic, weak) id<LineGraphViewDataSource> dataSource;

/** Delegate for receiving updates when touchesEnabled is true. */
@property (nonatomic, weak) id<LineGraphViewDelegate> delegate;

/** Defines the location of the x-axis. */
@property (nonatomic) LineGraphAxisPosition xAxisPosition;

/** Defines the location of the y-axis. */
@property (nonatomic) LineGraphAxisPosition yAxisPosition;

/** Manual gutters/insets at the edges of the graph.  Does not typically need to be set due to automatic calculations. */
@property (nonatomic) UIEdgeInsets graphInsets;

/** Font for the axis labels. */
@property (nonatomic, strong) UIFont *labelFont;

/** Color of the axis lines and labels. */
@property (nonatomic, strong) UIColor *axisColor;

/** Object used to determine how the value range of the graph is calculated.  If set to nil, value range will either
 be taken from the valueRange property of the view, or calculated to the minimum range required to fit the current
 values of the plots.
*/
@property (nonatomic, copy) LineGraphRangeCalculator *valueRangeObject;

/** The value range of the graph.  Will be automatically calculated if this value is set to CGRectZero (default).  Will
 only be used if valueRangeObject is set to nil. */
@property (nonatomic) CGRect valueRange;

/** Length, in pixels, of the axis ticks. */
@property (nonatomic) CGFloat tickLength;

/** Justification of the x-axis labels relative to the ticks. */
@property (nonatomic) LineGraphXAlignment xAlignment;

/** Whether touches are enabled on the graph.  When set to true, delegate will receieve updates and any added touch handlers will be active. */
@property (nonatomic) BOOL touchesEnabled;

/** Default animation duration for animateToFrame and endUpdate (queued) animation calls. */
@property (nonatomic) CFTimeInterval animationDuration;

/** Defines the layout and animation controller for the axes. */
@property (nonatomic) LineGraphAxisAnimator *axisAnimator;

/** Defines whether plot lines appear on top of the axes.  Defaults to TRUE. */
@property (nonatomic) BOOL plotShouldOverlayAxes;

/** Reload data from the dataSource */
- (void)reloadData;

/** Calls animateToFrame:duration: using the animationDuration property.
 
  @param frame The updated frame.
*/
- (void)animateToFrame:(CGRect)frame;

/** Animates the frame property, smoothly transitioning plots and axes.  Sets the frame property.
 
 @param frame The updated frame.
 @param duration Number of seconds over which the animation will occur.
 */
- (void)animateToFrame:(CGRect)frame duration:(CFTimeInterval)duration;

/** Adds a touch handler to the line graph, for providing visual feedback for pinch and long press gestures.
 
 @param touchHandler Touch handler to be added.
 @param plot Which plot index the touch handler will be active for.
*/
- (void)addTouchHandler:(LineGraphTouchHandler *)touchHandler plot:(NSUInteger)plot;

/** Cancels any touches currently active on the view. */
- (void)cancelTouches;

/**
 Currently a hacktastic solution to having multiple separate "plots" that react to the same pinch gesture handler, and can
 therefore be spanned.
 
 @param maskedPlot The plot index to mask.
 @param targetPlot The target plot.  Pinch gestures spanning both plots will be reported to lineGraphView:didPinchWithValues:plot: and touch handlers as coming from this plot.
*/
- (void)maskPlot:(NSUInteger)maskedPlot toPlot:(NSUInteger)targetPlot;

/**
 Removes masking from the specified plot.
 
 @param maskedPlot Plot index to remove masking from.
*/
- (void)removeMaskForPlot:(NSUInteger)maskedPlot;

/**
 Starts an animation block.  Animation methods (insert, delete, replace/reload) are queued until endUpdates is called.
*/
- (void)beginUpdates;

/**
 End an animation block.  Reloads the plot data and executes any queued animations.
*/
- (void)endUpdates;

/** Calls insertPointsAtIndexPath:count:withPointAnimation: with default animation of kLineGraphAnimationFadeIn
 
 @param indexPath Start index (post-reload) of the data section to be inserted.
 @param count Number of data points to be inserted.
*/
- (void)insertPointsAtIndexPath:(NSIndexPath *)indexPath count:(NSInteger)count;

/** Animate the insertion of a new section of the graph.
 
 @param indexPath Start index (post-reload) of the data section to be inserted.
 @param count Number of data points to be inserted.
 @param animator Animator instance for animating the insertion.
*/
- (void)insertPointsAtIndexPath:(NSIndexPath *)indexPath count:(NSInteger)count animator:(id<LineGraphPlotAnimator>)animator;

/** Calls deletePointsAtIndexPath:count:withPointAnimation: with default animation of kLineGraphAnimationFadeOut

 @param indexPath Start index (pre-reload) of the data section to be deleted.
 @param count Number of data points to be removed.
*/
- (void)deletePointsAtIndexPath:(NSIndexPath *)indexPath count:(NSUInteger)count;

/** Animates removal of an existing section of the graph.
 
 @param indexPath Start index (pre-reload) of the data section to be deleted.
 @param count Number of data points to be removed.
 @param animator Animator instance for animating the deletion.
*/
- (void)deletePointsAtIndexPath:(NSIndexPath *)indexPath count:(NSUInteger)count animator:(id<LineGraphPlotAnimator>)animator;

/** Transforms a section of the graph.  Defaults to interpolated animation style.
 
 @param startRange Range (pre-reload) of the data that will be transformed.
 @param endRange Range (post-reload) of the data being transformed to.
 @param plot Plot index.  Does not currently support changes in plot index during transformation.
 */
- (void)replacePointsInRange:(NSRange)startRange withRange:(NSRange)endRange plot:(NSUInteger)plot;

/** Transforms a section of the graph.
 
 @param startRange Range (pre-reload) of the data that will be transformed.
 @param endRange Range (post-reload) of the data being transformed to.
 @param plot Plot index.  Does not currently support changes in plot index during transformation.
 @param animationStyle Determines which path transformation style is used.
*/
- (void)replacePointsInRange:(NSRange)startRange withRange:(NSRange)endRange plot:(NSUInteger)plot animationStyle:(LineGraphReplaceStyle)animationStyle;

/**
 Animates insertion of a new plot.  Must be used within an update block.
 
 @param plot Index (post-reload) of the plot to insert.
 @param animator Animator instance for animating the insertion.
*/
- (void)insertPlot:(NSUInteger)plot animator:(id<LineGraphPlotAnimator>)animator;

/**
 Animates removal of an existing plot.  Must be used within an update block.
 
 @param plot Index (pre-reload) of the plot to delete.
 @param animator Animator instance for animating the deletion.
*/
- (void)deletePlot:(NSUInteger)plot animator:(id<LineGraphPlotAnimator>)animator;

/**
 Convenience method.  Interally calls replacePointsInRange:withRange:plot: for equal ranges.
 @param indexPath Starting index.
 @param count Length of the range to reload.
*/
- (void)reloadDataAtIndexPath:(NSIndexPath *)indexPath count:(NSUInteger)count;

/**
 Convenience method.  Interally calls replacePointsInRange:withRange:plot: for equal ranges.
 @param indexPath Starting index.
 @param count Length of the range to reload.
 @param animationStyle Determines with path transformation style is used.
 */
- (void)reloadDataAtIndexPath:(NSIndexPath *)indexPath count:(NSUInteger)count animationStyle:(LineGraphReplaceStyle)animationStyle;

@end

