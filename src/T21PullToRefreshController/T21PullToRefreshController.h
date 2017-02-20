//
//  T21PullToRefreshController.h
//  MyApp
//
//  Created by David Arrufat on 15/06/15.
//  Copyright (c) 2015 Tempos21. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface T21PullToRefreshController : NSObject

+(T21PullToRefreshController*)getInstance;

#pragma mark - Add/Remove pull to refresh methods

-(UIRefreshControl*)addPullToRefresh:(UIScrollView *)scrollView withRefreshBlock:(void (^)(void))refreshBlock;
-(void)removePullToRefresh:(UIScrollView*)scrollView;

#pragma mark - Animation methods

-(void)startPullToRefreshAnimation:(UIScrollView*)scrollView;
-(void)finishPullToRefreshAnimation:(UIScrollView*)scrollView;
-(BOOL)isPullToRefreshAnimating:(UIScrollView*)scrollView;

-(void)resetPullToRefreshAnimation:(UIScrollView*)scrollView __deprecated_msg("use finishPullToRefreshAnimation instead.");

#pragma mark - Pull to refresh by code

-(void)performPullToRefresh:(UIScrollView*)scrollView;

#pragma mark - Helper methods

-(BOOL)hasPullToRefresh:(UIScrollView *)scrollView;

@end
