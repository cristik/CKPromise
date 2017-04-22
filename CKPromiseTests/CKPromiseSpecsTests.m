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

#import "CKPromiseTestsBase.h"

@interface CKPromiseSpecsTests : CKPromiseTestsBase
@end

@implementation CKPromiseSpecsTests

// # Promise States

//A promise must be in one of three states: pending, fulfilled, or rejected.
- (void)test_initialState_isPending{
    __block BOOL handlerExecuted = NO;;
    promise.then(^{
        handlerExecuted = YES;
    }, ^{
        handlerExecuted = YES;
    });
    wait(YES, 0.02);
    XCTAssertFalse(handlerExecuted, @"Incorrect state");
}

// 1. When pending, a promise:
// may transition to either the fulfilled or rejected state.
- (void)test_resolve_transitionsToResolved{
    __block BOOL handlerExecuted = NO;;
    promise.then(nil, ^{
        handlerExecuted = YES;
    });
    wait(YES, 0.02);
    [promise resolve:nil];
    XCTAssertFalse(handlerExecuted, @"Incorrect state");
}

- (void)test_reject_transitionsToRejected{
    __block BOOL handlerExecuted = NO;;
    promise.then(^{
        handlerExecuted = YES;
    }, nil);
    wait(YES, 0.02);
    [promise reject:nil];
    XCTAssertFalse(handlerExecuted, @"Incorrect state");
}

//2. When fulfilled, a promise:
//2.i. must not transition to any other state.
- (void)test_resolve_cannotBeResolvedAgain{
    [promise resolve:nil];
    XCTAssertThrows([promise resolve:nil], @"Should throw exception");
}

- (void)test_resolve_cannotBeAlsoRejected{
    [promise resolve:nil];
    XCTAssertThrows([promise reject:nil], @"Should throw exception");
}

//2.ii. must have a value, which must not change.
//TODO: add test


//3. When rejected, a promise:
//3.i. must not transition to any other state.
- (void)test_reject_cannotBeRejectedAgain{
    [promise reject:nil];
    XCTAssertThrows([promise reject:nil], @"Should throw exception");
}

- (void)test_reject_cannotBeAlsoResolved{
    [promise reject:nil];
    XCTAssertThrows([promise resolve:nil], @"Should throw exception");
}

//3.ii. must have a reason, which must not change.
//TODO: add test


// # The then Method

//A promise must provide a then method to access its current or eventual value or reason.
//A promise's then method accepts two arguments:
//promise.then(onFulfilled, onRejected)
- (void)test_has_then_method{
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"@?@:"];
    XCTAssertTrue([promise respondsToSelector:@selector(then)], @"Should have a then method");
    XCTAssertEqualObjects([promise methodSignatureForSelector:@selector(then)], sig, @"Unexpected signature for then");
}

//1. Both onFulfilled and onRejected are optional arguments:
//1.i. If onFulfilled is not a function, it must be ignored.
//1.ii. If onRejected is not a function, it must be ignored.
- (void)test_resolve_withoutCallback{
    promise.then(nil, nil);
    [promise resolve:@1];
    //nothing should happen, no exceptions or other nasty stuff
    wait(NO, 0.1);
}

- (void)test_reject_withoutCallback{
    promise.then(nil, nil);
    [promise reject:@1];
    //nothing should happen, no exceptions or other nasty stuff
    wait(NO, 0.1);
}

//2. If onFulfilled is a function:
//2.i. it must be called after promise is fulfilled, with promise's value as its first argument.
//2.ii. it must not be called before promise is fulfilled.
//2.iii. it must not be called more than once.
//4. onFulfilled or onRejected must not be called until the execution context stack contains only platform code. [3.1].
- (void)test_resolve_executesTheCallback{
    __block BOOL executed = NO;
    __block BOOL rejectedExecuted = NO;
    __block int executeCount = 0;
    __block id value = nil;
    promise.then(^id(id val) {
        executed = YES;
        value = val;
        executeCount++;
        return nil;
    }, ^id(id rsn){
        rejectedExecuted = YES;
        return nil;
    });
    XCTAssertFalse(executed, @"Callback should not be executed before resolving");
    [promise resolve:@12];
    XCTAssertFalse(executed, @"Callback should not be executed in this cycle");
    wait(!executed, 1);
    XCTAssertTrue(executed, @"Resolved dallback not executed");
    XCTAssertFalse(rejectedExecuted, @"Rejected callback was executed");
    XCTAssertEqual(executeCount, 1, @"Callback not executed exactly once");
    XCTAssertEqualObjects(value, @12, @"Resolve value doesn't match");
}

