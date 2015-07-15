//
//  CKPromisePerformanceTests.m
//  CKPromise
//
//  Created by Cristian Kocza on 15/07/15.
//  Copyright © 2015 Cristik. All rights reserved.
//

@interface CKPromisePerformanceTests : CKPromiseTestsBase
@end

@implementation CKPromisePerformanceTests

- (void)testPerformance_thenProperty {
    [self measureBlock:^{
        for(int i=0; i<100000; i++) {
            promise.then(^{
                
            }, ^NSNumber*(int code){
                return nil;
            });
            promise = [CKPromise promise];
        }
    }];
}

- (void)testPerformance_thenMethod {
    [self measureBlock:^{
        for(int i=0; i<100000; i++) {
            [promise then:^{
                
            } :^NSNumber*(int code){
                return nil;
            }];
            promise = [CKPromise promise];
        }
    }];
}

@end
