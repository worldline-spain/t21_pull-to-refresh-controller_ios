//
//  T21PullToRefreshController.m
//  MyApp
//
//  Created by David Arrufat on 15/06/15.
//  Copyright (c) 2015 Tempos21. All rights reserved.
//

#import "T21PullToRefreshController.h"

@interface T21PullToRefreshControllerInternalState : NSObject

@property (nonatomic) NSNumber * isAnimating;
@property (nonatomic,copy) void (^refreshBlock)();

@end

@interface T21PullToRefreshController ()

@property (nonatomic,strong) NSMapTable *refreshStates;
@property (nonatomic,strong) NSMapTable *refreshControls;

@end

@implementation T21PullToRefreshController

+ (T21PullToRefreshController *)getInstance {
    static T21PullToRefreshController *_getInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _getInstance = [[self alloc] init];
    });
    return _getInstance;
}

- (id) init
{
    self = [super init];
    if (self) {
        self.refreshStates = [NSMapTable weakToStrongObjectsMapTable];
        self.refreshControls = [NSMapTable weakToWeakObjectsMapTable];
    }
    return self;
}

#pragma mark - Add/Remove pull to refresh methods

- (UIRefreshControl*) addPullToRefresh:(UIScrollView *)scrollView withRefreshBlock:(void (^)(void))refreshBlock
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (!refreshControl && [scrollView isKindOfClass:[UIScrollView class]]) {
        refreshControl = [self createGenericRefreshControl];
        [scrollView addSubview:refreshControl];
        
        T21PullToRefreshControllerInternalState * state = [[T21PullToRefreshControllerInternalState alloc] init];
        state.refreshBlock = refreshBlock;
        
        [_refreshStates setObject:state forKey:refreshControl];
        [_refreshControls setObject:refreshControl forKey:scrollView];
    }
    return refreshControl;
}

- (void) removePullToRefresh:(UIScrollView *)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl) {
        [_refreshStates removeObjectForKey:refreshControl];
        [refreshControl removeFromSuperview];
        refreshControl = nil;
    }
}

- (UIRefreshControl*) createGenericRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    
    //ios 10 fix:
    refreshControl.backgroundColor = UIColor.clearColor;
    
    return refreshControl;
}

#pragma mark - Animation methods

- (void) startPullToRefreshAnimation:(UIScrollView*)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    [self animateRefreshControl:refreshControl wasForced:YES];
}

- (void) finishPullToRefreshAnimation:(UIScrollView*)scrollView {
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl) {
        T21PullToRefreshControllerInternalState * state = [_refreshStates objectForKey:refreshControl];
        if (state && state.isAnimating.boolValue) {
            // ugly trick to ensure the refresh control has time to be shown
            // we found some issues showing the refresh control even after the viewDidLoad and viewWillAppear methods.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                state.isAnimating = @NO;
                [refreshControl endRefreshing];
            });
        }
    }
}

- (void) resetPullToRefreshAnimation:(UIScrollView*)scrollView //deprecated
{
    [self finishPullToRefreshAnimation:scrollView];
}

- (BOOL)isPullToRefreshAnimating:(UIScrollView*)scrollView {
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl) {
        T21PullToRefreshControllerInternalState * state = [_refreshStates objectForKey:refreshControl];
        if (state) {
            return state.isAnimating.boolValue;
        }
    }
    return NO;
}

- (void) animateRefreshControl:(UIRefreshControl*)refreshControl wasForced:(BOOL)wasForced
{
    T21PullToRefreshControllerInternalState * state = [_refreshStates objectForKey:refreshControl];
    // ugly trick to ensure the refresh control has time to be shown
    // we found some issues showing the refresh control even after the viewDidLoad and viewWillAppear methods.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (state && !state.isAnimating.boolValue) {
            state.isAnimating = @YES;
            if (wasForced) {
                UIScrollView *scrollView = (UIScrollView*)refreshControl.superview;
                if([scrollView isKindOfClass:[UIScrollView class]]){
                    // UIViewControllers manage automatically the inset calculation when a refresh control begins
                    // (taking in account the status bar and navigation bar)
                    // In order to get the exact height of the refreshControl we inspect the contentInset increment
                    CGFloat prevInset = scrollView.contentInset.top;
                    [refreshControl beginRefreshing];
                    
                    //The beginRefreshing action doesn't scroll automatically to the refreshControl contentOffset
                    CGFloat currentInset = scrollView.contentInset.top;
                    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y - fabs(currentInset - prevInset)) animated:YES];
                }
            }
        }
    });
}

#pragma mark - Pull to refresh by code

- (void) performPullToRefresh:(UIScrollView*)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl)
    {
        [self animateRefreshControl:refreshControl wasForced:YES];
        [self executeRefreshBlock:refreshControl];
    }
}

- (void) executeRefreshBlock:(UIRefreshControl*)refreshControl
{
    T21PullToRefreshControllerInternalState * state = [_refreshStates objectForKey:refreshControl];
    if (state) {
        state.refreshBlock();
    }
}

#pragma mark - Helper methods

- (BOOL) hasPullToRefresh:(UIScrollView *)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl) {
        return YES;
    }
    return NO;
}

#pragma mark - UIRefreshControl delegate

- (void) handleRefresh:(UIRefreshControl*)refreshControl
{
    T21PullToRefreshControllerInternalState * state = [_refreshStates objectForKey:refreshControl];
    if (state) {
        [self animateRefreshControl:refreshControl wasForced:NO];
        [self executeRefreshBlock:refreshControl];
    }
}

@end



@implementation T21PullToRefreshControllerInternalState

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isAnimating = @NO;
        self.refreshBlock = nil;
    }
    return self;
}

@end
