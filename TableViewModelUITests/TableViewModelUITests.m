//
//  TableViewModelUITests.m
//  TableViewModelUITests
//
//  Created by SolaWing on 16/3/24.
//  Copyright © 2016年 SW. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import "SWTableViewModel+NSFetchedResultsController.h"

@interface TableViewModelUITests : XCTestCase

@end

@implementation TableViewModelUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBindUI {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.tables.staticTexts[@"Normal TableView"] tap];
    
    XCUIElementQuery *detailNavigationBarsQuery = app.navigationBars;
    XCUIElement *addButton = detailNavigationBarsQuery.buttons[@"Add"];
    for (NSUInteger i = 0; i < 20; ++i) {
        [addButton tap];
    }
    [detailNavigationBarsQuery.buttons[@"Edit"] tap];
    [detailNavigationBarsQuery.buttons[@"Done"] tap];

}

@end
