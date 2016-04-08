//
//  SWTableViewModel.m
//  TableViewModel
//
//  Created by SolaWing on 16/3/24.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWTableViewModel+Private.h"
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

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
    return [self newWithSections:[SWTableSectionViewModel arrayOfSectionsRows:sections]];
}

- (instancetype)init {
    if (self = [super init]) {
        _sections = [NSMutableArray new];
    }
    return self;
}

- (void)setSections:(NSArray<SWTableSectionViewModel *> *)sections {
    if (sections) {
        _sections = sections.mutableCopy;
    } else {
        _sections = [NSMutableArray new];
    }
}

- (id)modelAtIndexPath:(NSIndexPath *)indexPath {
    return [[self objectInSectionsAtIndex:indexPath.section] objectInRowsAtIndex:indexPath.row];
}

- (void)selectModelAtIndexPath:(NSIndexPath *)indexPath {
    id delegate = _delegate;
    if ([delegate respondsToSelector:@selector(tableViewModel:didSelectModel:atIndexPath:)]) {
        id model = [self modelAtIndexPath:indexPath];
        [delegate tableViewModel:self didSelectModel:model atIndexPath:indexPath];
    }
}

- (BOOL)canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    id delegate = _delegate;
    if ([delegate respondsToSelector:@selector(tableViewModel:canEditModel:atIndexPath:)]) {
        id model = [self modelAtIndexPath:indexPath];
        return [delegate tableViewModel:self canEditModel:model atIndexPath:indexPath];
    }
    return NO;
}

- (void)deleteModelsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (indexPaths.count == 0) { return; }

    id delegate = _delegate;
    if ([delegate respondsToSelector:@selector(tableViewModel:wouldDeleteModels:atIndexPaths:)]) {
        NSMutableArray* models = [NSMutableArray new];
        for (NSIndexPath* element in indexPaths){
            [models addObject:[self modelAtIndexPath:element]];
        }
        indexPaths = [delegate tableViewModel:self wouldDeleteModels:models atIndexPaths:indexPaths];
    }
    [self removeObjectsAtIndexPaths:indexPaths];
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

#pragma mark - indexPaths version of modify models
typedef struct {
    CFMutableArrayRef models;
    CFTypeRef indexSets;
} _M_IPair;

/** convert models pair with indexPaths to array pair with indexSet, and put into buffers */
static void convertModelsOfIndexPathsToArrayOfIndexSets(NSArray* models, NSArray* indexPaths, _M_IPair* buffers, NSUInteger count) {
    [models enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        NSIndexPath* indexPath = indexPaths[idx];
        NSUInteger section = indexPath.section;
        NSCParameterAssert( section < count );

        _M_IPair* pair = buffers + section;
        if (!(pair->indexSets)) {
            pair->indexSets = CFBridgingRetain([NSMutableIndexSet new]);
            pair->models = CFArrayCreateMutable(nil, 0, &kCFTypeArrayCallBacks);
        }
        NSMutableIndexSet* indexes = (__bridge id)(pair->indexSets);
        NSMutableArray* models = (__bridge id)(pair->models);
        if ([indexes containsIndex:indexPath.row]) {
            NSLog(@"WARNING: repeat indexPath %@ for model %@", indexPath, obj);
        } else {
            NSUInteger index = [indexes countOfIndexesInRange:NSMakeRange(0, indexPath.row)];
            [models insertObject:obj atIndex:index];
            [indexes addIndex:indexPath.row];
        }
    }];
}

