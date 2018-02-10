//
//  UIScrollView+T21PullToRefreshUtils.m
//  MyApp
//
//  Created by David Arrufat on 15/06/15.
//  Copyright (c) 2015 Tempos21. All rights reserved.
//

#import "UIScrollView+T21PullToRefreshUtils.h"
#import "T21PullToRefreshController.h"

@implementation UIScrollView (T21PullToRefreshUtils)

#pragma mark - Add/Remove pull to refresh methods

- (UIRefreshControl*) addPullToRefreshWithRefreshBlock:(void (^)(void))refreshBlock
{
    return [[T21PullToRefreshController getInstance] addPullToRefresh:self withRefreshBlock:refreshBlock];
}

- (void) removePullToRefresh
{
    [[T21PullToRefreshController getInstance] removePullToRefresh:self];
}

#pragma mark - Animation methods

- (void) startPullToRefreshAnimation
{
    [[T21PullToRefreshController getInstance] startPullToRefreshAnimation:self];
}

- (void) resetPullToRefreshAnimation
{
    [[T21PullToRefreshController getInstance] resetPullToRefreshAnimation:self];
}

- (void) finishPullToRefreshAnimation {
    [[T21PullToRefreshController getInstance] finishPullToRefreshAnimation:self];
}

- (BOOL) isPullToRefreshAnimating {
    return [[T21PullToRefreshController getInstance] isPullToRefreshAnimating:self];
}

- (BOOL) hasPullToRefreshController {
    return [[T21PullToRefreshController getInstance] hasPullToRefresh:self];
}

#pragma mark - Pull to refresh by code

- (void) performPullToRefresh
{
    [[T21PullToRefreshController getInstance] performPullToRefresh:self];
}


@end
