//
//  SWTableViewModel+Private.h
//  TableViewModel
//
//  Created by SolaWing on 16/3/24.
//  Copyright © 2016年 SW. All rights reserved.
//

#ifndef SWTableViewModel_Private_h
#define SWTableViewModel_Private_h

#import "SWTableViewModel.h"

@interface SWTableSectionViewModel () {
    NSMutableArray* _rows;
}

@end

@interface SWTableViewModel () {
    NSMutableArray* _sections;
}

@end

#endif /* SWTableViewModel_Private_h */
