//
//  UIColor+HMOColorAdditions.h
//  HomeMonitor
//
//  Created by Taylan Pince on 2014-11-20.
//  Copyright (c) 2014 Hipo. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIColor (HMOColorAdditions)

/** Generates a UIColor instance from any hex color code
 
 @param hexString hex string for the target color, can be in #aaa or #aaabbb format
 */
+ (UIColor *)colorFromHexString:(NSString *)hexString;

/** Global colors used by HomeMonitor
 */
+ (UIColor *)backgroundColor;
+ (UIColor *)graphColor;
+ (UIColor *)lightTitleColor;
+ (UIColor *)buttonTitleColor;
+ (UIColor *)separatorColor;

@end
