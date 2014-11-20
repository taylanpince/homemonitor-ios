//
//  HMOGraph.h
//  HomeMonitor
//
//  Created by Taylan Pince on 2014-11-19.
//  Copyright (c) 2014 Hipo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface HMOGraph : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSMutableArray *values;
@property (nonatomic, assign, readonly) CGRect valueRange;
@property (nonatomic, strong) UIColor *lineColor;

- (instancetype)initWithName:(NSString *)name;

- (void)addValue:(Float32)value;

@end
