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
#import "SWCellDecoratorProtocol.h"

/** this controller use to display a static tableView, and don't provide edit feature
 * you may subclass to add feature or customize behaviour */
@interface SWTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/** the viewModel used by tableView. when set to new model, call reloadData */
@property (nonatomic, strong) SWTableViewModel* model;
/** this class use self.view as tableView, subclass may implement loadView, getter, setter. */
@property (nonatomic, strong) UITableView* tableView;

/** decorator used to additional config for cell */
@property (nonatomic, strong) id<SWCellDecorator> cellDecorator;

/** return model in SWTableViewModel at indexPath */
- (id)modelForRowAtModelIndexPath:(NSIndexPath *)indexPath;

#pragma mark - subclass method
/** use default SWCellFactory. subclass can choose to use a different one */
- (id<SWCellFactory>)cellFactory;
@end
