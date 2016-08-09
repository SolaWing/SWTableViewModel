//
//  TableViewModelTests.m
//  TableViewModelTests
//
//  Created by SolaWing on 16/4/7.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import "SWTableViewModel+NSFetchedResultsController.h"
#import "SWTableViewController.h"
#import "SWTableViewBinder.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface TableViewModelTests : XCTestCase

@property (strong) NSManagedObjectContext* context;

@end

@implementation TableViewModelTests

- (void)setUp {
    [super setUp];

    NSManagedObjectModel* model = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]];
    NSPersistentStoreCoordinator* coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    [coord addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.context.persistentStoreCoordinator = coord;

    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCoreData {
#define DefaultSection @"1 Section"
    for (NSUInteger i = 0; i < 30; ++i) {
        NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:self.context];
        [object setValue:[NSString stringWithFormat:@"Cell %lu",i] forKey:@"name"];
        [object setValue:@(i) forKey:@"sort"];
        [object setValue:DefaultSection forKey:@"section"];
    }
    [self.context save:nil];

    NSFetchRequest* fetch = [NSFetchRequest fetchRequestWithEntityName:@"Entity"];
    fetch.sortDescriptors = @[
        [NSSortDescriptor sortDescriptorWithKey:@"section" ascending:YES],
        [NSSortDescriptor sortDescriptorWithKey:@"sort" ascending:YES]
    ];
    NSFetchedResultsController* controller = [[NSFetchedResultsController alloc]
    initWithFetchRequest:fetch managedObjectContext:self.context sectionNameKeyPath:@"section" cacheName:nil];

    SWTableViewModel* viewModel = [SWTableViewModel newWithFetchResultsController:controller andConvertor:nil];

    SWTableSectionViewModel* section = viewModel.sections[0];
    [controller.fetchedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        XCTAssertEqual(obj, section.rows[idx]);
    }];

    NSManagedObjectContext* newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    newContext.parentContext = self.context;

    // async change object
    [newContext performBlock:^{
        NSArray* models = [newContext executeFetchRequest:fetch error:nil];
        for (NSUInteger i = 10; i < 13; ++i) {
            [newContext deleteObject:models[i]];
        }
        for (NSUInteger i = 15; i < 16; ++i) {
            [newContext deleteObject:models[i]];
        }
        for (NSUInteger i = 18; i < 20; ++i) {
            [newContext deleteObject:models[i]];
        }

        for (NSUInteger i = 100; i < 120; ++i) {
            NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
            [object setValue:[NSString stringWithFormat:@"Insert %lu",i] forKey:@"name"];
            [object setValue:@(i) forKey:@"sort"];
            [object setValue:DefaultSection forKey:@"section"];
        }
        for (NSUInteger i = 20; i < 23; ++i) {
            NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
            [object setValue:[NSString stringWithFormat:@"Insert %lu",i] forKey:@"name"];
            [object setValue:@(i) forKey:@"sort"];
            [object setValue:DefaultSection forKey:@"section"];
        }

        for (NSUInteger i = 25; i < 27; ++i) {
            [models[i] setValue:@(i - 20) forKey:@"sort"];
        }

        for (NSUInteger i = 5; i < 7; ++i) {
            [models[i] setValue:[NSString stringWithFormat:@"Replace %lu",i] forKey:@"name"];
        }
        for (NSUInteger i = 3; i < 4; ++i) {
            [models[i] setValue:[NSString stringWithFormat:@"Replace %lu",i] forKey:@"name"];
        }

        [newContext save:nil];
    }];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];

    [controller.fetchedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        XCTAssertEqual(obj, section.rows[idx]);
    }];

    newContext = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSConfinementConcurrencyType];
    newContext.parentContext = self.context;

    // add section
    for (NSUInteger i = 30; i < 60; ++i) {
        NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
        [object setValue:[NSString stringWithFormat:@"Section Insert %lu",i] forKey:@"name"];
        [object setValue:@(i) forKey:@"sort"];
        [object setValue:@"0 Section" forKey:@"section"];
    }

    for (NSUInteger i = 30; i < 60; ++i) {
        NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
        [object setValue:[NSString stringWithFormat:@"Section Insert %lu",i] forKey:@"name"];
        [object setValue:@(i) forKey:@"sort"];
        [object setValue:@"5 Section" forKey:@"section"];
    }
    for (NSUInteger i = 30; i < 60; ++i) {
        NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
        [object setValue:[NSString stringWithFormat:@"Section Insert %lu",i] forKey:@"name"];
        [object setValue:@(i) forKey:@"sort"];
        [object setValue:@"3 Section" forKey:@"section"];
    }
    for (NSUInteger i = 30; i < 60; ++i) {
        NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
        [object setValue:[NSString stringWithFormat:@"Section Insert %lu",i] forKey:@"name"];
        [object setValue:@(i) forKey:@"sort"];
        [object setValue:@"8 Section" forKey:@"section"];
    }
    [newContext save:nil];

    [controller.sections enumerateObjectsUsingBlock:^(id<NSFetchedResultsSectionInfo>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        SWTableSectionViewModel* section = viewModel.sections[idx];
        XCTAssertEqualObjects(section.header, [obj name]);
        XCTAssertEqualObjects(section.rows, [obj objects]);
    }];

    // delete section and move section
    for (NSManagedObject* element in [controller.sections[1] objects]){
        NSManagedObject* obj = [newContext objectWithID:element.objectID];
        [newContext deleteObject:obj];
    }
    for (NSManagedObject* element in [controller.sections[2] objects]){
        NSManagedObject* obj = [newContext objectWithID:element.objectID];
        [obj setValue:@"9 Section" forKey:@"section"]; // move section
    }
    [newContext save:nil];
    [controller.sections enumerateObjectsUsingBlock:^(id<NSFetchedResultsSectionInfo>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        SWTableSectionViewModel* section = viewModel.sections[idx];
        XCTAssertEqualObjects(section.header, [obj name]);
        XCTAssertEqualObjects(section.rows, [obj objects]);
    }];

    viewModel = [SWTableViewModel newWithFetchResultsController:controller andConvertor:^id _Nonnull(id  _Nonnull obj){
        return [obj valueForKey:@"name"];
    }];

    // left 0, 5, 8, 9 section
    // mixed with add section, delete section, move section, change objects
    for (NSManagedObject* element in [controller.sections[0] objects]){
        NSManagedObject* obj = [newContext objectWithID:element.objectID];
        [obj setValue:@"7 Section" forKey:@"section"];
    }
    for (NSManagedObject* element in [controller.sections[0] objects]){
        NSManagedObject* obj = [newContext objectWithID:element.objectID];
        [obj setValue:@(arc4random()) forKey:@"sort"]; // random move rows in 5 section
    }
    for (NSManagedObject* element in [controller.sections[3] objects]){
        NSManagedObject* obj = [newContext objectWithID:element.objectID];
        [obj setValue:@"this is a name" forKey:@"name"]; // update object
    }
    for (NSManagedObject* element in [controller.sections[2] objects]){
        NSManagedObject* obj = [newContext objectWithID:element.objectID];
        [newContext deleteObject:obj]; // delete 8 section
    }
    for (NSUInteger i = 30; i < 60; ++i) { // insert 6 section
        NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
        [object setValue:[NSString stringWithFormat:@"Section Insert %lu",i] forKey:@"name"];
        [object setValue:@(i) forKey:@"sort"];
        [object setValue:@"6 Section" forKey:@"section"];
    }
    for (NSUInteger i = 30; i < 40; ++i) { // insert 7 section
        NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
        [object setValue:[NSString stringWithFormat:@"Section Insert %lu",i] forKey:@"name"];
        [object setValue:@(i) forKey:@"sort"];
        [object setValue:@"7 Section" forKey:@"section"];
    }
    for (NSUInteger i = 30; i < 40; ++i) { // insert 5 section
        NSManagedObject* object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity" inManagedObjectContext:newContext];
        [object setValue:[NSString stringWithFormat:@"Section Insert %lu",i] forKey:@"name"];
        [object setValue:@(i) forKey:@"sort"];
        [object setValue:@"5 Section" forKey:@"section"];
    }
    [newContext save:nil];

    [controller.sections enumerateObjectsUsingBlock:^(id<NSFetchedResultsSectionInfo>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        SWTableSectionViewModel* section = viewModel.sections[idx];
        XCTAssertEqualObjects(section.header, [obj name]);
        XCTAssertEqualObjects(section.rows, [[obj objects] valueForKey:@"name"]);
    }];
}

