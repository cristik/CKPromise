// Copyright (c) 2014-2015, Cristian Kocza
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@interface CKPromiseAggregateTests : CKPromiseTestsBase
@end

@implementation CKPromiseAggregateTests

- (void)test_chained_onePromiseFails{
    NSMutableArray *callbacksOrder = [NSMutableArray arrayWithCapacity:3];
    promise.success(^(id value){
        [callbacksOrder addObject:@1];
        return [CKPromise resolvedWith:@1];
    }).success(^(id value){
        [callbacksOrder addObject:@2];
        return [CKPromise rejectedWith:@2];
    }).success(^(id value){
        [callbacksOrder addObject:@3];
        return [CKPromise resolvedWith:@3];
    }).failure(^(){
        [callbacksOrder addObject:@4];
    });
    [promise resolve:@0];
    wait(callbacksOrder.count < 3, 0.1);
    XCTAssertEqualObjects(callbacksOrder, (@[@1,@2,@4]), @"Not the expected callbacks");
}

- (void)test_aggregate_waitsForAllPromises{
    CKPromise *promise1 = [CKPromise promise];
    CKPromise *promise2 = [CKPromise promise];
    CKPromise *promise3 = [CKPromise promise];
    promise = [CKPromise when:@[promise1, promise2, promise3]];
    [promise1 resolve:nil];
    [promise2 resolve:nil];
    __block BOOL handlerExecuted = NO;
    promise.then(^{
        handlerExecuted = YES;
    }, ^{
        handlerExecuted = YES;
    });
    wait(!handlerExecuted, 0.02);
    XCTAssertFalse(handlerExecuted, @"Should be in pending until all promises have a resolution");
}

- (void)test_aggregate_resolvesIfAllPromisesResolve{
    CKPromise *promise1 = [CKPromise promise];
    CKPromise *promise2 = [CKPromise promise];
    promise = [CKPromise when:@[promise1, promise2]];
    [promise1 resolve:nil];
    [promise2 resolve:nil];
    __block BOOL handlerExecuted = NO;;
    promise.then(^{
        handlerExecuted = YES;
    }, ^{
        handlerExecuted = YES;
    });
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Should be resolved if all promises have are resolved");
}

- (void)test_aggregate_rejectsIfOnePromiseFails{
    CKPromise *promise1 = [CKPromise promise];
    CKPromise *promise2 = [CKPromise promise];
    promise = [CKPromise when:@[promise1, promise2]];
    [promise1 reject:nil];
    [promise2 resolve:nil];
    __block BOOL handlerExecuted = NO;
    promise.then(nil, ^{
        handlerExecuted = YES;
    });
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Should be resolved if all promises have are resolved");
}

- (CKPromise*)alteredPromise{
    return promise.then(^id(int val){
        if(val != 1) return [CKPromise rejectedWith:@(val)];
        else return [CKPromise resolvedWith:@(val)];
    }, nil);
}

- (void)test_promise_alteration_success{
    CKPromise *promise2 = [self alteredPromise];
    __block BOOL handlerExecuted = NO;
    __block int value = 0;
    promise2.then(^(int val){
        handlerExecuted = YES;
        value = val;
    }, nil);
    [promise resolve:@1];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Should be resolved");
    XCTAssertEqual(value, 1, @"Expected to receive the resolve value");
}

- (void)test_promise_alteration_success_but_altered_rejected{
    CKPromise *promise2 = [self alteredPromise];
    __block BOOL handlerExecuted = NO;
    __block int reason = 0;
    promise2.then(nil, ^(int rsn){
        handlerExecuted = YES;
        reason = rsn;
    });
    [promise resolve:@2];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Should be resolved");
    XCTAssertEqual(reason, 2, @"Expected to receive the resolve value");
}

- (void)test_promise_alteration_reject{
    CKPromise *promise2 = [self alteredPromise];
    __block BOOL handlerExecuted = NO;
    __block int reason = 0;
    promise2.then(nil, ^(int rsn){
        handlerExecuted = YES;
        reason = rsn;
    });
    [promise reject:@3];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Should be resolved");
    XCTAssertEqual(reason, 3, @"Expected to receive the resolve value");
}

@end
