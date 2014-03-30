//
//  SherginScrollableNavigationBar.h
//  SherginScrollableNavigationBar
//
//  Created by Valentin Shergin on 30/03/14.
//  Copyright (c) 2014 shergin research. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SherginScrollableNavigationBar : UINavigationBar

@property (strong, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) CGFloat scrollTolerance;

@end
