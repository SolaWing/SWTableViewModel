//
//  SWTableViewBinder.h
//  TableViewModel
//
//  Created by SolaWing on 16/8/9.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SWTableViewModel.h"
#import "SWCellFactory.h"
#import "SWTableViewHeader.h"

/** this class is used as tableView dataSource and delegate to bind tableView
 * content and behaviour to other classes like TableViewModel, SWCellFactory, etc..
 * NOTE: tableView and binder is 1V1 relationship, and shouldn't change after set */
@interface SWTableViewBinder : NSObject <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithTableView:(UITableView*)tableView NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTableView:(UITableView*)tableView model:(SWTableViewModel*)model;

/** tableView's dataSource and delegate will change to this object */
@property (nonatomic, weak, readonly) UITableView* tableView;

/** the viewModel used by tableView. when set to new model, call reloadData */
@property (nonatomic, strong) SWTableViewModel* model;

/** behaviour when model change.
 * NOTE: shouldn't change value when model is updating!
 */
@property (nonatomic) SWTableViewSyncStyle syncStyle;

/** cell factory to use, default use default SWCellFactory */
@property (nonatomic, strong) id<SWCellFactory> cellFactory;

/** decorator used to additional config for cell */
@property (nonatomic, strong) id<SWCellDecorator> cellDecorator;

#pragma mark subclass method
- (id<SWCellFactory>)defaultCellFactory; ///< return a default factory

@end

@interface UITableView (SWTableViewBinder)

/** binder use to provide content */
@property (nonatomic, strong) SWTableViewBinder* viewBinder;

/** following is property redirect to SWTableViewBinder.
 * set property will create a default SWTableViewBinder when none */

/** the viewModel used by tableView. when set to new model, call reloadData */
@property (nonatomic, strong) SWTableViewModel* bindModel;

/** behaviour when model change.
 * NOTE: shouldn't change value when model is updating!
 */
@property (nonatomic) SWTableViewSyncStyle bindSyncStyle;

/** cell factory to use, default use default SWCellFactory */
@property (nonatomic, strong) id<SWCellFactory> bindCellFactory;

/** decorator used to additional config for cell */
@property (nonatomic, strong) id<SWCellDecorator> bindCellDecorator;

@end
