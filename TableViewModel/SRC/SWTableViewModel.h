//
//  SWTableViewModel.h
//  TableViewModel
//
//  Created by SolaWing on 16/3/24.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SWTableViewModelDelegate;

@interface SWTableSectionViewModel : NSObject

+ (instancetype)newWithRows:(nullable NSArray*)rows;
+ (instancetype)newWithRows:(nullable NSArray*)rows header:(nullable id)header footer:(nullable id)footer;
/** map each element to call newWithRows */
+ (NSArray<SWTableSectionViewModel*>*)arrayOfSectionsRows:(NSArray*)sections;

@property (nonatomic, strong, nullable) id header;    ///< header view model
@property (nonatomic, strong, nullable) id footer;    ///< footer view model
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
+ (instancetype)newWithRows:(nullable NSArray*)rows;
/** init with a array of sections */
+ (instancetype)newWithSections:(nullable NSArray*)sections;
/** init with a array of array of rows */
+ (instancetype)newWithSectionRows:(nullable NSArray*)sections;

@property (nonatomic, weak, nullable) id<SWTableViewModelDelegate> delegate;
/** if need to change section, use KVC mutable array api */
@property (nonatomic, copy) NSArray<SWTableSectionViewModel*>* sections;

/** NOTE will raise exception for invalid indexPath */
- (id)modelAtIndexPath:(NSIndexPath*)indexPath;

/** these method should called by view, it only call delegate, subclass may override to implement it */
- (void)selectModelAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL)canEditRowAtIndexPath:(NSIndexPath*)indexPath;
- (void)deleteModelsAtIndexPaths:(NSArray<NSIndexPath*>*)indexPaths;


#pragma mark - KVC array accessors for sections
- (NSUInteger)indexOfObjectInSections:(SWTableSectionViewModel*)section;
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

/** following methods as the indexPaths version of modify underlying models.
 * the indexPath section should valid, and row will be batch packed in NSIndexSet */

- (void)insertObjects:(NSArray*)models atIndexPaths:(NSArray*)indexPaths; ///< indexPath.row should be the result position
- (void)replaceObjects:(NSArray*)models atIndexPaths:(NSArray*)indexPaths;
- (void)removeObjectsAtIndexPaths:(NSArray*)indexPaths;

#pragma mark end sections
#pragma mark -

@end

@protocol SWTableViewModelDelegate <NSObject>

@optional
- (void)tableViewModel:(SWTableViewModel*)sender didSelectModel:(id)model atIndexPath:(NSIndexPath*)indexPath;
- (BOOL)tableViewModel:(SWTableViewModel*)sender canEditModel:(id)model atIndexPath:(NSIndexPath*)indexPath;
/** return indexPaths which would really deleted, or nil to deny deleting */
- (nullable NSArray<NSIndexPath*>*)tableViewModel:(SWTableViewModel*)sender wouldDeleteModels:(NSArray*)models atIndexPaths:(NSArray<NSIndexPath*>*)indexPaths;

@end

NS_ASSUME_NONNULL_END
