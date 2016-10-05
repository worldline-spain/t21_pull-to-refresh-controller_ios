//
//  T21PullToRefreshController.m
//  MyApp
//
//  Created by David Arrufat on 15/06/15.
//  Copyright (c) 2015 Tempos21. All rights reserved.
//

#import "T21PullToRefreshController.h"

@interface T21PullToRefreshController ()

@property (nonatomic,strong) NSMapTable *refreshBlocks;
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
        self.refreshBlocks = [NSMapTable weakToStrongObjectsMapTable];
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
        
        [_refreshBlocks setObject:refreshBlock forKey:refreshControl];
        [_refreshControls setObject:refreshControl forKey:scrollView];
    }
    return refreshControl;
}

- (void) removePullToRefresh:(UIScrollView *)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl) {
        [_refreshBlocks removeObjectForKey:refreshControl];
        [refreshControl removeFromSuperview];
        refreshControl = nil;
    }
}

- (UIRefreshControl*) createGenericRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    return refreshControl;
}

#pragma mark - Animation methods

- (void) startPullToRefreshAnimation:(UIScrollView*)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    [self animateRefreshControl:refreshControl];
}

- (void) resetPullToRefreshAnimation:(UIScrollView*)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl && refreshControl.refreshing) {
        [refreshControl endRefreshing];
    }
}

- (void) animateRefreshControl:(UIRefreshControl*)refreshControl
{
    if (refreshControl && !refreshControl.refreshing) {
        UIScrollView *scrollView = (UIScrollView*)refreshControl.superview;
        [refreshControl beginRefreshing];
        if([scrollView isKindOfClass:[UIScrollView class]]){ //The beginRefreshing action doesn't scroll automatically to the refreshControl contentOffset
            [scrollView setContentOffset:CGPointMake(0, -refreshControl.frame.size.height) animated:YES];
        }
    }
}

#pragma mark - Pull to refresh by code

- (void) performPullToRefresh:(UIScrollView*)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl)
    {
        [self executeRefreshBlock:refreshControl];
    }
}

- (void) executeRefreshBlock:(UIRefreshControl*)refreshControl
{
    void(^refreshBlock)() = [_refreshBlocks objectForKey:refreshControl];
    if (refreshBlock) {
        [self animateRefreshControl:refreshControl];
        refreshBlock();
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
    [self executeRefreshBlock:refreshControl];
}

@end
