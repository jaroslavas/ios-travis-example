//
//  testAppUITests.m
//  testAppUITests
//
//  Created by Jaroslav O on 22/08/16.
//  Copyright © 2016 j. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "testAppUITests-Swift.h"

@interface testAppUITests : XCTestCase

@end

@implementation testAppUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [Snapshot setupSnapshot:app];
    [app launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.images[@"test_img"] tap];
    [[[[app.otherElements containingType:XCUIElementTypeImage identifier:@"test_img"] childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:1] tap];
    
    [Snapshot snapshot:@"01-TestScreen" waitForLoadingIndicator:NO];
    
}

@end
