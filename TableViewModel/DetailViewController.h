//
//  DetailViewController.h
//  TableViewModel
//
//  Created by SolaWing on 16/3/24.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

