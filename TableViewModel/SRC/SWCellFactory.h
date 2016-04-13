//
//  SWCellFactory.h
//  TableViewModel
//
//  Created by SolaWing on 16/3/25.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** protocol which view need to follow for used in SWCellFactory */
@protocol SWFactoryView <NSObject>

@required
- (void)loadModel:(id)model;

@optional
+ (CGFloat)heightForModel:(id)model withWidth:(CGFloat)width;

@end

@protocol SWCellFactory <NSObject>

@required
- (UITableViewCell *)cellForTableView:(UITableView *)tableView model:(id)model;
- (CGFloat)heightForTableView:(UITableView *)tableView model:(id)model;

@optional
- (UIView*)sectionHeaderForTableView:(UITableView *)tableView model:(id)model;
- (UIView*)sectionFooterForTableView:(UITableView *)tableView model:(id)model;
- (CGFloat)heightForSectionHeaderInTableView:(UITableView *)tableView model:(id)model;
- (CGFloat)heightForSectionFooterInTableView:(UITableView *)tableView model:(id)model;

@end

@interface SWCellFactory : NSObject <SWCellFactory>

+ (instancetype)defaultFactory;

- (UITableViewCell *)cellForTableView:(UITableView *)tableView model:(id)model;
- (CGFloat)heightForTableView:(UITableView *)tableView model:(id)model;

- (UIView*)sectionHeaderForTableView:(UITableView *)tableView model:(id)model;
- (UIView*)sectionFooterForTableView:(UITableView *)tableView model:(id)model;
- (CGFloat)heightForSectionHeaderInTableView:(UITableView *)tableView model:(id)model;
- (CGFloat)heightForSectionFooterInTableView:(UITableView *)tableView model:(id)model;

@end

/** app need to implement this or use subclass and implement method in this */
@interface SWCellFactory (cellClass)

- (Class)cellClassForModel:(id)model;
- (Class)headerClassForModel:(id)model;
- (Class)footerClassForModel:(id)model;

@end
