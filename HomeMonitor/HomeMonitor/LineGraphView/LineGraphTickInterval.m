//
//  LineGraphTickInterval.m
//  LineGraphView
//
//  Created by Mark Reist on 2014-08-01.
//  Copyright (c) 2014 Hippo Foundry. All rights reserved.
//

#import "LineGraphTickInterval.h"

@implementation LineGraphTickInterval

+ (LineGraphTickInterval *)intervalWithInterval:(NSDecimalNumber *)interval offset:(NSDecimalNumber *)offset scale:(short)scale {
    return [[LineGraphTickInterval alloc] initWithInterval:interval offset:offset scale:scale];
}

- (id)initWithInterval:(NSDecimalNumber *)interval offset:(NSDecimalNumber *)offset scale:(short)scale {
    self = [super init];
    
    if (self) {
        _interval = interval;
        _offset = offset;
        _scale = scale;
    }
    
    return self;
}

- (NSArray *)ticksForStart:(CGFloat)start end:(CGFloat)end {
    NSDecimalNumber *value = [[[[NSDecimalNumber alloc] initWithDouble:floor((start + self.offset.doubleValue) / self.interval.doubleValue)] decimalNumberByMultiplyingBy:self.interval withBehavior:self] decimalNumberBySubtracting:self.offset withBehavior:self];

    NSMutableArray *returnArray = [NSMutableArray array];
    
    while (value.doubleValue <= end) {
        if (value.doubleValue >= start)
            [returnArray addObject:[value copy]];
        value = [value decimalNumberByAdding:self.interval withBehavior:self];
    }
    
    return returnArray;
}

- (NSArray *)labelsForStart:(CGFloat)start end:(CGFloat)end {
    NSDecimalNumber *value = [[[[NSDecimalNumber alloc] initWithDouble:floor((start + self.offset.doubleValue) / self.interval.doubleValue)] decimalNumberByMultiplyingBy:self.interval withBehavior:self] decimalNumberBySubtracting:self.offset withBehavior:self];
    
    NSMutableArray *returnArray = [NSMutableArray array];
    
    while (value.doubleValue <= end) {
        if (value.doubleValue >= start)
            [returnArray addObject:self.labelBlock ? self.labelBlock(value) : [value stringValue]];
        value = [value decimalNumberByAdding:self.interval withBehavior:self];
    }

    return returnArray;
}

#pragma mark - NSDecimalNumberBehaviors

- (NSRoundingMode)roundingMode {
    return [[NSDecimalNumber defaultBehavior] roundingMode];
}

- (NSDecimalNumber *)exceptionDuringOperation:(SEL)method error:(NSCalculationError)error leftOperand:(NSDecimalNumber *)leftOperand rightOperand:(NSDecimalNumber *)rightOperand {
    
    return [[NSDecimalNumber defaultBehavior] exceptionDuringOperation:method error:error leftOperand:leftOperand rightOperand:rightOperand];
}

- (short)scale {
    return _scale;
}

@end
