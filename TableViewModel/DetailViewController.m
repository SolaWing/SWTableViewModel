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

@interface DetailViewController () <SWTableViewModelDelegate>
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
    // _tableViewController.tableView.allowsMultipleSelectionDuringEditing = YES;
    _tableViewController.model = [self testViewModel];

    _tableViewController.syncing = YES;
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
            target:self action:@selector(updateSections)],
        _tableViewController.editButtonItem,
    ];

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
    SWTableViewModel* model = [SWTableViewModel newWithRows:@[
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
    model.delegate = self;
    return model;
}

- (SWTableViewModel*)testUseCellAsSeperator {
    SWTableViewModel* viewModel = [SWTableViewModel new];
    viewModel.delegate = self;
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

static NSUInteger counter = 0;

- (void)updateSections {
    SWTableViewModel* model = _tableViewController.model;
    CGFloat random = arc4random() / (double)UINT32_MAX ;
    if (random > 6/8.0) {
        if (model.countOfSections == 0) { return; }
        [self updateRows];
    } else if (random > 2/4.0) {
        self.navigationItem.title = [NSString stringWithFormat:@"rm sec %lu", ++counter];
        if (model.countOfSections == 0) { return; }
        NSMutableIndexSet* indexes = [NSMutableIndexSet indexSetWithIndex:0];
        [indexes addIndex:model.countOfSections-1];
        [model removeSectionsAtIndexes:indexes];
    } else if (random > 1/4.0) {
        // insert
        self.navigationItem.title = [NSString stringWithFormat:@"ins sec %lu", ++counter];
        [model insertSections:@[
            [SWTableSectionViewModel newWithRows:@[
                @{@"text": @"insert 1 section 0"},
                @{@"text": @"insert 1 section 1"},
                @{@"text": @"insert 1 section 2"},
                @{@"text": @"insert 1 section 3"},
            ] header:@"Insert 1" footer:@{
                @"text":@"footer 1",
                @"textColor":[UIColor blueColor],
                @"backgroundColor":[UIColor greenColor],
            }],
            [SWTableSectionViewModel newWithRows:@[
                @{@"text": @"insert 2 section 0"},
                @{@"text": @"insert 2 section 1"},
                @{@"text": @"insert 2 section 2"},
                @{@"text": @"insert 2 section 3"},
            ] header:@{
                @"text":@"header 2",
                @"textColor":[UIColor blueColor],
                @"backgroundColor":[UIColor greenColor],
            } footer:@"footer 2"],
        ] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,2)]];
    } else if (model.countOfSections < 4) {
        self.navigationItem.title = [NSString stringWithFormat:@"reload sec %lu", ++counter];
        model.sections = [SWTableSectionViewModel arrayOfSectionsRows:@[
        // _tableViewController.model = [SWTableViewModel newWithSectionRows:@[
            @[
                @{@"text": @"section1 0"},
                @{@"text": @"section1 1"},
                @{@"text": @"section1 2"},
                @{@"text": @"section1 3"},
            ],
            @[
                @{@"text": @"section2 0"},
                @{@"text": @"section2 1"},
                @{@"text": @"section2 2"},
                @{@"text": @"section2 3"},
            ],
        ]];
        _tableViewController.model.delegate = self;
    } else {
         // replace
        self.navigationItem.title = [NSString stringWithFormat:@"chg sec %lu", ++counter];
        [model replaceObjectInSectionsAtIndex:1 withObject:[SWTableSectionViewModel newWithRows:@[
            @{@"text": @"replace section 0"},
            @{@"text": @"replace section 1"},
            @{@"text": @"replace section 2"},
            @{@"text": @"replace section 3"},
        ]]];
    }
}

- (void)addRow {
    SWTableSectionViewModel* section = [_tableViewController.model objectInSectionsAtIndex:0];
    [section insertObject:@{@"text": [NSString stringWithFormat:@"addRow %@", [NSDate date]]}
            inRowsAtIndex:[section countOfRows]/2];
}

- (void)updateRows {
    CGFloat random = arc4random() / (double)UINT32_MAX ;
    if (random > 2/4.0) {
        self.navigationItem.title = [NSString stringWithFormat:@"rm rows %lu", ++counter];
        return [self deleteRows];
    } else if (random > 1/4.0) {
        self.navigationItem.title = [NSString stringWithFormat:@"chg rows %lu", ++counter];
        return [self replaceRows];
    }

    self.navigationItem.title = [NSString stringWithFormat:@"ins rows %lu", ++counter];
    SWTableSectionViewModel* section = [_tableViewController.model objectInSectionsAtIndex:0];
    id desc = [NSDate date];
    [section insertRows:@[
             @{@"text": [NSString stringWithFormat:@"addRow 1 %@", desc]},
             @{@"text": [NSString stringWithFormat:@"addRow 2 %@", desc]},
    ] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([section countOfRows]/3, 2)]];
}

- (void)replaceRows {
    SWTableSectionViewModel* section = [_tableViewController.model objectInSectionsAtIndex:0];
    if (section.countOfRows < 10) {
        section.rows = @[
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
        ]; return;
    }
    NSMutableIndexSet* indexes = [NSMutableIndexSet indexSetWithIndex:[section countOfRows]/3-1];
    [indexes addIndex:[section countOfRows]/3+1]; // the same index will ignore
    id desc = [NSDate date];
    [section replaceRowsAtIndexes:indexes withRows:@[
        @{@"text": [NSString stringWithFormat:@"replaceRows 1 %@", desc]},
        @{@"text": [NSString stringWithFormat:@"replaceRows 2 %@", desc]},
    ]];
}

- (void)deleteRows {
    SWTableSectionViewModel* section = [_tableViewController.model objectInSectionsAtIndex:0];
    if (section.countOfRows < 3) { return; }
    NSMutableIndexSet* indexes = [NSMutableIndexSet indexSetWithIndex:[section countOfRows]/3-1];
    [indexes addIndex:[section countOfRows]/3+1]; // the same index will ignore
    [section removeRowsAtIndexes:indexes];
}

- (void)toggleEdit:(UIBarButtonItem*)btn {
    btn.style = UIBarButtonSystemItemEdit == btn.style
                    ? UIBarButtonItemStyleDone
                    : UIBarButtonSystemItemEdit;
    _tableViewController.tableView.editing =
        btn.style == UIBarButtonItemStyleDone;
}

#pragma mark - SWTableViewModelDelegate
- (NSArray<NSIndexPath *> *)tableViewModel:(SWTableViewModel *)sender wouldDeleteModels:(NSArray *)models atIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    return indexPaths;
}

// - (BOOL)tableViewModel:(SWTableViewModel *)sender canEditModel:(id)model atIndexPath:(NSIndexPath *)indexPath {
//     return YES;
// }

@end
