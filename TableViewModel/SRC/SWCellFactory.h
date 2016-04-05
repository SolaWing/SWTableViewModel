//
//  SWCellFactory.h
//  TableViewModel
//
//  Created by SolaWing on 16/3/25.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** protocol which cell need to follow for used in SWCellFactory */
@protocol SWFactoryCell <NSObject>

@required
- (void)loadModel:(id)model;

@optional
+ (CGFloat)heightForModel:(id)model;

@end

@protocol SWCellFactory <NSObject>

- (UITableViewCell *)cellForTableView:(UITableView *)tableView model:(id)model;
- (CGFloat)heightForTableView:(UITableView *)tableView model:(id)model;

@end

@interface SWCellFactory : NSObject <SWCellFactory>

+ (instancetype)defaultFactory;

- (UITableViewCell *)cellForTableView:(UITableView *)tableView model:(id)model;
- (CGFloat)heightForTableView:(UITableView *)tableView model:(id)model;

@end

/** app need to implement this or use subclass and implement method in this */
@interface SWCellFactory (cellClass)

- (Class)cellClassForModel:(id)model;

@end
