//
//  HMORootViewController.m
//  HomeMonitor
//
//  Created by Taylan Pince on 2014-11-19.
//  Copyright (c) 2014 Hipo. All rights reserved.
//

#import "BLE.h"
#import "LineGraphAxisAnimatorTranslate.h"
#import "LineGraphPlotAnimation.h"
#import "LineGraphView.h"
#import "PureLayout.h"

#import "HMOGraph.h"
#import "HMORootViewController.h"

#import "UIColor+HMOColorAdditions.h"


@interface HMORootViewController ()
<BLEDelegate, LineGraphViewDataSource, LineGraphViewDelegate>

@property (nonatomic, strong) BLE *bleController;
@property (nonatomic, strong) UIButton *connectButton;
@property (nonatomic, strong) LineGraphView *graphView;
@property (nonatomic, strong) HMOGraph *graph;
@property (nonatomic, strong) UILabel *temperatureLabel;

- (void)didTapConnectButton:(id)sender;

- (void)updateGraph;

@end


@implementation HMORootViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _bleController = [[BLE alloc] init];
        
        [_bleController controlSetup];
        [_bleController setDelegate:self];
        
        _graph = [[HMOGraph alloc] initWithName:NSLocalizedString(@"Atmospheric Pressure (Pa)", nil)];
        
        [_graph setLineColor:[UIColor graphColor]];
        
        for (NSInteger i = 0; i < 22; i++) {
            [_graph addValue:99700 + (arc4random_uniform(20) - 10)];
        }
    }
    
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor backgroundColor]];
    
    UILabel *pressureTitleLabel = [[UILabel alloc] initForAutoLayout];
    
    [pressureTitleLabel setBackgroundColor:self.view.backgroundColor];
    [pressureTitleLabel setTextAlignment:NSTextAlignmentCenter];
    [pressureTitleLabel setTextColor:[UIColor lightTitleColor]];
    [pressureTitleLabel setText:NSLocalizedString(@"Atmospheric Pressure (Pa)", nil)];
    [pressureTitleLabel setFont:[UIFont fontWithName:@"AzoSans-Regular" size:13.0]];
    
    [self.view addSubview:pressureTitleLabel];
    
    [pressureTitleLabel autoSetDimension:ALDimensionHeight toSize:17.0];
    [pressureTitleLabel autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(45.0, 10.0, 0.0, 10.0)
                                                 excludingEdge:ALEdgeBottom];
    
    UIView *pressureSeparatorView = [[UIView alloc] initForAutoLayout];
    
    [pressureSeparatorView setBackgroundColor:[UIColor separatorColor]];
    
    [self.view addSubview:pressureSeparatorView];
    
    [pressureSeparatorView autoSetDimension:ALDimensionHeight toSize:1.0];
    [pressureSeparatorView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
    [pressureSeparatorView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
    [pressureSeparatorView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:pressureTitleLabel withOffset:8.0];
    
    _graphView = [[LineGraphView alloc] initWithFrame:CGRectMake(0.0, 40.0, self.view.bounds.size.width, 200.0)];
    
    [_graphView setDelegate:self];
    [_graphView setDataSource:self];
    [_graphView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_graphView setAxisAnimator:[[LineGraphAxisAnimatorTranslate alloc] init]];
    [_graphView setGraphInsets:UIEdgeInsetsZero];
    [_graphView setAnimationDuration:0.2];
    [_graphView setXAxisPosition:kLineGraphAxisPositionNone];
    [_graphView setYAxisPosition:kLineGraphAxisPositionNone];
    [_graphView setAxisColor:[UIColor blackColor]];
    [_graphView setTickLength:1];
    
    [self.view addSubview:_graphView];
    
    [_graphView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0.0];
    [_graphView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0.0];
    [_graphView autoSetDimension:ALDimensionHeight toSize:200.0];
    [_graphView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:pressureSeparatorView withOffset:20.0];
    
    [_graphView setValueRange:_graph.valueRange];
    
    UILabel *temperatureTitleLabel = [[UILabel alloc] initForAutoLayout];
    
    [temperatureTitleLabel setBackgroundColor:self.view.backgroundColor];
    [temperatureTitleLabel setTextAlignment:NSTextAlignmentCenter];
    [temperatureTitleLabel setTextColor:[UIColor lightTitleColor]];
    [temperatureTitleLabel setText:NSLocalizedString(@"Temperature (°C)", nil)];
    [temperatureTitleLabel setFont:[UIFont fontWithName:@"AzoSans-Regular" size:13.0]];
    
    [self.view addSubview:temperatureTitleLabel];
    
    [temperatureTitleLabel autoSetDimension:ALDimensionHeight toSize:17.0];
    [temperatureTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
    [temperatureTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
    [temperatureTitleLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_graphView withOffset:40.0];
    
    UIView *temperatureSeparatorView = [[UIView alloc] initForAutoLayout];
    
    [temperatureSeparatorView setBackgroundColor:[UIColor separatorColor]];
    
    [self.view addSubview:temperatureSeparatorView];
    
    [temperatureSeparatorView autoSetDimension:ALDimensionHeight toSize:1.0];
    [temperatureSeparatorView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
    [temperatureSeparatorView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:20.0];
    [temperatureSeparatorView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:temperatureTitleLabel withOffset:8.0];
    
    UIImageView *temperatureImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-temperature"]];
    
    [temperatureImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:temperatureImageView];
    
    [temperatureImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:temperatureSeparatorView withOffset:20.0];
    [temperatureImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    _temperatureLabel = [[UILabel alloc] initForAutoLayout];
    
    [_temperatureLabel setFont:[UIFont boldSystemFontOfSize:46.0]];
    [_temperatureLabel setTextColor:[UIColor whiteColor]];
    [_temperatureLabel setTextAlignment:NSTextAlignmentCenter];
    [_temperatureLabel setText:@"--"];
    
    [self.view addSubview:_temperatureLabel];
    
    [_temperatureLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:temperatureImageView withOffset:0.0];
    [_temperatureLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:temperatureImageView withOffset:0.0];
    [_temperatureLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:temperatureImageView withOffset:0.0];
    [_temperatureLabel autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:temperatureImageView withOffset:0.0];
    
    _connectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [_connectButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_connectButton setBackgroundColor:[UIColor separatorColor]];
    [_connectButton setTitleColor:[UIColor buttonTitleColor] forState:UIControlStateNormal];
    [_connectButton setTitleColor:[UIColor lightTitleColor] forState:UIControlStateDisabled];
    
    if ([_bleController isConnected]) {
        [_connectButton setTitle:NSLocalizedString(@"Disconnect", nil) forState:UIControlStateNormal];
    } else {
        [_connectButton setTitle:NSLocalizedString(@"Connect", nil) forState:UIControlStateNormal];
    }
    
    [_connectButton addTarget:self
                       action:@selector(didTapConnectButton:)
             forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_connectButton];
    
    [_connectButton autoSetDimension:ALDimensionHeight toSize:50.0];
    [_connectButton autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero
                                             excludingEdge:ALEdgeTop];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Control actions

- (void)didTapConnectButton:(id)sender {
    [_connectButton setEnabled:NO];
    
    if ([_bleController isConnected]) {
        // Disconnect
        [_bleController.CM cancelPeripheralConnection:_bleController.activePeripheral];
        
        [_connectButton setTitle:NSLocalizedString(@"Disconnecting...", nil) forState:UIControlStateNormal];
        [_connectButton setNeedsLayout];
    } else {
        // Connect
        [_bleController setPeripherals:nil];
        [_bleController findBLEPeripherals:5];
        
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if ([_bleController.peripherals count] > 0) {
                [_bleController connectPeripheral:[_bleController.peripherals objectAtIndex:0]];
            } else {
                [_connectButton setTitle:NSLocalizedString(@"Connect", nil) forState:UIControlStateNormal];
                [_connectButton setEnabled:YES];
                [_connectButton setNeedsLayout];
            }
        });
        
        [_connectButton setTitle:NSLocalizedString(@"Connecting...", nil) forState:UIControlStateNormal];
        [_connectButton setNeedsLayout];
    }
}

#pragma mark - Graph view delegate

- (NSUInteger)numberOfPlotsInLineGraphView:(LineGraphView *)lineGraphView {
    return 1;
}

- (NSArray *)lineGraphView:(LineGraphView *)lineGraphView plotPointsForPlot:(NSUInteger)plot {
    return _graph.values;
}

- (UIColor *)lineGraphView:(LineGraphView *)lineGraphView lineColorForPlot:(NSUInteger)plot {
    return _graph.lineColor;
}

- (CGFloat)lineGraphView:(LineGraphView *)lineGraphView lineWidthForPlot:(NSUInteger)plot {
    return 2.0;
}

- (NSArray *)lineGraphView:(LineGraphView *)lineGraphView dashPatternForPlot:(NSUInteger)plot {
    return @[@(1)];
}

#pragma mark - Bluetooth LE delegate

- (void)bleDidConnect {
    [_connectButton setTitle:NSLocalizedString(@"Disconnect", nil) forState:UIControlStateNormal];
    [_connectButton setEnabled:YES];
}

- (void)bleDidDisconnect {
    [_connectButton setTitle:NSLocalizedString(@"Connect", nil) forState:UIControlStateNormal];
    [_connectButton setEnabled:YES];
}

- (void)bleDidReceiveData:(unsigned char *)data length:(int)length {
    NSLog(@"Length: %d", length);
    
    // parse data, all commands are in 5-byte
    for (int i = 0; i < length; i += 5) {
        Float32 readingValue = data[i + 1] << 24 | data[i + 2] << 16 | data[i + 3] << 8 | data[i + 4];

        if (data[i] == 0x0A) {
            [_temperatureLabel setText:[NSString stringWithFormat:@"%1.1f", readingValue]];
            NSLog(@"TEMPERATURE: %1.2f Celcius", readingValue);
        } else if (data[i] == 0x0B) {
            [_graph addValue:readingValue];
            NSLog(@"PRESSURE: %1.2f Pa", readingValue);
        } else if (data[i] == 0x0C) {
            NSLog(@"ALTITUDE: %1.2fm", readingValue);
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateGraph];
    });
}

- (void)bleDidUpdateRSSI:(NSNumber *)rssi {
    NSLog(@">>> RSSI: %@", rssi);
}

#pragma mark - Graph updates

- (void)updateGraph {
    [_graphView beginUpdates];
    
    [_graphView insertPointsAtIndexPath:[NSIndexPath indexPathForRow:[_graph.values count] - 1 inSection:0]
                                  count:1
                               animator:[LineGraphPlotAnimation animationOfType:kLineGraphAnimationStroke]];
    
    [_graphView setValueRange:_graph.valueRange];
    
    [_graphView endUpdates];
}

@end
