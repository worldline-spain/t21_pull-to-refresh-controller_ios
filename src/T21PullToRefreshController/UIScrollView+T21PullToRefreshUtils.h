//
//  UIScrollView+T21PullToRefreshUtils.h
//  MyApp
//
//  Created by David Arrufat on 15/06/15.
//  Copyright (c) 2015 Tempos21. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (T21PullToRefreshUtils)

#pragma mark - Add/Remove pull to refresh methods

- (UIRefreshControl*) addPullToRefreshWithRefreshBlock:(void (^)(void))refreshBlock;
- (void) removePullToRefresh;

#pragma mark - Animation methods

- (void) startPullToRefreshAnimation;
- (void) resetPullToRefreshAnimation;
- (void) finishPullToRefreshAnimation;
- (BOOL) isPullToRefreshAnimating;
- (BOOL) hasPullToRefreshController;

#pragma mark - Pull to refresh by code

- (void) performPullToRefresh;

@end
