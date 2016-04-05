//
//  DetailViewController.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/24.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "DetailViewController.h"
#import "SWTableViewController.h"
#import "SWCellDecorator.h"

@interface DetailViewController ()
{
    SWTableViewController* _tableViewController;
}

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableViewController = [[SWTableViewController alloc] init];
    [self.view addSubview:_tableViewController.tableView];

    _tableViewController.cellDecorator = [SWCellHeadSeperatorLineDecorator new];
    _tableViewController.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableViewController.model = [self testViewModel];

    // self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
    //     initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
    //                          target:self
    //                          action:@selector(toggleEdit:)];
}

- (void)viewWillLayoutSubviews {
    CGRect bounds = self.view.bounds;
    bounds.origin.y += [self.topLayoutGuide length];
    bounds.size.height -= bounds.origin.y;
    _tableViewController.tableView.frame = bounds;
}

- (SWTableViewModel*)testViewModel {
    return [SWTableViewModel newWithRows:@[
        @{@"text": @"text 0"},
        @{@"text": @"text 1"},
        @{@"text": @"text 2"},
        @{@"text": @"text 3"},
        @{@"text": @"text 4"},
        @{@"text": @"text 5"},
        @{@"text": @"text 6"},
        @{@"text": @"text 7"},
        @{@"text": @"text 8"},
        @{@"text": @"text 9"},
    ]];
}

- (SWTableViewModel*)testUseCellAsSeperator {
    SWTableViewModel* viewModel = [SWTableViewModel new];
    SWTableSectionViewModel* section = [SWTableSectionViewModel new];
    section.rows = @[
        @{@"text": @"text 1"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 2"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 3"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 4"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 5"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 6"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 7"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 8"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 9"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 10"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 11"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 12"},
        NSClassFromString(@"SeperatorCell"),
        @{@"text": @"text 13"},
    ];
    _tableViewController.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [viewModel insertObject:section inSectionsAtIndex:0];
    return viewModel;
}

- (void)toggleEdit:(UIBarButtonItem*)btn {
    btn.style = UIBarButtonSystemItemEdit == btn.style
                    ? UIBarButtonItemStyleDone
                    : UIBarButtonSystemItemEdit;
    _tableViewController.tableView.editing =
        btn.style == UIBarButtonItemStyleDone;
}

@end
