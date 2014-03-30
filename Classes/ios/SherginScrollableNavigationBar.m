//
//  SherginScrollableNavigationBar.m
//  SherginScrollableNavigationBar
//
//  Created by Valentin Shergin on 30/03/14.
//  Copyright (c) 2014 shergin research. All rights reserved.
//

#import <objc/runtime.h>

#import "SherginScrollableNavigationBar.h"

typedef enum {
    SherginScrollableNavigationBarStateNone,
    SherginScrollableNavigationBarStateGesture,
    SherginScrollableNavigationBarStateFinishing,
} SherginScrollableNavigationBarState;

@interface SherginScrollableNavigationBar () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) UIPanGestureRecognizer* panGesture;

@property (assign, nonatomic) CGFloat scrollOffset;
@property (assign, nonatomic) CGFloat scrollOffsetStart;
@property (assign, nonatomic) CGFloat scrollOffsetRelative;
@property (assign, nonatomic) CGFloat barOffset;
@property (assign, nonatomic) CGFloat barOffsetStart;
@property (assign, nonatomic) CGFloat statusBarHeight;
@property (assign, nonatomic) SherginScrollableNavigationBarState scrollState;

@end

@implementation SherginScrollableNavigationBar

SherginScrollableNavigationBar *_self;
const CGFloat DefaultScrollTolerance = 44.0f;

@synthesize scrollView = _scrollView;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _self = self;
    self.scrollTolerance = DefaultScrollTolerance;

    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(handlePan:)];
    self.panGesture.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarOrientationDidChange)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
}

- (void)swizzleScrollView:(UIScrollView *)scrollView
{
    NSObject<UIScrollViewDelegate> *scrollViewDelegate = scrollView.delegate;

    Method methodOriginal = class_getInstanceMethod([scrollViewDelegate class], @selector(scrollViewDidScroll:));
    Method methodWrapper = class_getInstanceMethod([self class], @selector(scrollViewDidScrollWrapper:));

    if (method_getImplementation(methodOriginal) == method_getImplementation(methodWrapper)) {
        NSLog(@"Method scrollViewDidScroll in class already swizzled.");
        return;
    }

    class_addMethod(
        [scrollViewDelegate class],
        @selector(scrollViewDidScrollOriginal:),
        method_getImplementation(methodOriginal),
        method_getTypeEncoding(methodOriginal)
    );

    class_replaceMethod(
        [scrollViewDelegate class],
        @selector(scrollViewDidScroll:),
        method_getImplementation(methodWrapper),
        method_getTypeEncoding(methodWrapper)
    );
}

- (void)scrollViewDidScrollWrapper:(UIScrollView *)scrollView
{
    if (scrollView == _self.scrollView) {
        if (_self.scrollState != SherginScrollableNavigationBarStateNone) {
            [_self scrollViewDidScroll];
        }
    }

    if ([self respondsToSelector:@selector(scrollViewDidScrollOriginal:)]) {
        [self performSelector:@selector(scrollViewDidScrollOriginal:) withObject:scrollView];
    }
}

- (void)setScrollView:(UIScrollView*)scrollView
{
    _scrollView = scrollView;
    if (scrollView) {
        [self swizzleScrollView:_scrollView];
    }

    [self resetToDefaultPosition:NO];

    // remove gesture from current panGesture's view
    if (self.panGesture.view) {
        [self.panGesture.view removeGestureRecognizer:self.panGesture];
    }

    if (scrollView) {
        [scrollView addGestureRecognizer:self.panGesture];
    }
}

- (void)resetToDefaultPosition:(BOOL)animated
{
    [self setBarOffset:0.0f animated:animated];
}

#pragma mark - Notifications
- (void)statusBarOrientationDidChange
{
    [self resetToDefaultPosition:NO];
}

- (void)applicationDidBecomeActive
{
    [self resetToDefaultPosition:NO];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSLog(@"shouldRecognizeSimultaneouslyWithGestureRecognizer");
    return YES;
}

- (CGFloat)scrollOffset
{
    return -(self.scrollView.contentOffset.y + self.scrollView.contentInset.top);
}

- (CGFloat)scrollOffsetRelative
{
    return self.scrollOffset - self.scrollOffsetStart;
}