//3. If onRejected is a function,
//3.i. it must be called after promise is rejected, with promise's reason as its first argument.
//3.ii. it must not be called before promise is rejected.
//3.iii. it must not be called more than once.
//4. onFulfilled or onRejected must not be called until the execution context stack contains only platform code. [3.1].
- (void)test_reject_executesTheCallback{
    __block BOOL executed = NO;
    __block BOOL resolvedExecuted = NO;
    __block int executeCount = 0;
    __block id reason = nil;
    promise.then(^(id value){
        resolvedExecuted = YES;
    }, ^(id aReason) {
        executed = YES;
        reason = aReason;
        executeCount++;
    });
    XCTAssertFalse(executed, @"Callback should not be executed before resolving");
    [promise reject:@13];
    XCTAssertFalse(executed, @"Callback should not be executed in this cycle");
    wait(!executed, 1);
    XCTAssertTrue(executed, @"Rejected dallback not executed");
    XCTAssertFalse(resolvedExecuted, @"Resolved callback was executed");
    XCTAssertEqual(executeCount, 1, @"Callback not executed exactly once");
    XCTAssertEqualObjects(reason, @13, @"Reject reason doesn't match");
}

//5. onFulfilled and onRejected must be called as functions (i.e. with no this value). [3.2]
// skipped, on ObjC blocks don't have self

//6. then may be called multiple times on the same promise.
//6.i. If/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then.
- (void)test_resolve_callbackOrder{
    NSMutableArray *callbacksOrder = [NSMutableArray arrayWithCapacity:3];
    promise.then(^id(id val) {
        [callbacksOrder addObject:@1];
        return nil;
    }, nil);
    promise.then(^id(id val) {
        [callbacksOrder addObject:@2];
        return nil;
    } ,nil);
    promise.then(^id(id val) {
        [callbacksOrder addObject:@3];
        return nil;
    }, nil);
    [promise resolve:@4];
    wait(callbacksOrder.count < 3, 1.0);
    XCTAssertEqualObjects(callbacksOrder, (@[@1,@2,@3]), @"Resolve callbacks not called in order");
}

//6.ii. If/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then.
- (void)test_reject_callbackOrder{
    NSMutableArray *callbacksOrder = [NSMutableArray arrayWithCapacity:3];
    promise.then(nil, ^id(id val) {
        [callbacksOrder addObject:@1];
        return nil;
    });
    promise.then(nil, ^id(id val) {
        [callbacksOrder addObject:@2];
        return nil;
    });
    promise.then(nil, ^id(id val) {
        [callbacksOrder addObject:@3];
        return nil;
    });
    [promise reject:@4];
    wait(callbacksOrder.count < 3, 1.0);
    XCTAssertEqualObjects(callbacksOrder, (@[@1,@2,@3]), @"Resolve callbacks not called in order");
}

//7. then must return a promise [3.3]
- (void)test_then_returnsAnotherPromise{
    CKPromise *promise2 = promise.then(nil, nil);
    XCTAssertTrue([promise2 isKindOfClass:[CKPromise class]], @"Expected a promise to be returned");
    XCTAssertFalse(promise2==promise, @"Expected a different promise");
}

// 7.i. If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).
- (void)test_then_resolvedCallbackReturnsValue_promise2IsResolvedWithThatValue{
    __block id value = nil;
    CKPromise *promise2 = promise.then(^id(id val){
        return @19;
    }, nil);
    promise2.then(^id(id val) {
        value = val;
        return nil;
    }, nil);
    [promise resolve:@18];
    wait(!value, 1.0);
    XCTAssertEqualObjects(value, @19, @"Incorrect promise2 value");
}

- (void)test_then_rejectedCallbackReturnsValue_promise2IsResolvedWithThatValue{
    __block id value = nil;
    CKPromise *promise2 = promise.then(nil, ^id(id rsn){
        return @29;
    });
    promise2.then(^id(id val) {
        value = val;
        return nil;
    }, nil);
    [promise reject:@28];
    wait(!value, 1.0);
    XCTAssertEqualObjects(value, @29, @"Incorrect promise2 value");

}

// 7.ii. If either onFulfilled or onRejected throws an exception e, promise2 must be rejected with e as the reason.
- (void)test_then_resolvedThrowsException_promise2IsRejectedWithThatException{
    NSException *ex = [NSException exceptionWithName:@"aa" reason:@"bb" userInfo:nil];
    __block id reason = nil;
    CKPromise *promise2 = promise.then(^id(id val){
        [ex raise];
        return @21;
    }, nil);
    promise2.then(nil, ^id(id aReason){
        reason = aReason;
        return nil;
    });
    [promise resolve:@18];
    wait(!reason, 1.0);
    XCTAssertEqual(reason, ex, @"Incorrect promise2 reason");
}

- (void)test_then_rejectedThrowsException_promise2IsRejectedWithThatException{
    NSException *ex = [NSException exceptionWithName:@"aa" reason:@"bb" userInfo:nil];
    __block id reason = nil;
    CKPromise *promise2 = promise.then(nil, ^id(id rsn){
        [ex raise];
        return @29;
    });
    promise2.then(nil, ^id(id aReason){
        reason = aReason;
        return nil;
    });
    [promise reject:@28];
    wait(!reason, 0.02);
    XCTAssertEqual(reason, ex, @"Incorrect promise2 reason");
    
}

