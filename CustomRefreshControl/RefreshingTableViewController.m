//
//  RefreshingTableViewController.m
//  CustomRefreshControl
//
//  Created by Sean Wertheim on 6/19/15.
//  Copyright (c) 2015 Sean Wertheim. All rights reserved.
//

#import "RefreshingTableViewController.h"

@interface RefreshingTableViewController ()

@property (strong, nonatomic) UIImageView *blueBall;
@property (strong, nonatomic) UIImageView *yellowBall;

@property (assign, nonatomic) BOOL refreshIconCentersOverlap;
@property (assign, nonatomic) BOOL refreshIsAnimating;

@end

@implementation RefreshingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor clearColor];
    [self setupRefreshControl];
    
}

- (void)setupRefreshControl {
    [self setupPullToRefreshBalls];
   
    [self.refreshControl setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"stars_background"]]];
    [self.refreshControl addSubview:self.blueBall];
    [self.refreshControl addSubview:self.yellowBall];
    
    // When activated, invoke our refresh function
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
}

- (void)setupPullToRefreshBalls {
    self.blueBall = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blue-circle"]];
    self.yellowBall = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yellow-circle"]];
    
    CGFloat blueDiameter = CGRectGetHeight(self.refreshControl.bounds) - 10; // blue circle will fill bounds
    CGFloat yellowDiameter = blueDiameter / 4.f;
    
    self.blueBall.frame = CGRectMake(0, -80, blueDiameter, blueDiameter);
    self.yellowBall.frame = CGRectMake(CGRectGetWidth(self.refreshControl.bounds) - yellowDiameter, -80, yellowDiameter, yellowDiameter);
}



- (void)refresh:(id)sender {
    // -- DO SOMETHING AWESOME (... or just wait 3 seconds) --
    // This is where you'll make requests to an API, reload data, or process information
    double delayInSeconds = 3.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"DONE");
        
        // When done requesting/reloading/processing invoke endRefreshing, to close the control
        [self.refreshControl endRefreshing];
    });
    // -- FINISHED SOMETHING AWESOME, WOO! --
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    static NSString *cellId = @"cellId";
    cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"This is cell number %ld", (long)indexPath.row];
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    NSLog(@"Refresh control frame is: %@", NSStringFromCGRect(self.refreshControl.frame));
    
    CGFloat pullDistance = -self.refreshControl.frame.origin.y;
    CGFloat animationThreshold = 120.f;
    CGFloat pullRatio = MIN(pullDistance / animationThreshold, 1.f);
    NSLog(@"pull distance is %f and pull ratio is %f",pullDistance, pullRatio);
    
    CGFloat yellowBallCenterX = CGRectGetMidX(self.refreshControl.frame) + (1.f - pullRatio) * CGRectGetWidth(self.refreshControl.bounds);
    CGFloat yellowBallCenterY = -CGRectGetMidY(self.refreshControl.frame);
    NSLog(@"Yellowball frame is now %@", NSStringFromCGRect(self.yellowBall.frame));
    
    CGFloat blueBallCenterX = CGRectGetMidX(self.refreshControl.frame) - (1.f - pullRatio) * CGRectGetWidth(self.refreshControl.bounds);
    CGFloat blueBallCenterY = -CGRectGetMidY(self.refreshControl.frame);
    
    //when icons overlap for first time
    if (fabs(yellowBallCenterX - blueBallCenterX) <= 1) {
        self.refreshIconCentersOverlap = YES;
    }
    
    //Keep icons together while we are refreshing
    if (!self.refreshIsAnimating && self.refreshIconCentersOverlap && (!self.tableView.tracking  || !self.refreshControl.isRefreshing)) {
        yellowBallCenterX = CGRectGetMidX(self.refreshControl.frame);
        blueBallCenterX = CGRectGetMidX(self.refreshControl.frame);
    }
    
    [self.yellowBall setCenter: CGPointMake(yellowBallCenterX, yellowBallCenterY)];
    [self.blueBall setCenter: CGPointMake(blueBallCenterX, blueBallCenterY)];
    
    NSLog(@"Blueball frame is now %@", NSStringFromCGRect(self.blueBall.frame));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // If we're refreshing and the animation is not playing, then play the animation
    if (self.refreshControl.isRefreshing && !self.refreshIsAnimating) {
        [self animateRefreshView];
    }
}

- (void)animateRefreshView
{
    // Flag that we are animating
    self.refreshIsAnimating = YES;
    
    [self startOrbitAnimation];
    
}

- (void) startOrbitAnimation {
    
    self.refreshIconCentersOverlap = NO;
    
    CGFloat orbitDistance = 10.f;
    CGFloat orbitRadius = self.blueBall.frame.size.width / 2.f + orbitDistance;
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         
                         // Rotate the spinner by M_PI_2 = PI/2 = 90 degrees
                         self.yellowBall.frame = CGRectOffset(self.yellowBall.frame, -orbitRadius, 0);
                     }
                     completion:^(BOOL finished) {
                         [self backPlanetOrbit];
                    }];
}



- (void)backPlanetOrbit {
    CGFloat orbitDistance = 10.f;
    CGFloat orbitRadius = self.blueBall.frame.size.width / 2.f + orbitDistance;
    
    [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.yellowBall.layer.zPosition -= 1;
        self.yellowBall.frame = CGRectOffset(self.yellowBall.frame, 2 * orbitRadius, 0);
    } completion:^(BOOL finished) {
        [self frontPlanetOrbit];
    }];
}

- (void)frontPlanetOrbit {
    CGFloat orbitDistance = 10.f;
    CGFloat orbitRadius = self.blueBall.frame.size.width / 2.f + orbitDistance;
    
    [UIView animateWithDuration:0.6 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.yellowBall.layer.zPosition += 1;
        self.yellowBall.frame = CGRectOffset(self.yellowBall.frame, - 2 * orbitRadius, 0);
    } completion:^(BOOL finished) {
        if (self.refreshControl.isRefreshing) {
            [self backPlanetOrbit];
        } else {
            [self resetAnimation];
        }
        
    }];
}

- (void)resetAnimation
{
    // Reset flags
    self.refreshIsAnimating = NO;
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
