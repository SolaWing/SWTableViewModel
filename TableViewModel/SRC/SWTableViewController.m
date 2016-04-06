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

- (void)dealloc {
    self.model = nil; // release KVO
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _clearsSelectionOnViewWillAppear = YES;
    }
    return self;
}

#pragma mark - property
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_clearsSelectionOnViewWillAppear) {
        UITableView* tableView = self.tableView;
        NSArray* indexPaths = [tableView indexPathsForSelectedRows];
        if (indexPaths.count > 0) {
            for (NSIndexPath* element in indexPaths){
                [tableView deselectRowAtIndexPath:element animated:YES];
            }
        }
    }
}

- (void)loadView {
    self.tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                  style:UITableViewStylePlain];
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
        if (_model && _syncing) {
            [self unbindModel:_model];
        }
        _model = model;
        [self.tableView reloadData];
        if (_model && _syncing) {
            [self bindModel:_model];
        }
    }
}

- (void)setSyncing:(bool)syncing {
    if (_syncing != syncing) {
        _syncing = syncing;
        if (_model) {
            if (_syncing) {
                [self bindModel:_model];
            } else {
                [self unbindModel:_model];
            }
        }
    }
}

- (void)bindModel:(SWTableViewModel*)model {
    [model addObserver:self forKeyPath:@"sections" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:@"sections"];
    for (SWTableSectionViewModel* element in model.sections){
        [element addObserver:self forKeyPath:@"rows" options:0 context:@"rows"];
    }
}

- (void)unbindModel:(SWTableViewModel*)model {
    for (SWTableSectionViewModel* element in model.sections){
        [element removeObserver:self forKeyPath:@"rows" context:@"rows"];
    }
    [model removeObserver:self forKeyPath:@"sections" context:@"sections"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (context == @"sections") {
        NSParameterAssert([NSThread isMainThread]);
        // deal section KVO change
        NSArray* oldSections = change[NSKeyValueChangeOldKey];
        NSArray* newSections = change[NSKeyValueChangeNewKey];
        for (SWTableSectionViewModel* element in oldSections){
            [element removeObserver:self forKeyPath:@"rows" context:@"rows"];
        }
        for (SWTableSectionViewModel* element in newSections){
            [element addObserver:self forKeyPath:@"rows" options:0 context:@"rows"];
        }

        NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] integerValue];
        SEL updateSEL;
        switch( kind ){
            case NSKeyValueChangeReplacement:
                updateSEL = @selector(reloadSections:withRowAnimation:);
                goto PartialUpdateSection;
            case NSKeyValueChangeRemoval:
                updateSEL = @selector(deleteSections:withRowAnimation:);
                goto PartialUpdateSection;
            case NSKeyValueChangeInsertion:
                updateSEL = @selector(insertSections:withRowAnimation:);
            PartialUpdateSection: {
                NSIndexSet* indexes = change[NSKeyValueChangeIndexesKey];
                void(*imp)(UITableView*, SEL, NSIndexSet*, UITableViewRowAnimation)
                    = (void*)[self.tableView methodForSelector:updateSEL];
                imp(self.tableView, updateSEL, indexes, UITableViewRowAnimationAutomatic);
            } return;
            case NSKeyValueChangeSetting: {
                [self.tableView reloadData];
            } return;
        } return;
    } else if (context == @"rows") {
        NSParameterAssert([NSThread isMainThread]);

        NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] integerValue];
        NSUInteger section = [_model indexOfObjectInSections:object];
        SEL updateSEL;
        switch( kind ){
            case NSKeyValueChangeReplacement:
                updateSEL = @selector(reloadRowsAtIndexPaths:withRowAnimation:);
                goto PartialUpdate;
            case NSKeyValueChangeRemoval:
                updateSEL = @selector(deleteRowsAtIndexPaths:withRowAnimation:);
                goto PartialUpdate;
            case NSKeyValueChangeInsertion:
                updateSEL = @selector(insertRowsAtIndexPaths:withRowAnimation:);
            PartialUpdate: {
                NSIndexSet* indexes = change[NSKeyValueChangeIndexesKey];
                NSMutableArray* indexPaths = [NSMutableArray new];
                [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop){
                    [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
                }];
                void (*imp)(UITableView*, SEL, NSArray*, UITableViewRowAnimation)
                    = (void*)[self.tableView methodForSelector:updateSEL];
                imp(self.tableView, updateSEL, indexPaths, UITableViewRowAnimationAutomatic);
            } return;
            case NSKeyValueChangeSetting: {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
            } return;
        } return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (id<SWCellFactory>)cellFactory {
    return [SWCellFactory defaultFactory];
}

- (id)modelForRowAtModelIndexPath:(NSIndexPath *)indexPath {
    return [_model modelAtIndexPath:indexPath];
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
    id viewModel = [self modelForRowAtModelIndexPath:indexPath];
    cell = [self.cellFactory cellForTableView:tableView model:viewModel];

    NSParameterAssert(cell);
    if (_cellDecorator && [_cellDecorator respondsToSelector:@selector(tableView:decorateCell:forModel:atIndexPath:)]) {
        [_cellDecorator tableView:tableView decorateCell:cell forModel:viewModel atIndexPath:indexPath];
    }

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
    id viewModel = [self modelForRowAtModelIndexPath:indexPath];
    CGFloat height = [self.cellFactory heightForTableView:tableView model:viewModel];
    if (_cellDecorator && [_cellDecorator respondsToSelector:@selector(tableView:suggestHeight:forModel:atIndexPath:)]) {
        [_cellDecorator tableView:tableView suggestHeight:&height forModel:viewModel atIndexPath:indexPath];
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!tableView.editing) {
        [_model selectModelAtIndexPath:indexPath];
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
