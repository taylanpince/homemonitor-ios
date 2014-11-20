//
//  HMOGraphCollectionViewCell.h
//  HomeMonitor
//
//  Created by Taylan Pince on 2014-11-19.
//  Copyright (c) 2014 Hipo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LineGraphView.h"


@interface HMOGraphCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) LineGraphView *graphView;

@end
