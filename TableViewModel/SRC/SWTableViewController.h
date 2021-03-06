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
#import "SWTableViewHeader.h"

/** this controller use to display a static tableView, and don't provide edit feature
 * you may subclass to add feature or customize behaviour */
@interface SWTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

/** the viewModel used by tableView. when set to new model, call reloadData */
@property (nonatomic, strong) SWTableViewModel* model;

/** behaviour when model change.
 * NOTE: shouldn't change value when model is updating!
 */
@property (nonatomic) SWTableViewSyncStyle syncStyle;

/** this class use self.view as tableView, subclass may implement loadView, getter, setter. */
@property (nonatomic, strong) UITableView* tableView;

/** cell factory to use, default use default SWCellFactory */
@property (nonatomic, strong) id<SWCellFactory> cellFactory;

/** decorator used to additional config for cell */
@property (nonatomic, strong) id<SWCellDecorator> cellDecorator;

// A Boolean value indicating if the controller clears the selection when the table appears
@property (nonatomic) bool clearsSelectionOnViewWillAppear;

/** return model in SWTableViewModel at indexPath */
- (id)modelForRowAtModelIndexPath:(NSIndexPath *)indexPath;

#pragma mark - subclass to override
/** default cellFactory to use when not set cellFactory */
- (id<SWCellFactory>)defaultCellFactory;
- (UITableViewRowAnimation)animationForUpdateSEL:(SEL)sel;

@end
