//
//  TableViewCell.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/27.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "TableViewCell.h"

@interface TableViewCell () <SWFactoryCell>

@end

@implementation TableViewCell

- (void)loadModel:(id)model {
    NSDictionary* dict = (id)model;
    self.textLabel.text = dict[@"text"];
}

@end

// @interface SWCellFactory (testCellClass)

// - (Class)cellClassForModel:(id)model;

// @end

@implementation SWCellFactory (testCellClass)

- (Class)cellClassForModel:(id)model {
    return [TableViewCell class];
}

@end
