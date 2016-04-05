//
//  SWTableViewController.h
//  TableViewModel
//
//  Created by SolaWing on 16/3/25.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SWTableViewModel.h"
#import "SWCellFactory.h"

/** a delegate use to provide view behaviour for tableView, can use as dataSource and delegate */
@interface SWTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) SWTableViewModel* model;
/** this class use self.view as tableView, subclass may implement loadView, getter, setter. */
@property (nonatomic, strong) UITableView* tableView;

#pragma mark - subclass method
/** use default SWCellFactory. subclass can choose to use a different one */
- (id<SWCellFactory>)cellFactory;
@end
