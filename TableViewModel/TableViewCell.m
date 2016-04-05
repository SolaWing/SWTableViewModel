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

@implementation SeperatorCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor orangeColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)loadModel:(id)model {};
+ (CGFloat)heightForModel:(id)model { return 3; }

@end

// @interface SWCellFactory (testCellClass)

// - (Class)cellClassForModel:(id)model;

// @end

#import <objc/runtime.h>
@implementation SWCellFactory (testCellClass)

- (Class)cellClassForModel:(id)model {
    if (class_isMetaClass(object_getClass(model))) {
        return model;
    }
    return [TableViewCell class];
}

@end