- (void)testSyncController {
    // reloadData in ios9 should have only reload when update view
    SWTableViewController* controller = [[SWTableViewController alloc] init];
    UIWindow* window = [UIApplication sharedApplication].keyWindow;

    [window addSubview:controller.view];
    controller.view.frame = window.bounds;

    controller.model = [SWTableViewModel newWithSectionRows:@[
        @[@"array 1", @"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1"],
        @[@"array 2", @"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2"],
        @[@"array 3", @"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3"],
    ]];

    controller.view.backgroundColor = [UIColor redColor];
    [controller.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2] atScrollPosition:UITableViewScrollPositionBottom animated:NO];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];

    controller.syncStyle = SWTableViewSyncStylePartialUpdate;
    [controller.model batchUpdates:^{
        for (int i = 0; i < 100; ++i) {
            [controller.model.sections[2] replaceObjectInRowsAtIndex:2 withObject:@"replace 1"];
        }
        [controller.model.sections[2] removeObjectFromRowsAtIndex:3];
        [controller.model removeObjectFromSectionsAtIndex:1];
    }];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
}

- (void)testSyncBinder {
    // reloadData in ios9 should have only reload when update view
    UIWindow* window = [UIApplication sharedApplication].keyWindow;
    UITableView* tableView = [UITableView new];

    [window addSubview:tableView];
    tableView.frame = window.bounds;

    tableView.bindModel = [SWTableViewModel newWithSectionRows:@[
        @[@"array 1", @"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1",@"array 1"],
        @[@"array 2", @"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2",@"array 2"],
        @[@"array 3", @"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3",@"array 3"],
    ]];

    tableView.backgroundColor = [UIColor redColor];
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2] atScrollPosition:UITableViewScrollPositionBottom animated:NO];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];

    tableView.bindSyncStyle = SWTableViewSyncStylePartialUpdate;
    [tableView.bindModel batchUpdates:^{
        for (int i = 0; i < 100; ++i) {
            [tableView.bindModel.sections[2] replaceObjectInRowsAtIndex:2 withObject:@"replace 1"];
        }
        [tableView.bindModel.sections[2] removeObjectFromRowsAtIndex:3];
        [tableView.bindModel removeObjectFromSectionsAtIndex:1];
    }];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
