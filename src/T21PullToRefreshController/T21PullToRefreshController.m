//
//  T21PullToRefreshController.m
//  MyApp
//
//  Created by David Arrufat on 15/06/15.
//  Copyright (c) 2015 Tempos21. All rights reserved.
//

#import "T21PullToRefreshController.h"

typedef enum T21PullToRefreshOperationType {
    T21PullToRefreshOperationTypeUnknown = -1,
    T21PullToRefreshOperationTypeShow = 0,
    T21PullToRefreshOperationTypeHide = 1
}T21PullToRefreshOperationType;


@interface T21PullToRefreshOperation : NSObject

- (instancetype)initWithType:(T21PullToRefreshOperationType)type;

@property (nonatomic) T21PullToRefreshOperationType type;
@property (nonatomic) BOOL wasForcedProgramatically;

@end

@interface T21PullToRefreshControllerInternalState : NSObject

-(void)addOperation:(T21PullToRefreshOperation*)newOperation;

@property (nonatomic) NSNumber * isAnimating;
@property (nonatomic,copy) void (^refreshBlock)();
@property (nonatomic) NSMutableArray * queue;
@property (nonatomic,weak) UIRefreshControl *refreshControl;
@property (nonatomic) T21PullToRefreshOperationType lastState;

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
        state.refreshControl = refreshControl;
        
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
    [self animateRefreshControl:refreshControl wasForcedProgramatically:YES];
}

- (void) finishPullToRefreshAnimation:(UIScrollView*)scrollView {
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl) {
        T21PullToRefreshControllerInternalState * state = [_refreshStates objectForKey:refreshControl];
        T21PullToRefreshOperation * operation = [[T21PullToRefreshOperation alloc] initWithType:T21PullToRefreshOperationTypeHide];
        [state addOperation:operation];
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
            return state.queue.count > 0;
        }
    }
    return NO;
}

- (void) animateRefreshControl:(UIRefreshControl*)refreshControl wasForcedProgramatically:(BOOL)wasForcedProgramatically
{
    T21PullToRefreshControllerInternalState * state = [_refreshStates objectForKey:refreshControl];
    T21PullToRefreshOperation * operation = [[T21PullToRefreshOperation alloc] initWithType:T21PullToRefreshOperationTypeShow];
    operation.wasForcedProgramatically = wasForcedProgramatically;
    [state addOperation:operation];
}

#pragma mark - Pull to refresh by code

- (void) performPullToRefresh:(UIScrollView*)scrollView
{
    UIRefreshControl *refreshControl = [_refreshControls objectForKey:scrollView];
    if (refreshControl)
    {
        [self animateRefreshControl:refreshControl wasForcedProgramatically:YES];
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
        [self animateRefreshControl:refreshControl wasForcedProgramatically:NO];
        [self executeRefreshBlock:refreshControl];
    }
}

@end

@implementation T21PullToRefreshOperation

- (instancetype)initWithType:(T21PullToRefreshOperationType)type
{
    self = [super init];
    if (self) {
        self.type = type;
        self.wasForcedProgramatically = NO;
    }
    return self;
}

@end

@implementation T21PullToRefreshControllerInternalState

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isAnimating = @NO;
        self.refreshBlock = nil;
        self.queue = [NSMutableArray array];
        self.lastState = T21PullToRefreshOperationTypeUnknown;
    }
    return self;
}

-(void)addOperation:(T21PullToRefreshOperation*)newOperation {
    @synchronized (self) {
//        NSLog(@"ADD OPERATION STARTS");
        if (newOperation.type != self.lastState) {
            if (self.queue.count == 0) {
                [self.queue addObject:newOperation];
                [self executeOperation:newOperation];
            } else {
                T21PullToRefreshOperation * currentOperation = self.queue.firstObject;
                if (self.queue.count == 1) {
                    // one action is already taking place: Show or Hide
                    // add if it's the opposite action
                    if (currentOperation.type != newOperation.type) {
                        [self.queue addObject:newOperation];
                    }
                } else {
                    //more than one action in the queue: Hide,Show or Show,Hide
                    if (currentOperation.type == newOperation.type) {
                        // remove the opposite action and do not add the new action, as it's the same
                        // Hide,Show <- Hide === Hide
                        [self.queue removeObjectAtIndex:1];
                    } else {
                        //noop: we are adding a redundant operation: Hide,Show <- Show === Hide,Show
                    }
                }
            }
            
            T21PullToRefreshOperation * lastOp = self.queue.lastObject;
            if (lastOp) {
                self.lastState = lastOp.type;
            }
        }
        
//        NSLog(@"OPERATION COUNT: %d",self.queue.count);
//        NSLog(@"ADD OPERATION FINISHES");
    }
}

-(void)executeOperation:(T21PullToRefreshOperation*)operation {
    
//    NSLog(@"EXECUTE OPERATION STARTS");
    if (operation.type == T21PullToRefreshOperationTypeShow) {
        [self executeDelayed:0.2 block:^{
            if (operation.wasForcedProgramatically) {
                UIScrollView *scrollView = (UIScrollView*)self.refreshControl.superview;
                if([scrollView isKindOfClass:[UIScrollView class]]){
                    // UIViewControllers manage automatically the inset calculation when a refresh control begins
                    // (taking in account the status bar and navigation bar)
                    // In order to get the exact height of the refreshControl we inspect the contentInset increment
                    CGFloat prevInset = scrollView.contentInset.top;
                    [self.refreshControl beginRefreshing];
                    
                    //The beginRefreshing action doesn't scroll automatically to the refreshControl contentOffset
                    CGFloat currentInset = scrollView.contentInset.top;
                    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y - fabs(currentInset - prevInset)) animated:YES];
                }
            }
            [self executeDelayed:0.5 block:^{
//                NSLog(@"EXECUTE OPERATION FINISHES");
                [self finishOperation];
            }];
        }];
    } else if (operation.type == T21PullToRefreshOperationTypeHide) {
        [self executeDelayed:0.2 block:^{
            [self.refreshControl endRefreshing];
            [self executeDelayed:0.5 block:^{
//                NSLog(@"EXECUTE OPERATION FINISHES");
                [self finishOperation];
            }];
        }];
    }
}

-(void)executeDelayed:(CGFloat)seconds block:(void (^)())block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        block();
    });
}

-(void)finishOperation {
    @synchronized (self) {
//        NSLog(@"FINISH OPERATION STARTS");
        if (self.queue.count > 0) {
            [self.queue removeObjectAtIndex:0];
            if (self.queue.count > 0) {
                [self executeOperation:self.queue.firstObject];
            }
        }
    }
}

@end
