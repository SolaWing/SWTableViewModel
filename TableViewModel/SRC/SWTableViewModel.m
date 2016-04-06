//
//  SWTableViewModel.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/24.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWTableViewModel+Private.h"
#import <UIKit/UIKit.h>
@implementation SWTableViewModel

@synthesize sections = _sections;

+ (instancetype)newWithRows:(NSArray *)rows {
    SWTableSectionViewModel* section = [SWTableSectionViewModel newWithRows:rows];
    SWTableViewModel* ret = [self new];
    [ret insertObject:section inSectionsAtIndex:0];
    return ret;
}

+ (instancetype)newWithSections:(NSArray *)sections {
    SWTableViewModel* ret = [self new];
    if (sections) {
        [ret->_sections setArray:sections];
    }
    return ret;
}

+ (instancetype)newWithSectionRows:(NSArray *)sections {
    NSMutableArray* sectionModels = [NSMutableArray arrayWithCapacity:sections.count];
    for (id element in sections){
        [sectionModels addObject:[SWTableSectionViewModel newWithRows:element]];
    }
    return [self newWithSections:sectionModels];
}

- (instancetype)init {
    if (self = [super init]) {
        _sections = [NSMutableArray new];
    }
    return self;
}

- (id)modelAtIndexPath:(NSIndexPath *)indexPath {
    return [[self objectInSectionsAtIndex:indexPath.section] objectInRowsAtIndex:indexPath.row];
}

- (void)selectModelAtIndexPath:(NSIndexPath *)indexPath {
    id delegate = _delegate;
    if ([delegate respondsToSelector:@selector(tableViewModel:didSelectModel:)]) {
        id model = [self modelAtIndexPath:indexPath];
        [delegate tableViewModel:self didSelectModel:model];
    }
}

#pragma mark - KVC array accessors for sections
- (NSUInteger)indexOfObjectInSections:(SWTableSectionViewModel*)section {
    return [_sections indexOfObjectIdenticalTo:section];
}
- (NSUInteger)countOfSections { return _sections.count; }
- (SWTableSectionViewModel *)objectInSectionsAtIndex:(NSUInteger)index { return _sections[index]; }
- (void)getSections:(SWTableSectionViewModel * __unsafe_unretained [])buffer range:(NSRange)range {
    [_sections getObjects:buffer range:range];
}

#pragma mark Mutable accessors for sections
- (void)insertObject:(SWTableSectionViewModel *)object inSectionsAtIndex:(NSUInteger)index {
    [_sections insertObject:object atIndex:index];
}

- (void)insertSections:(NSArray *)array atIndexes:(NSIndexSet *)indexes {
    [_sections insertObjects:array atIndexes:indexes];
}

- (void)removeObjectFromSectionsAtIndex:(NSUInteger)index {
    [_sections removeObjectAtIndex:index];
}

- (void)removeSectionsAtIndexes:(NSIndexSet *)indexes {
    [_sections removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInSectionsAtIndex:(NSUInteger)index withObject:(SWTableSectionViewModel*)object {
    [_sections replaceObjectAtIndex:index withObject:object];
}

- (void)replaceSectionsAtIndexes:(NSIndexSet *)indexes withSections:(NSArray *)array {
    [_sections replaceObjectsAtIndexes:indexes withObjects:array];
}

#pragma mark end sections
#pragma mark -

@end

@implementation SWTableSectionViewModel

@synthesize rows = _rows;

+ (instancetype)newWithRows:(NSArray *)rows {
    SWTableSectionViewModel* ret = [self new];
    ret.rows = rows;
    return ret;
}

+ (instancetype)newWithRows:(NSArray*)rows header:(id)header footer:(id)footer {
    SWTableSectionViewModel *ret = [self new];
    ret.rows = rows;
    ret.header = header;
    ret.footer = footer;
    return ret;
}

- (void)setRows:(NSArray *)rows {
    _rows = [rows mutableCopy];
}

#pragma mark - KVC array accessors for rows
- (NSUInteger)countOfRows { return _rows.count; }
- (id)objectInRowsAtIndex:(NSUInteger)index { return _rows[index]; }
- (void)getRows:(id __unsafe_unretained [])buffer range:(NSRange)range {
    [_rows getObjects:buffer range:range];
}

#pragma mark Mutable accessors for rows
- (void)insertObject:(id)object inRowsAtIndex:(NSUInteger)index {
    [_rows insertObject:object atIndex:index];
}

- (void)insertRows:(NSArray *)array atIndexes:(NSIndexSet *)indexes {
    [_rows insertObjects:array atIndexes:indexes];
}

- (void)removeObjectFromRowsAtIndex:(NSUInteger)index {
    [_rows removeObjectAtIndex:index];
}

- (void)removeRowsAtIndexes:(NSIndexSet *)indexes {
    [_rows removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInRowsAtIndex:(NSUInteger)index withObject:(id)object {
    [_rows replaceObjectAtIndex:index withObject:object];
}

- (void)replaceRowsAtIndexes:(NSIndexSet *)indexes withRows:(NSArray *)array {
    [_rows replaceObjectsAtIndexes:indexes withObjects:array];
}

#pragma mark end rows
#pragma mark -


@end
