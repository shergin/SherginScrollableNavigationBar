//
//  SherginScrollableNavigationBar.swift
//  ScrollableNavigationBarDemo
//
//  Created by Valentin Shergin on 19/09/14.
//  Copyright (c) 2014 shergin research. All rights reserved.
//

import UIKit

enum ScrollState {
    case None
    case Gesture
    case Finishing
}

let ScrollViewContentOffsetPropertyName: String = "contentOffset"
let NavigationBarAnimationName: String = "NavigationBarScrollAnimation"
let DefaultScrollTolerance: CGFloat = 44.0;

public class SherginScrollableNavigationBar: UINavigationBar, UIGestureRecognizerDelegate
{
    var scrollView: UIScrollView?
    var panGestureRecognizer: UIPanGestureRecognizer!
    var scrollTolerance = DefaultScrollTolerance
    var scrollOffsetStart: CGFloat = 0.0
    var scrollState: ScrollState = .None
    var barOffsetStart: CGFloat = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }

    func commonInit() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        self.panGestureRecognizer.delegate = self

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "applicationDidBecomeActive",
            name: UIApplicationDidBecomeActiveNotification,
            object: nil
        )

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "statusBarOrientationDidChange",
            name: UIApplicationDidChangeStatusBarOrientationNotification,
            object: nil
        )
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIApplicationDidBecomeActiveNotification,
            object: nil
        )

        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIApplicationDidChangeStatusBarOrientationNotification,
            object: nil
        )

        self.scrollView = nil
    }

    func statusBarOrientationDidChange() {
        self.resetToDefaultPosition(false);
    }

    func applicationDidBecomeActive() {
        self.resetToDefaultPosition(false);
    }

    //pragma mark - UIGestureRecognizerDelegate
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
    }

    var scrollable: Bool {
        let scrollView = self.scrollView!
        let contentSize = scrollView.contentSize;
        let contentInset = scrollView.contentInset;
        let containerSize = scrollView.bounds.size;

        let containerHeight = containerSize.height - contentInset.top - contentInset.bottom;
        let contentHeight = contentSize.height;
        let barHeight = self.frame.size.height;

        return contentHeight - self.scrollTolerance - barHeight > containerHeight;
    }

    var scrollOffset: CGFloat {
        let scrollView = self.scrollView!
        return -(scrollView.contentOffset.y + scrollView.contentInset.top);
    }

    var scrollOffsetRelative: CGFloat {
        return self.scrollOffset - self.scrollOffsetStart;
    }

    public func setScrollView(scrollView: UIScrollView?) {

        if self.scrollView != nil {
            self.scrollView!.removeObserver(
                self,
                forKeyPath: ScrollViewContentOffsetPropertyName
            )

            scrollView?.removeGestureRecognizer(self.panGestureRecognizer)
        }

        self.scrollView = scrollView

        if self.scrollView != nil {
            scrollView?.addObserver(
                self,
                forKeyPath: ScrollViewContentOffsetPropertyName,
                options: NSKeyValueObservingOptions.New,
                context: nil
            )

            scrollView?.addGestureRecognizer(self.panGestureRecognizer)
        }
    }

    public func resetToDefaultPosition(animated: Bool) {
        self.setBarOffset(0.0, animated: animated)
    }

    override public func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<()>) {
        if (self.scrollView != nil) && (keyPath == ScrollViewContentOffsetPropertyName) && (object as NSObject == self.scrollView!) {
            self.scrollViewDidScroll()
        }

        //super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    }

    func setBarOffset(offset: CGFloat, animated: Bool) {
        var offset: CGFloat = offset;

        if offset > 0 {
            offset = 0;
        }

        let barHeight: CGFloat = self.frame.size.height
        let statusBarHeight: CGFloat = self.statusBarHeight()

        offset = max(offset, -barHeight)

        let alpha: CGFloat = min(1.0 - abs(offset / barHeight) + CGFloat(FLT_EPSILON), 1.0)

        let currentOffset: CGFloat = self.frame.origin.y
        let targetOffset: CGFloat = statusBarHeight + offset

        if (abs(currentOffset - targetOffset) < CGFloat(FLT_EPSILON)) {
            return;
        }

        if (animated) {
            UIView.beginAnimations(NavigationBarAnimationName, context: nil)
        }

        let subviews: [UIView] = self.subviews as [UIView]
        let backgroundView: UIView = subviews[0]

        // apply alpha
        for view in subviews {
            let isBackgroundView: Bool = (view == backgroundView)
            let isInvisible: Bool = view.hidden || view.alpha < CGFloat(FLT_EPSILON)

            if isBackgroundView || isInvisible {
                continue;
            }

            view.alpha = alpha;
        }

        // apply offset
        var frame: CGRect = self.frame;
        frame.origin.y = targetOffset;
        self.frame = frame;
        
        if (animated) {
            UIView.commitAnimations()
        }
    }

    var barOffset: CGFloat {
        get {
            return self.frame.origin.y - self.statusBarHeight()
        }
        set(offset) {
            self.setBarOffset(offset, animated: false);
        }
    }

    func statusBarHeight() -> CGFloat {
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        let frame = UIApplication.sharedApplication().statusBarFrame

        switch (orientation) {
            case .Portrait, .PortraitUpsideDown:
                return CGRectGetHeight(frame)

            case .LandscapeLeft, .LandscapeRight:
                return CGRectGetWidth(frame)

            default:
                assertionFailure("Unknown orientation.")
        }
    }

    func handlePanGesture(gesture: UIPanGestureRecognizer) {
        if self.scrollView == nil || gesture.view != self.scrollView {
            return
        }

        let gestureState: UIGestureRecognizerState = gesture.state

        if gestureState == .Began {
            // Begin state
            self.scrollState = .Gesture
            self.scrollOffsetStart = self.scrollOffset
            self.barOffsetStart = self.barOffset;
        }
        else if gestureState == .Changed {
            // Changed state
            self.scrollViewDidScroll()
        }
        else if
            gestureState == .Ended ||
            gestureState == .Cancelled ||
            gestureState == .Failed
        {
            // End state
            self.scrollState = .Finishing
            self.scrollFinishing()
        }
    }

    func scrollViewDidScroll() {
        if (!self.scrollable) {
            self.resetToDefaultPosition(false);
            return;
        }

        var offset = self.scrollOffsetRelative
        var tolerance = self.scrollTolerance

        if self.scrollOffsetRelative > 0 {
            let maxTolerance = self.barOffsetStart - self.scrollOffsetStart
            if tolerance > maxTolerance {
                tolerance = maxTolerance;
            }
        }

        if abs(offset) < tolerance {
            offset = 0.0;
        }
        else {
            offset = offset + (offset < 0 ? +tolerance : -tolerance);
        }

        self.barOffset = self.barOffsetStart + offset
        
        self.scrollFinishing();
    }

    var timer: NSTimer?

    func scrollFinishing() {
        if let timer = self.timer {
            timer.invalidate()
        }

        if self.scrollState != .Finishing {
            return;
        }

        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "scrollFinishActually", userInfo: nil, repeats: false)
    }

    func scrollFinishActually() {
        self.scrollState = .None;

        var barOffset = self.barOffset;
        var barHeight = self.frame.size.height;

        if
            (abs(barOffset) < barHeight / 2.0) ||
            (-self.scrollOffset < barHeight)
        {
            // show bar
            barOffset = 0;
        }
        else {
            // hide bar
            barOffset = -barHeight;
        }
        
        self.setBarOffset(barOffset, animated:true);

        self.barOffsetStart = 0.0;
    }
}
