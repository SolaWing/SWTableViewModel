//
//  SWTableViewBinder.m
//  TableViewModel
//
//  Created by SolaWing on 16/8/9.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWTableViewBinder.h"
#import <objc/runtime.h>

#define STRONGIFY_TABLEVIEW_OR_RETURN() \
    UITableView* tableView = self.tableView; if (!tableView) { return; }

@implementation SWTableViewBinder

- (void)dealloc {
    self.model = nil; // release KVO
}

- (instancetype)init { NSAssert(false, @"shouldn't call this method!"); return [self initWithTableView:nil]; }
- (instancetype)initWithTableView:(UITableView *)tableView {
    if (self = [super init]) {
        _tableView = tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView model:(SWTableViewModel *)model {
    if (self = [self initWithTableView:tableView]) {
        self.model = model;
    }
    return self;
}

#pragma mark - property
static inline bool isSyncing(SWTableViewSyncStyle style) {
    return style > 0;
}

- (void)setModel:(SWTableViewModel *)model {
    if (_model != model) {
        UITableView* tv = self.tableView;
        if (_model && isSyncing(_syncStyle)) {
            [self unbindModel:_model];
        }
        _model = model;
        [tv reloadData];
        if (_model && isSyncing(_syncStyle)) {
            [self bindModel:_model];
        }
    }
}

- (void)setSyncStyle:(SWTableViewSyncStyle)syncStyle {
    if (syncStyle != _syncStyle) {
        bool const changeSync = (isSyncing(_syncStyle) != isSyncing(syncStyle));
        if (_model && isSyncing(_syncStyle)) {
            if (changeSync) { [self unbindModel:_model]; }
            else if (_model.updating) { [self endUpdates]; }
        }
        _syncStyle = syncStyle;
        if (_model && isSyncing(_syncStyle)) {
            if (changeSync) { [self bindModel:_model]; }
            else if (_model.updating) { [self beginUpdates]; }
        }
    }
}

- (void)bindModel:(SWTableViewModel*)model {
    [model addObserver:self forKeyPath:@"updating" options:NSKeyValueObservingOptionOld context:@"updating"];
    if (model.updating) { [self beginUpdates]; } // sync updating stat

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

    [model removeObserver:self forKeyPath:@"updating" context:@"updating"];
    if (model.updating) { [self endUpdates]; } // end sync updating stat
}

static inline bool shouldReloadTableView(SWTableViewBinder* self) {
    // NOTE: return value shouldn't change during batchUpdates
    return self->_syncStyle == SWTableViewSyncStyleReload;
}

- (void)beginUpdates {
    if ( !shouldReloadTableView(self) ) {
        [self.tableView beginUpdates];
    }
}

- (void)endUpdates {
    if ( shouldReloadTableView(self) ) {
        [self.tableView reloadData];
    } else {
        [self.tableView endUpdates];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    // BUGS: float section footer may move to bottom when partially update tableView
    // NOTE: when not batch update, delete rows may cause contentSize and offset change.
    //       that's why use batch update. performance is also one factor.
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

        STRONGIFY_TABLEVIEW_OR_RETURN();
        if ( shouldReloadTableView(self) ) {
            if (!_model.updating) { // delay reloadData to endUpdating
                [tableView reloadData];
            }
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
                goto PartialUpdateSection;
            PartialUpdateSection: {
                NSIndexSet* indexes = change[NSKeyValueChangeIndexesKey];
                void(*imp)(UITableView*, SEL, NSIndexSet*, UITableViewRowAnimation)
                    = (void*)[tableView methodForSelector:updateSEL];
                NSParameterAssert(imp); // clean analyze warning
                imp(tableView, updateSEL, indexes, UITableViewRowAnimationAutomatic);
            } return;
            case NSKeyValueChangeSetting: {
                NSAssert( !_model.updating, @"shouldn't replace entire sections when batch updating!" );
                [tableView reloadData];
            } return;
        } return;
    } else if (context == @"rows") {
        NSParameterAssert([NSThread isMainThread]);
        STRONGIFY_TABLEVIEW_OR_RETURN();
        if ( shouldReloadTableView(self) ) {
            if (!_model.updating) { // delay reloadData to endUpdating
                [tableView reloadData];
            }
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
                goto PartialUpdate;
            PartialUpdate: {
                NSIndexSet* indexes = change[NSKeyValueChangeIndexesKey];
                NSMutableArray* indexPaths = [NSMutableArray new];
                [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop){
                    [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:section]];
                }];
                void (*imp)(UITableView*, SEL, NSArray*, UITableViewRowAnimation)
                    = (void*)[tableView methodForSelector:updateSEL];
                NSParameterAssert(imp);
                imp(tableView, updateSEL, indexPaths, UITableViewRowAnimationAutomatic);
            } return;
            case NSKeyValueChangeSetting: {
                [tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
            } return;
        } return;
    } else if (context == @"updating") {
        STRONGIFY_TABLEVIEW_OR_RETURN();
        BOOL oldValue = [change[NSKeyValueChangeOldKey] boolValue];
        BOOL newValue = _model.updating;
        if (oldValue != newValue) {
            // when reloadSync Style, reload when endUpdating
            // when PartialUpdate Style, call beginUpdates and endUpdates
            if (newValue) {
                [self beginUpdates];
            } else {
                [self endUpdates];
            }
        } return;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

@implementation UITableView (SWTableViewBinder)

static inline SWTableViewBinder* viewBinderOrDefault(UITableView* self){
    SWTableViewBinder* binder = objc_getAssociatedObject(self, @selector(viewBinder));
    if (!binder) {
        binder = [[SWTableViewBinder alloc] initWithTableView:self];
        objc_setAssociatedObject(self, @selector(viewBinder), binder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return binder;
}

- (SWTableViewBinder*)viewBinder {
    return objc_getAssociatedObject(self, @selector(viewBinder));
}

- (void)setViewBinder:(SWTableViewBinder*)viewBinder {
    objc_setAssociatedObject(self, @selector(viewBinder), viewBinder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SWTableViewModel *)bindModel {
    return self.viewBinder.model;
}

- (void)setBindModel:(SWTableViewModel *)bindModel {
    viewBinderOrDefault(self).model = bindModel;
}

- (SWTableViewSyncStyle)bindSyncStyle {
    return self.viewBinder.syncStyle;
}

- (void)setBindSyncStyle:(SWTableViewSyncStyle)bindSyncStyle {
    viewBinderOrDefault(self).syncStyle = bindSyncStyle;
}

- (id<SWCellFactory>)bindCellFactory {
    return self.viewBinder.cellFactory;
}

- (void)setBindCellFactory:(id<SWCellFactory>)bindCellFactory {
    viewBinderOrDefault(self).cellFactory = bindCellFactory;
}

- (id<SWCellDecorator>)bindCellDecorator {
    return self.viewBinder.cellDecorator;
}

- (void)setBindCellDecorator:(id<SWCellDecorator>)bindCellDecorator {
    viewBinderOrDefault(self).cellDecorator = bindCellDecorator;
}

@end
