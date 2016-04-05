//
//  SWCellDecorator.m
//  TableViewModel
//
//  Created by SolaWing on 16/4/5.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWCellDecorator.h"
#import <objc/runtime.h>

@implementation SWCellHeadSeperatorLineDecorator

- (instancetype)init {
    if (self = [super init]) {
        _color = [UIColor lightGrayColor];
    }
    return self;
}

- (void)tableView:(UITableView *)tableView decorateCell:(UITableViewCell *)cell forModel:(id)model atIndexPath:(NSIndexPath *)indexPath {
    bool shouldShowSeparator = true;
    UIView* separatorView = (UIView*)objc_getAssociatedObject(cell, (__bridge void*)self);
    if (shouldShowSeparator) {
        if (!separatorView) {
            CGRect frame = cell.bounds;
            CGFloat height = 1 / [UIScreen mainScreen].scale;
            frame.origin.y = frame.size.height - height;
            frame.origin.x = 11;
            frame.size.width-=frame.origin.x;
            frame.size.height = height;
            separatorView = [[UIView alloc] initWithFrame:frame];
            separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
            [cell addSubview:separatorView];
            objc_setAssociatedObject(cell, (__bridge void*)self, separatorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        separatorView.backgroundColor = self.color;
        separatorView.hidden = NO;
    } else {
        separatorView.hidden = YES;
    }
}

@end