- (void)insertObjects:(NSArray *)models atIndexPaths:(NSArray *)indexPaths {
    NSParameterAssert( models.count <= indexPaths.count );
    NSUInteger sectionCount = _sections.count;
    if (models.count > 0 && sectionCount > 0) {
        size_t totalSize = sizeof(_M_IPair) * sectionCount;
        _M_IPair * pairs = alloca( totalSize );
        memset(pairs, 0, totalSize);

        convertModelsOfIndexPathsToArrayOfIndexSets(models, indexPaths, pairs, sectionCount);
        for (NSUInteger i = 0; i < sectionCount; ++i) {
            if (pairs[i].indexSets) {
                NSIndexSet* indexSet = CFBridgingRelease(pairs[i].indexSets);
                NSArray* array = CFBridgingRelease(pairs[i].models);
                SWTableSectionViewModel* section = [self objectInSectionsAtIndex:i];
                [section insertRows:array atIndexes:indexSet];
            }
        }
    }
}

- (void)replaceObjects:(NSArray *)models atIndexPaths:(NSArray *)indexPaths {
    NSParameterAssert( models.count <= indexPaths.count );
    NSUInteger sectionCount = _sections.count;
    if (models.count > 0 && sectionCount > 0) {
        size_t totalSize = sizeof(_M_IPair) * sectionCount;
        _M_IPair * pairs = alloca( totalSize );
        memset(pairs, 0, totalSize);

        convertModelsOfIndexPathsToArrayOfIndexSets(models, indexPaths, pairs, sectionCount);
        for (NSUInteger i = 0; i < sectionCount; ++i) {
            if (pairs[i].indexSets) {
                NSIndexSet* indexSet = CFBridgingRelease(pairs[i].indexSets);
                NSArray* array = CFBridgingRelease(pairs[i].models);
                SWTableSectionViewModel* section = [self objectInSectionsAtIndex:i];
                [section replaceRowsAtIndexes:indexSet withRows:array];
            }
        }
    }
}

/** convert indexPaths to indexSet and put in buffer, should release it if not equal to nil */
static void convertIndexPathsToIndexSets(NSArray* indexPaths, CFTypeRef* sectionBuffers, NSUInteger count) {
    // convert to array of indexSet
    for (NSIndexPath* element in indexPaths) {
        NSUInteger section = element.section;
        NSCParameterAssert( section < count );

        if ( !sectionBuffers[section] ) {
            sectionBuffers[section] = CFBridgingRetain([NSMutableIndexSet new]);
        }
        [(__bridge NSMutableIndexSet *)(sectionBuffers[section]) addIndex:element.row];
    }
}

- (void)removeObjectsAtIndexPaths:(NSArray *)indexPaths {
    NSUInteger sectionCount = _sections.count;
    if (indexPaths.count > 0 && sectionCount > 0) {
        size_t indexSetsSize = sizeof(CFTypeRef) * sectionCount;
        CFTypeRef * indexSets = alloca( indexSetsSize );
        memset(indexSets, 0, indexSetsSize);

        convertIndexPathsToIndexSets(indexPaths, indexSets, sectionCount);

        // reverse deleted section
        for (NSInteger i = sectionCount - 1; i >= 0; --i) {
            if (indexSets[i]) {
                NSMutableIndexSet* index = CFBridgingRelease(indexSets[i]);
                SWTableSectionViewModel* section = [self objectInSectionsAtIndex:i];
                [section removeRowsAtIndexes:index];
            }
        }
    }
}


- (NSString *)description {
    return [[NSString stringWithFormat:@"sections: %@", _sections]
        stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
}

@end


#pragma mark - SWTableSectionViewModel
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

+ (NSArray<SWTableSectionViewModel*>*)arrayOfSectionsRows:(NSArray*)sections {
    NSMutableArray* sectionModels = [NSMutableArray arrayWithCapacity:sections.count];
    for (id element in sections){
        [sectionModels addObject:[SWTableSectionViewModel newWithRows:element]];
    }
    return sectionModels;
}

- (instancetype)init {
    if (self = [super init]) {
        _rows = [NSMutableArray new];
    }
    return self;
}

- (void)setRows:(NSArray *)rows {
    if (rows) {
        _rows = [rows mutableCopy];
    } else {
        _rows = [NSMutableArray new];
    }
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

- (NSString *)description {
    return [[NSString stringWithFormat:@"rows: %@", _rows]
        stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
}

@end
