//
//  SWCellDecorator.h
//  TableViewModel
//
//  Created by SolaWing on 16/4/5.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SWTableViewSyncStyle) {
    SWTableViewSyncStyleNone = 0, // do nothing when model change
    SWTableViewSyncStylePartialUpdate = 1, // call partial update methods
    SWTableViewSyncStyleReload = 2, // call reload methods
};

/** object use to decorate cell, such as add a separator line */
@protocol SWCellDecorator <NSObject>

@optional
/** you can change the pHeight to desired value */
- (void)tableView:(UITableView*)tableView suggestHeight:(inout CGFloat*)pHeight forModel:(id)model atIndexPath:(NSIndexPath*)indexPath;
/** give receiver a change to config cell */
- (void)tableView:(UITableView*)tableView decorateCell:(UITableViewCell*)cell forModel:(id)model atIndexPath:(NSIndexPath*)indexPath;

@end

