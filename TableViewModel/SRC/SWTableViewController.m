//
//  SWTableViewController.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/25.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWTableViewController.h"
#import <objc/runtime.h>

// FIXME: how to implementation observing change with viewModel?
@implementation SWTableViewController

#pragma mark - property
- (void)loadView {
    self.tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                  style:UITableViewStylePlain];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor blueColor];
}

- (UITableView *)tableView {
    UITableView* tableView = (id)self.view;
    NSParameterAssert( !tableView || [tableView isKindOfClass:[UITableView class]] );
    return tableView;
}

- (void)setTableView:(UITableView *)tableView {
    UITableView *oldView = [self isViewLoaded] ? (id)self.view : nil;
    if (oldView != tableView) {
        self.view = tableView;
        tableView.dataSource = self;
        tableView.delegate = self;
    }
}

- (void)setModel:(SWTableViewModel *)model {
    if (_model != model) {
        _model = model;
        [self.tableView reloadData];
    }
}

- (id<SWCellFactory>)cellFactory {
    return [SWCellFactory defaultFactory];
}

- (id)viewModelForRowAtModelIndexPath:(NSIndexPath *)indexPath {
    return [[_model objectInSectionsAtIndex:indexPath.section]
        objectInRowsAtIndex:indexPath.row];
}

#pragma mark - TableView Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_model objectInSectionsAtIndex:section] countOfRows];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_model countOfSections];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    id viewModel = [self viewModelForRowAtModelIndexPath:indexPath];
    cell = [self.cellFactory cellForTableView:tableView model:viewModel];

    NSParameterAssert(cell);
    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id title = [_model objectInSectionsAtIndex:section].header;
    return [title isKindOfClass:[NSString class]] ? title : nil;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    id title = [_model objectInSectionsAtIndex:section].footer;
    return [title isKindOfClass:[NSString class]] ? title : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id viewModel = [self viewModelForRowAtModelIndexPath:indexPath];
    return [self.cellFactory heightForTableView:tableView model:viewModel];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!tableView.editing && _model.selectModel) {
        id viewModel = [self viewModelForRowAtModelIndexPath:indexPath];
        _model.selectModel(_model, viewModel);

        // after callback, clear selection
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

/*
#pragma mark - redirect
static bool isTableViewDelegateMethod(SEL selector, bool isRequired) {
    return protocol_getMethodDescription(@protocol(UITableViewDelegate),
                                         selector, isRequired, YES)
               .name != nil;
}

static bool isTableViewDataSourceMethod(SEL selector, bool isRequired) {
    return protocol_getMethodDescription(@protocol(UITableViewDataSource),
                                         selector, isRequired, YES)
               .name != nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    if (_delegate && (isTableViewDelegateMethod(aSelector, NO) ||
                      isTableViewDataSourceMethod(aSelector, NO)) &&
        [_delegate respondsToSelector:aSelector]) {
        return YES;
    }
    return NO;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (_delegate && (isTableViewDelegateMethod(aSelector, NO) ||
                      isTableViewDataSourceMethod(aSelector, NO)) &&
        [_delegate respondsToSelector:aSelector]) {
        return _delegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

*/
@end