- (void)scrollViewDidScroll
{
    CGFloat offset = self.scrollOffsetRelative;
    CGFloat tolerance = self.scrollTolerance;

    if (self.scrollOffsetRelative > 0) {
        CGFloat minTolerance = self.barOffsetStart - self.scrollOffsetStart;
        if (tolerance > minTolerance) {
            tolerance = minTolerance;
        }
    }

    if (ABS(offset) < tolerance)
        offset = 0.0f;
    else
        offset = offset + (offset < 0 ? +tolerance : -tolerance);

    [self setBarOffset:(self.barOffsetStart + offset) animated:NO];

    if (self.scrollState == SherginScrollableNavigationBarStateFinishing) {
        [self scrollViewEndScroll];
    }
}

- (void)scrollViewEndScroll
{
    [self debounce:@selector(scrollViewEndScrollActually) delay:0.1f];
}

- (void)scrollViewEndScrollActually
{
    NSLog(@"scrollViewEndScrollActually %i", self.scrollState);
    self.scrollState = SherginScrollableNavigationBarStateNone;

    CGFloat barOffset = self.barOffset;
    CGFloat barHeight = self.frame.size.height;
    if (
        (ABS(barOffset) < barHeight / 2.0f) ||
        (-self.scrollOffset < barHeight)
    ) {
        // show bar
        barOffset = 0;
    }
    else {
        // hide bar
        barOffset = -barHeight;
    }

    [self setBarOffset:barOffset animated:YES];
}

#pragma mark - panGesture handler
- (void)handlePan:(UIPanGestureRecognizer*)gesture
{
    if (!self.scrollView || gesture.view != self.scrollView) {
        return;
    }

    UIGestureRecognizerState gestureState = gesture.state;

    if (gestureState == UIGestureRecognizerStateBegan) {
        // Begin state
        self.scrollState = SherginScrollableNavigationBarStateGesture;
        self.scrollOffsetStart = self.scrollOffset;
        self.barOffsetStart = self.barOffset;
    }
    else if (gestureState == UIGestureRecognizerStateChanged) {
        // Changed state
        [self scrollViewDidScroll];
    }
    else if (
             gestureState == UIGestureRecognizerStateEnded ||
             gestureState == UIGestureRecognizerStateCancelled ||
             gestureState == UIGestureRecognizerStateFailed
             ) {
        // End state
        self.scrollState = SherginScrollableNavigationBarStateFinishing;
        [self scrollViewEndScroll];
    }
}

#pragma mark - helper methods
- (CGFloat)statusBarHeight
{
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            return CGRectGetWidth([UIApplication sharedApplication].statusBarFrame);
        default:
            break;
    };
    return 0.0f;
}

- (CGFloat)barOffset
{
    return self.frame.origin.y - self.statusBarHeight;
}

- (void)setBarOffset:(CGFloat)offset
{
    [self setBarOffset:offset animated:NO];
}

- (void)setBarOffset:(CGFloat)offset animated:(BOOL)animated
{
    if (offset > 0) {
        offset = 0;
    }

    const CGFloat nearZero = 0.001f;

    CGFloat barHeight = self.frame.size.height;
    CGFloat statusBarHeight = self.statusBarHeight;

    offset = MAX(offset, -barHeight);

    CGFloat alpha = MIN(1.0f - ABS(offset / barHeight) + nearZero, 1.0f);
    CGFloat currentOffset = self.frame.origin.y;
    CGFloat targetOffset = statusBarHeight + offset;

    if (ABS(currentOffset - targetOffset) < FLT_EPSILON) {
        return;
    }

    if (animated) {
        [UIView beginAnimations:@"SherginScrollableNavigationBar" context:nil];
    }

    // apply alpha
    for (UIView* view in self.subviews) {
        bool isBackgroundView = (view == [self.subviews objectAtIndex:0]);
        bool isInvisible = view.hidden || view.alpha < (nearZero / 2);
        if (isBackgroundView || isInvisible)
            continue;
        view.alpha = alpha;
    }

    // apply offset
    CGRect frame = self.frame;
    frame.origin.y = targetOffset;
    self.frame = frame;

    if (animated) {
        [UIView commitAnimations];
    }
}

- (void)debounce:(SEL)selector delay:(NSTimeInterval)delay
{
    __weak typeof(self) weakSelf = self;
    [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:selector object:nil];
    [weakSelf performSelector:selector withObject:nil afterDelay:delay];
}

@end
