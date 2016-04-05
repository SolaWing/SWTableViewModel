//
//  SWCellFactory.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/25.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWCellFactory.h"
#import "TableViewCell.h"

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
    UITableViewCell<SWFactoryCell>* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    [cell loadModel:model];

    return cell;
}


@end
