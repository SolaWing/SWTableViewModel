//
//  SWCellFactory.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/25.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWCellFactory.h"

#define kDefaultSectionHeight 22

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation SWCellFactory

+ (instancetype)defaultFactory {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once,^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (Class)headerClassForModel:(id)model { return nil; }
- (Class)footerClassForModel:(id)model { return nil; }

- (CGFloat)heightForTableView:(UITableView *)tableView model:(id)model {
    Class cellClass = [self cellClassForModel:model];
    NSParameterAssert(cellClass);

    if ([cellClass respondsToSelector:@selector(heightForModel:)]) {
        return [cellClass heightForModel:model];
    }

    return tableView.rowHeight;
}

- (UITableViewCell *)cellForTableView:(UITableView *)tableView model:(id)model {
    Class cellClass = [self cellClassForModel:model];
    NSParameterAssert(cellClass);

    NSString* identifier = NSStringFromClass(cellClass);
    UITableViewCell<SWFactoryView>* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    [cell loadModel:model];

    return cell;
}

static CGFloat heightForSection(Class cls, id model) {
    if ([cls respondsToSelector:@selector(heightForModel:)]) {
        return [cls heightForModel:model];
    }

    return kDefaultSectionHeight;
}

static UIView* getSectionView(UITableView* tableView, Class cls, id model) {
    UIView<SWFactoryView>* v;
    if ([cls isSubclassOfClass:[UITableViewHeaderFooterView class]]) {
        NSString* identifier = NSStringFromClass(cls);
        v = (id)[tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
        if (!v) {
             v = [[cls alloc] initWithReuseIdentifier:identifier];
        }
    } else {
        CGRect frame = tableView.bounds;
        frame.size.height = heightForSection(cls, model);
        v = [[cls alloc] initWithFrame:frame];
    }

    [v loadModel:model];
    return v;
}

- (CGFloat)heightForSectionHeaderInTableView:(UITableView *)tableView model:(id)model {
    Class cls = [self headerClassForModel:model];
    if (!cls) { return 0; }
    return heightForSection(cls, model);
}

- (UIView *)sectionHeaderForTableView:(UITableView *)tableView model:(id)model {
    Class cls = [self headerClassForModel:model];
    if (!cls) { return nil; }

    return getSectionView(tableView, cls, model);
}

- (CGFloat)heightForSectionFooterInTableView:(UITableView *)tableView model:(id)model {
    Class cls = [self footerClassForModel:model];
    if (!cls) { return 0; }
    return heightForSection(cls, model);
}

- (UIView *)sectionFooterForTableView:(UITableView *)tableView model:(id)model {
    Class cls = [self footerClassForModel:model];
    if (!cls) { return nil; }

    return getSectionView(tableView, cls, model);
}

@end