//7.iii. If onFulfilled is not a function and promise1 is fulfilled, promise2 must be fulfilled with the same value as promise1.
- (void)test_then_noResolvedCallback_promise2IsResolvedWithPromise1Value{
    __block id value = nil;
    CKPromise *promise2 = promise.then(nil, nil);
    promise2.then(^id(id val) {
        value = val;
        return nil;
    }, nil);
    [promise resolve:@18];
    wait(!value, 0.02);
    XCTAssertEqualObjects(value, @18, @"Incorrect promise2 value");
}

//7.iv. If onRejected is not a function and promise1 is rejected, promise2 must be rejected with the same reason as promise1.
- (void)test_then_noRejectedCallback_promise2IsRejectedWithPromise1Reason{
    __block id reason = nil;
    CKPromise *promise2 = promise.then(nil, nil);
    promise2.then(nil, ^id(id aReason){
        reason = aReason;
        return nil;
    });
    [promise reject:@18];
    wait(!reason, 0.02);
    XCTAssertEqualObjects(reason, @18, @"Incorrect promise2 value");
}

// #The Promise Resolution Procedure

//The promise resolution procedure is an abstract operation taking as input a promise and a value, which we denote as [[Resolve]](promise, x). If x is a thenable, it attempts to make promise adopt the state of x, under the assumption that x behaves at least somewhat like a promise. Otherwise, it fulfills promise with the value x.
//
//This treatment of thenables allows promise implementations to interoperate, as long as they expose a Promises/A+-compliant then method. It also allows Promises/A+ implementations to "assimilate" nonconformant implementations with reasonable then methods.
//
//To run [[Resolve]](promise, x), perform the following steps:

//1. If promise and x refer to the same object, reject promise with a TypeError as the reason.
- (void)test_resolve_samePromise_raiseException{
    XCTAssertThrowsSpecific([promise resolve:promise], CKTypeErrorException, @"Should raise TypeError exception");
}

//2. If x is a promise, adopt its state [3.4]:
//2.i. If x is pending, promise must remain pending until x is fulfilled or rejected.
- (void)test_resolve_pendingPromise_staysInPending{
    CKPromise *x = [CKPromise promise];
    [promise resolve:x];
    __block BOOL handlerExecuted = NO;;
    promise.then(^{
        handlerExecuted = YES;
    }, ^{
        handlerExecuted = YES;
    });
    wait(!handlerExecuted, 0.02);
    XCTAssertFalse(handlerExecuted, @"Should be in pending");
}

//2.ii. If/when x is fulfilled, fulfill promise with the same value.
- (void)test_resolve_resolvingPromise_resolves{
    __block id value = nil;
    promise.then(^id(id val) {
        value = val;
        return nil;
    }, nil);
    CKPromise *x = [CKPromise promise];
    [promise resolve:x];
    [x resolve:@"x"];
    __block BOOL handlerExecuted = NO;;
    promise.then(^{
        handlerExecuted = YES;
    }, ^{
        handlerExecuted = YES;
    });
    wait(!value, 0.02);
    XCTAssertTrue(handlerExecuted, @"Should be in resolved");
    XCTAssertEqualObjects(value, @"x", @"Should have been resolved with same value");
}

//2.iii. If/when x is rejected, reject promise with the same reason.
- (void)test_resolve_rejectingPromise_rejects{
    __block id reason = nil;
    promise.then(nil, ^id(id rsn) {
        reason = rsn;
        return nil;
    });
    CKPromise *x = [CKPromise promise];
    [promise resolve:x];
    [x reject:@"y"];
    __block BOOL handlerExecuted = NO;;
    promise.then(^{
        handlerExecuted = YES;
    }, ^{
        handlerExecuted = YES;
    });
    wait(!reason, 0.02);
    XCTAssertEqualObjects(reason, @"y", @"Should have been rejected with same reason");
}

// 3. Otherwise, if x is an object or function,
// skip it, doesn't apply to ObjC

// 4. If x is not an object or function, fulfill promise with x.
- (void)test_resolve_noPromise{
    __block id value = nil;
    promise.then(^id(id val) {
        value = val;
        return nil;
    }, nil);
    [promise resolve:@"z"];
    wait(!value, 0.1);
    XCTAssertEqualObjects(value, @"z", @"Should have been resolved with the provided value");
}

// If a promise is resolved with a thenable that participates in a circular thenable chain, such that the recursive nature of [[Resolve]](promise, thenable) eventually causes [[Resolve]](promise, thenable) to be called again, following the above algorithm will lead to infinite recursion. Implementations are encouraged, but not required, to detect such recursion and reject promise with an informative TypeError as the reason. [3.6]


- (void)test_resolve_transformResolvedInRejected {
    __block BOOL rejected  = NO;
    promise.then(^{
        return [CKPromise rejectedWith:nil];
    }, nil).then(nil,^{
        rejected = YES;
    });
    [promise resolve:nil];
    wait(!rejected, 0.02);
    XCTAssertTrue(rejected);
}

- (void)test_reject_transformRejectedInResolved {
    __block BOOL resolved  = NO;
    promise.then(nil, ^{
        return [CKPromise resolvedWith:nil];
    }).then(^{
        resolved = YES;
    }, nil);
    [promise resolve:nil];
    wait(!resolved, 0.02);
    XCTAssertTrue(resolved);
}
@end
