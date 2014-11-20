//
//  LineGraphTickInterval.h
//  LineGraphView
//
//  Created by Mark Reist on 2014-08-01.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LineGraphTickInterval : NSObject <NSDecimalNumberBehaviors>

@property (nonatomic, readonly) NSDecimalNumber *interval;
@property (nonatomic, readonly) NSDecimalNumber *offset;
@property (nonatomic) short scale;
@property (nonatomic, copy) NSString *(^labelBlock)(NSDecimalNumber *);

+ (LineGraphTickInterval *)intervalWithInterval:(NSDecimalNumber *)interval offset:(NSDecimalNumber *)offset scale:(short)scale;

- (NSArray *)ticksForStart:(CGFloat)start end:(CGFloat)end;
- (NSArray *)labelsForStart:(CGFloat)start end:(CGFloat)end;


@end
