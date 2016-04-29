//
//  SWTableViewModel+NSFetchedResultsController.h
//  TableViewModel
//
//  Created by SolaWing on 16/4/7.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWTableViewModel.h"
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

typedef id __nonnull (^SWFetchViewModelConvertor)(id obj);

/** this category implement NSFetchedResultsControllerDelegate for convert and
 * bind NSFetchedResultsController source to SWTableViewModel */
@interface SWTableViewModel (NSFetchedResultsController) <NSFetchedResultsControllerDelegate>

/** create a SWTableViewModel through NSFetchedResultsController. use it's fetchedObjects, set as it's delegate to observe change
 * and may possible a convertor to convert object before put in tableViewModel */
+ (instancetype)newWithFetchResultsController:(NSFetchedResultsController*)controller andConvertor:(nullable SWFetchViewModelConvertor)convertor;

@property (nonatomic, copy, nullable) SWFetchViewModelConvertor fetchConvertor;

@end

NS_ASSUME_NONNULL_END
