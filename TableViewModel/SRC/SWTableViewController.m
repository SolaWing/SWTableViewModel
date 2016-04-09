//
//  SWTableViewController.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/25.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWTableViewController.h"
#import <objc/runtime.h>

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

#pragma mark - property
static inline bool isSyncing(SWTableViewSyncStyle style) {
    return style > 0;
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
        if (_model && isSyncing(_syncStyle)) {
            [self unbindModel:_model];
        }
        _model = model;
        [self.tableView reloadData];
        if (_model && isSyncing(_syncStyle)) {
            [self bindModel:_model];
        }
    }
}

- (void)setSyncStyle:(SWTableViewSyncStyle)syncStyle {
    bool changeSync = (isSyncing(_syncStyle) != isSyncing(syncStyle));
    _syncStyle = syncStyle;
    if (_model && changeSync) {
        if (isSyncing(_syncStyle)) {
            [self bindModel:_model];
        } else {
            [self unbindModel:_model];
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
    // float section footer may move to bottom when partially update tableView
    if (context == @"sections") {
        NSParameterAssert([NSThread isMainThread]);
        NSParameterAssert(self.tableView);
        // deal section KVO change
        NSArray* oldSections = change[NSKeyValueChangeOldKey];
        NSArray* newSections = change[NSKeyValueChangeNewKey];
        for (SWTableSectionViewModel* element in oldSections){
            [element removeObserver:self forKeyPath:@"rows" context:@"rows"];
        }
        for (SWTableSectionViewModel* element in newSections){
            [element addObserver:self forKeyPath:@"rows" options:0 context:@"rows"];
        }

        if (_syncStyle == SWTableViewSyncStyleReload) {
            [self.tableView reloadData];
            return;
        }

        // PartialUpdateSection
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
                NSParameterAssert(imp); // clean analyze warning
                imp(self.tableView, updateSEL, indexes, UITableViewRowAnimationAutomatic);
            } return;
            case NSKeyValueChangeSetting: {
                [self.tableView reloadData];
            } return;
        } return;
    } else if (context == @"rows") {
        NSParameterAssert([NSThread isMainThread]);
        if (_syncStyle == SWTableViewSyncStyleReload) {
            [self.tableView reloadData];
            return;
        }

        // PartialUpdate
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
                NSParameterAssert(imp);
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

- (id<SWCellFactory>)defaultCellFactory {
    return [SWCellFactory defaultFactory];
}

- (id<SWCellFactory>)cellFactory {
    if (nil == _cellFactory) {
        return [self defaultCellFactory];
    }
    return _cellFactory;
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

#pragma mark Cell
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id viewModel = [self modelForRowAtModelIndexPath:indexPath];
    CGFloat height = [self.cellFactory heightForTableView:tableView model:viewModel];
    if (_cellDecorator && [_cellDecorator respondsToSelector:@selector(tableView:suggestHeight:forModel:atIndexPath:)]) {
        [_cellDecorator tableView:tableView suggestHeight:&height forModel:viewModel atIndexPath:indexPath];
    }
    return height;
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

#pragma mark header & footer
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    id header = [_model objectInSectionsAtIndex:section].header;
    id<SWCellFactory> factory;
    if (header && [(factory = self.cellFactory) respondsToSelector:@selector(heightForSectionHeaderInTableView:model:)]) {
        return [factory heightForSectionHeaderInTableView:tableView model:header];
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    id header = [_model objectInSectionsAtIndex:section].header;
    id<SWCellFactory> factory;
    if (header && [(factory = self.cellFactory) respondsToSelector:@selector(sectionHeaderForTableView:model:)]) {
        return [factory sectionHeaderForTableView:tableView model:header];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    id footer = [_model objectInSectionsAtIndex:section].footer;
    id<SWCellFactory> factory;
    if (footer && [(factory = self.cellFactory) respondsToSelector:@selector(heightForSectionFooterInTableView:model:)]) {
        return [factory heightForSectionFooterInTableView:tableView model:footer];
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    id footer = [_model objectInSectionsAtIndex:section].footer;
    id<SWCellFactory> factory;
    if (footer && [(factory = self.cellFactory) respondsToSelector:@selector(sectionFooterForTableView:model:)]) {
        return [factory sectionFooterForTableView:tableView model:footer];
    }
    return nil;
}

#pragma mark edit
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_model deleteModelsAtIndexPaths:@[indexPath]];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_model canEditRowAtIndexPath:indexPath];
}

#pragma mark callback
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
