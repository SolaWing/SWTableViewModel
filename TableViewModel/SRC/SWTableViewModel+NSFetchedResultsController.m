//
//  SWTableViewModel+NSFetchedResultsController.m
//  TableViewModel
//
//  Created by SolaWing on 16/4/7.
//  Copyright © 2016年 SW. All rights reserved.
//

#import "SWTableViewModel+NSFetchedResultsController.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@implementation SWTableViewModel (NSFetchedResultsController)

+ (instancetype)newWithFetchResultsController:(NSFetchedResultsController *)controller andConvertor:(id  _Nonnull (^)(id _Nonnull))convertor {
    NSParameterAssert( controller );
    SWTableViewModel* vm = [self new];
    vm.fetchConvertor = convertor;
    [vm syncWithFetchController:controller];
    return vm;
}

- (void)syncWithFetchController:(NSFetchedResultsController*)controller {
    if (!controller.fetchedObjects) {
        NSError* error;
        if (![controller performFetch:&error]) {
            NSLog(@"fetch controller error: %@", error);
            return;
        }
    }

    self.sections = [self convertFetchSectionInfo2SectionViewModel:controller.sections];
    controller.delegate = self;
}

- (NSArray*)convertFetchSectionInfo2SectionViewModel:(NSArray*)fetchSections {
    if ( fetchSections.count == 0 ) { return nil; }

    SWFetchViewModelConvertor convertor = self.fetchConvertor;
    NSArray*(^convertArray)(NSArray* objects);
    if (convertor) {
        convertArray = ^(NSArray* objects) {
            NSMutableArray* rows = [[NSMutableArray alloc] initWithCapacity:objects.count];
            [objects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
                [rows addObject:convertor(obj)];
            }];
            return rows;
        };
    } else {
        convertArray = ^(NSArray* objects) { return objects; };
    }

    NSMutableArray* sections = [NSMutableArray new];
    [fetchSections enumerateObjectsUsingBlock:^(id<NSFetchedResultsSectionInfo>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        [sections addObject:[SWTableSectionViewModel
                            newWithRows:convertArray([obj objects])
                                 header:[obj name] footer:nil]];
    }];
    return sections;
}

- (SWFetchViewModelConvertor)fetchConvertor {
    return objc_getAssociatedObject(self, @selector(fetchConvertor));
}

