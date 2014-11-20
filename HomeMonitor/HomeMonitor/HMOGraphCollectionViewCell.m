//
//  HMOGraphCollectionViewCell.m
//  HomeMonitor
//
//  Created by Taylan Pince on 2014-11-19.
//  Copyright (c) 2014 Hipo. All rights reserved.
//

#import "HMOGraphCollectionViewCell.h"


@implementation HMOGraphCollectionViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [_graphView removeFromSuperview];
    
    _graphView = nil;
}

- (void)setGraphView:(LineGraphView *)graphView {
    if (_graphView) {
        [_graphView removeFromSuperview];
        
        _graphView = nil;
    }
    
    if (graphView) {
        _graphView = graphView;
        
        [self.contentView addSubview:_graphView];
    }
}

@end
