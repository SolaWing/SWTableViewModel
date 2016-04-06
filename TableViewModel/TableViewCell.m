//
//  TableViewCell.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/27.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "TableViewCell.h"

@interface TableViewCell () <SWFactoryView>

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

- (Class)headerClassForModel:(id)model { return [UITableViewHeaderFooterView class]; }
- (Class)footerClassForModel:(id)model { return [UITableViewHeaderFooterView class]; }

@end

@interface UITableViewHeaderFooterView (ViewModel) <SWFactoryView>

@end

@implementation UITableViewHeaderFooterView (ViewModel)

- (void)loadModel:(id)model {
    // UITableViewHeaderFooterView's textLabel style got reset, it's not dependable
    // use NSAttributedString will cause crash.
    // when floating and delete rows or sections, sectionView pos not get updated
    // how awful the UITableViewHeaderFooterView is.
    if ([model isKindOfClass:[NSString class]]) {
        self.textLabel.text = model;
    } else if ([model isKindOfClass:[NSDictionary class]]) {
        [self.textLabel setValuesForKeysWithDictionary:model];
        UIColor* backgroundColor = model[@"backgroundColor"];
        if (backgroundColor) { self.contentView.backgroundColor = backgroundColor; }
    }
}

@end
