//
//  SWTableViewModel.h
//  TableViewModel
//
//  Created by SolaWing on 16/3/24.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SWTableSectionViewModel : NSObject

+ (instancetype)newWithRows:(NSArray*)rows;

@property (nonatomic, strong) id header;    ///< header view model
@property (nonatomic, strong) id footer;    ///< footer view model
@property (nonatomic, copy) NSArray* rows;  ///< array of row view model

#pragma mark - KVC array accessors for rows
- (NSUInteger)countOfRows;
- (id)objectInRowsAtIndex:(NSUInteger)index;
- (void)getRows:(id __unsafe_unretained [])buffer range:(NSRange)range;

#pragma mark Mutable accessors for rows
- (void)insertObject:(id)object inRowsAtIndex:(NSUInteger)index;
- (void)insertRows:(NSArray *)array atIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromRowsAtIndex:(NSUInteger)index;
- (void)removeRowsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRowsAtIndex:(NSUInteger)index withObject:(id)object;
- (void)replaceRowsAtIndexes:(NSIndexSet *)indexes withRows:(NSArray *)array;
#pragma mark end rows
#pragma mark -

@end

@interface SWTableViewModel : NSObject

/** init with a list as a section of rows */
+ (instancetype)newWithRows:(NSArray*)rows;
/** init with a array of sections */
+ (instancetype)newWithSections:(NSArray*)sections;

/** if need to change section, use KVC mutable array api */
@property (nonatomic, copy, readonly) NSArray<SWTableSectionViewModel*>* sections;
@property (nonatomic, copy) void (^selectModel)(SWTableViewModel *sender, id rowModel);

#pragma mark - KVC array accessors for sections
- (NSUInteger)countOfSections;
- (SWTableSectionViewModel *)objectInSectionsAtIndex:(NSUInteger)index;
- (void)getSections:(SWTableSectionViewModel * __unsafe_unretained [])buffer range:(NSRange)range;

#pragma mark Mutable accessors for sections
- (void)insertObject:(SWTableSectionViewModel *)object inSectionsAtIndex:(NSUInteger)index;
- (void)insertSections:(NSArray *)array atIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromSectionsAtIndex:(NSUInteger)index;
- (void)removeSectionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSectionsAtIndex:(NSUInteger)index withObject:(SWTableSectionViewModel*)object;
- (void)replaceSectionsAtIndexes:(NSIndexSet *)indexes withSections:(NSArray *)array;
#pragma mark end sections
#pragma mark -

@end