- (void)setFetchConvertor:(SWFetchViewModelConvertor)fetchConvertor {
    objc_setAssociatedObject(self, @selector(fetchConvertor), fetchConvertor, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - NSFetchedResultsControllerDelegate
- (NSMutableDictionary*)fetchChangedObjects {
    return objc_getAssociatedObject(self, @selector(fetchChangedObjects));
}

- (void)setFetchChangedObjects:(NSMutableDictionary*)fetchChangedObjects {
    objc_setAssociatedObject(self, @selector(fetchChangedObjects), fetchChangedObjects, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSParameterAssert( [self fetchChangedObjects] == nil );
    self.fetchChangedObjects = [NSMutableDictionary new];
}

#define InsertSectionKey @"insertSections"
#define InsertSectionInfoKey @"insertSectionInfos"
#define DeletedSectionKey @"deletedSections"
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    NSMutableDictionary* fetchChangedObjects = self.fetchChangedObjects;

    void ( ^__unsafe_unretained addSectionIndex )( id ) = ^( id type ) {
        NSMutableIndexSet* indexSet = fetchChangedObjects[type];
        if ( !indexSet ) {
            indexSet = [NSMutableIndexSet indexSetWithIndex:sectionIndex];
            fetchChangedObjects[type] = indexSet;
        } else {
            [indexSet addIndex:sectionIndex];
        }
    };

    switch (type) {
        case NSFetchedResultsChangeInsert: {
            addSectionIndex(InsertSectionKey);
        } break;
        case NSFetchedResultsChangeDelete: {
            addSectionIndex(DeletedSectionKey);
        } break;
        default: { NSAssert(false, @"section change shouldn't have type %lu", type); } break;
    }
}

#define InsertObjectsKey @"insertObjects"
#define DeletedObjectsKey @"deletedObjects"
#define UpdatedObjectsKey @"updatedObjects"
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    NSMutableDictionary* fetchChangedObjects = self.fetchChangedObjects;

    void ( ^__unsafe_unretained addObjectIndexPath )( id, NSIndexPath* ) = ^( id type, NSIndexPath* indexPath ) {
        NSArray* changedObjects = fetchChangedObjects[type];
        if ( !changedObjects ) {
            changedObjects = [NSArray arrayWithObjects:
                       [NSMutableArray arrayWithObject:anObject],
                       [NSMutableArray arrayWithObject:indexPath],
                       nil];
            fetchChangedObjects[type] = changedObjects;
        } else {
            [changedObjects[0] addObject:anObject];
            [changedObjects[1] addObject:indexPath];
        }
    };

    switch( type ){
        case NSFetchedResultsChangeInsert: {
            addObjectIndexPath( InsertObjectsKey, newIndexPath );
        } break;
        case NSFetchedResultsChangeDelete: {
            addObjectIndexPath( DeletedObjectsKey, indexPath );
        } break;
        case NSFetchedResultsChangeMove: {
            addObjectIndexPath( DeletedObjectsKey, indexPath );
            addObjectIndexPath( InsertObjectsKey, newIndexPath );
        } break;
        case NSFetchedResultsChangeUpdate: {
            addObjectIndexPath( UpdatedObjectsKey, indexPath );
        } break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // according to tableView update order:
    // the reload, delete indexPath is the original indexPath.
    // the insert is the result indexPath
    // move operation like a remove and insert.
    NSMutableDictionary *fetchChangedObjects = self.fetchChangedObjects;
    self.fetchChangedObjects = nil;
    NSIndexSet* insertSection = fetchChangedObjects[InsertSectionKey];
    if (insertSection) {
        fetchChangedObjects[InsertSectionInfoKey] =
            [controller.sections objectsAtIndexes:insertSection];
    }

    if ([NSThread isMainThread]) {
        [self updateWithPatchDictionary:fetchChangedObjects];
    } else {
        [self performSelectorOnMainThread:@selector(updateWithPatchDictionary:) withObject:fetchChangedObjects waitUntilDone:NO];
    }
}

- (void)updateWithPatchDictionary:(NSDictionary*)patchDictionary {
    // patchDictionary may contains invalid section data.
    // such as duplicate insert section and insert section objects
    // so need to filter out these invalid indexPath

    SWFetchViewModelConvertor convertor = self.fetchConvertor;
    NSArray* updatedObjects = patchDictionary[UpdatedObjectsKey];
    if (updatedObjects) {
        NSArray* models = updatedObjects[0];
        NSArray* indexPaths = updatedObjects[1];
        if (convertor) {
            NSMutableArray* convertModels = [[NSMutableArray alloc] initWithCapacity:models.count];
            for (id element in models){
                [convertModels addObject:convertor(element)];
            }
            models = convertModels;
        }
        [self replaceObjects:models atIndexPaths:indexPaths];
    }

    NSIndexSet* deletedSections = patchDictionary[DeletedSectionKey];
    NSArray* deletedObjects = patchDictionary[DeletedObjectsKey];
    if (deletedObjects) {
        NSMutableArray* indexPaths = deletedObjects[1];
        if (deletedSections) {
            [indexPaths filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSIndexPath*  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings){
                return ![deletedSections containsIndex:evaluatedObject.section];
            }]];
        }
        [self removeObjectsAtIndexPaths:indexPaths];
    }

    if (deletedSections) {
        [self removeSectionsAtIndexes:deletedSections];
    }

    NSIndexSet* insertedSections = patchDictionary[InsertSectionKey];
    if (insertedSections) {
        NSArray* sections = patchDictionary[InsertSectionInfoKey];
        [self insertSections:[self convertFetchSectionInfo2SectionViewModel:sections]
                   atIndexes:insertedSections];
    }

    NSArray* insertObjects = patchDictionary[InsertObjectsKey];
    if (insertObjects) {
        NSMutableArray* models = insertObjects[0];
        NSMutableArray* indexPaths = insertObjects[1];
        if (insertedSections) {
            NSIndexSet* toRemove = [indexPaths indexesOfObjectsPassingTest:^BOOL(NSIndexPath*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
                return [insertedSections containsIndex:obj.section];
            }];
            if (toRemove.count > 0) {
                [indexPaths removeObjectsAtIndexes:toRemove];
                [models removeObjectsAtIndexes:toRemove];
            }
        }
        if (indexPaths.count > 0) {
            if (convertor) {
                NSMutableArray* convertModels = [[NSMutableArray alloc] initWithCapacity:models.count];
                for (id element in models){
                    [convertModels addObject:convertor(element)];
                }
                models = convertModels;
            }
            [self insertObjects:models atIndexPaths:indexPaths];
        }
    }
}

@end
