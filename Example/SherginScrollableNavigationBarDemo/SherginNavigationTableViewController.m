//
//  SherginNavigationTableViewController.m
//  SherginScrollableNavigationBarDemo
//
//  Created by Valentin Shergin on 31/03/14.
//  Copyright (c) 2014 shergin research. All rights reserved.
//

#import "SherginNavigationTableViewController.h"

#import "SherginScrollableNavigationBar.h"

@interface SherginNavigationTableViewController ()

@end

@implementation SherginNavigationTableViewController

int count = 30;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // SherginScrollableNavigationBar
    ((SherginScrollableNavigationBar *)self.navigationController.navigationBar).scrollView = self.tableView;

    self.title = @"ScrollableNavigationBar";

    UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle:@"Less" style:UIBarButtonItemStyleBordered target:self action:@selector(lessItems)];
    self.navigationItem.leftBarButtonItem = removeButton;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"More" style:UIBarButtonItemStyleBordered target:self action:@selector(moreItems)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewDidDisappear:(BOOL)animated
{
    // SherginScrollableNavigationBar
    ((SherginScrollableNavigationBar *)self.navigationController.navigationBar).scrollView = self.tableView;

    [super viewDidDisappear:animated];
}

- (void)lessItems {
    count--;
    [self refresh];
}

- (void)moreItems {
    count++;
    [self refresh];
}

- (void)refresh {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    cell.textLabel.text = [NSString stringWithFormat:@"Cell #%d", (int)indexPath.row];
    return cell;
}

@end
