//
//  KCPromiseTests.m
//  KCPromiseTests
//
//  Created by Cristian Kocza on 9/16/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "CKPromise.h"
#include <sys/time.h>

double microtime(){
    struct timeval time;
    gettimeofday(&time, NULL);
    return time.tv_sec + time.tv_usec / 1000000.0;
}

@interface CKPromiseTests : SenTestCase
@end

#define wait(condition, timeout) \
{\
double start = microtime();\
while((condition) && microtime() - start < timeout){\
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];\
}\
}


@implementation CKPromiseTests{
    CKPromise *promise;
}

- (void)setUp{
    [super setUp];
    promise = [CKPromise promise];
}

- (void)tearDown{
    [super tearDown];
}

// Callback types
- (void)test_acceptsResolveHandlerVoidVoid{
    __block BOOL handlerExecuted = NO;
    promise.done(^{
        handlerExecuted = YES;
    });
    [promise resolve:nil];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_acceptsResolveHandlerVoidId{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.done(^(id val){
        handlerExecuted = YES;
        resolveValue = val;
    });
    [promise resolve:@15];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
    STAssertEqualObjects(resolveValue, @15, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerVoidNSNumber{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.done(^(NSNumber *val){
        handlerExecuted = YES;
        resolveValue = val;
    });
    [promise resolve:@15];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
    STAssertEqualObjects(resolveValue, @15, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerIdVoid{
    __block BOOL handlerExecuted = NO;
    promise.done(^id{
        handlerExecuted = YES;
        return nil;
    });
    [promise resolve:nil];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_acceptsResolveHandlerNSStringVoid{
    __block BOOL handlerExecuted = NO;
    __block id value = nil;
    CKPromise *promise2 = promise.done(^NSString*{
        return @"abc";
    });
    promise2.then(^(id val){
        value = val;
        handlerExecuted = YES;
    }, nil);
    [promise resolve:nil];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
    STAssertEqualObjects(value, @"abc", @"Incorrect resolve value for promise2");
}

- (void)test_acceptsResolveHandlerIdId{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.done(^id(id val){
        handlerExecuted = YES;
        resolveValue = val;
        return nil;
    });
    [promise resolve:@16];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
    STAssertEqualObjects(resolveValue, @16, @"Incorrect resolve value");
}

- (void)test_acceptsRejectHandlerVoidVoid{
    __block BOOL handlerExecuted = NO;
    promise.fail(^{
        handlerExecuted = YES;
    });
    [promise reject:nil];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_acceptsRejectHandlerVoidId{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.fail(^(id val){
        handlerExecuted = YES;
        resolveValue = val;
    });
    [promise reject:@17];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
    STAssertEqualObjects(resolveValue, @17, @"Incorrect resolve value");
}

- (void)test_acceptsRejectHandlerIdVoid{
    __block BOOL handlerExecuted = NO;
    promise.fail(^id{
        handlerExecuted = YES;
        return nil;
    });
    [promise reject:nil];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_acceptsRejectHandlerIdId{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.fail(^id(id val){
        handlerExecuted = YES;
        resolveValue = val;
        return nil;
    });
    [promise reject:@18];
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Completion handler was not executed");
    STAssertEqualObjects(resolveValue, @18, @"Incorrect resolve value");
}

// scalar values
- (void)test_acceptsResolveHandlerVoidInt{
    __block int value = 0;
    promise.then(^(int val){
        value = val;
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    STAssertEquals(value, 27, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerVoidDouble{
    __block double value = 0;
    promise.then(^(double val){
        value = val;
    }, nil);
    [promise resolve:@28.98];
    wait(YES, 0.02);
    STAssertEquals(value, 28.98, @"Unexpected promise value");
}

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
    STAssertFalse(handlerExecuted, @"Incorrect state");
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
    STAssertFalse(handlerExecuted, @"Incorrect state");
}

- (void)test_reject_transitionsToRejected{
    __block BOOL handlerExecuted = NO;;
    promise.then(^{
        handlerExecuted = YES;
    }, nil);
    wait(YES, 0.02);
    [promise reject:nil];
    STAssertFalse(handlerExecuted, @"Incorrect state");
}

//2. When fulfilled, a promise:
//2.i. must not transition to any other state.
- (void)test_resolve_cannotBeResolvedAgain{
    [promise resolve:nil];
    STAssertThrows([promise resolve:nil], @"Should throw exception");
}

- (void)test_resolve_cannotBeAlsoRejected{
    [promise resolve:nil];
    STAssertThrows([promise reject:nil], @"Should throw exception");
}

//2.ii. must have a value, which must not change.
//TODO: add test


//3. When rejected, a promise:
//3.i. must not transition to any other state.
- (void)test_reject_cannotBeRejectedAgain{
    [promise reject:nil];
    STAssertThrows([promise reject:nil], @"Should throw exception");
}

- (void)test_reject_cannotBeAlsoResolved{
    [promise reject:nil];
    STAssertThrows([promise resolve:nil], @"Should throw exception");
}

//3.ii. must have a reason, which must not change.
//TODO: add test


// # The then Method

//A promise must provide a then method to access its current or eventual value or reason.
//A promise's then method accepts two arguments:
//promise.then(onFulfilled, onRejected)
- (void)test_has_then_method{
    NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:"@?@:"];
    STAssertTrue([promise respondsToSelector:@selector(then)], @"Should have a then method");
    STAssertEqualObjects([promise methodSignatureForSelector:@selector(then)], sig, @"Unexpected signature for then");
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
    STAssertFalse(executed, @"Callback should not be executed before resolving");
    [promise resolve:@12];
    STAssertFalse(executed, @"Callback should not be executed in this cycle");
    wait(!executed, 1);
    STAssertTrue(executed, @"Resolved dallback not executed");
    STAssertFalse(rejectedExecuted, @"Rejected callback was executed");
    STAssertEquals(executeCount, 1, @"Callback not executed exactly once");
    STAssertEqualObjects(value, @12, @"Resolve value doesn't match");
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
    promise.then(^id(id value){
        resolvedExecuted = YES;
        return nil;
    }, ^id(id aReason) {
        executed = YES;
        reason = aReason;
        executeCount++;
        return nil;
    });
    STAssertFalse(executed, @"Callback should not be executed before resolving");
    [promise reject:@13];
    STAssertFalse(executed, @"Callback should not be executed in this cycle");
    wait(!executed, 1);
    STAssertTrue(executed, @"Rejected dallback not executed");
    STAssertFalse(resolvedExecuted, @"Resolved callback was executed");
    STAssertEquals(executeCount, 1, @"Callback not executed exactly once");
    STAssertEqualObjects(reason, @13, @"Reject reason doesn't match");
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
    STAssertEqualObjects(callbacksOrder, (@[@1,@2,@3]), @"Resolve callbacks not called in order");
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
    STAssertEqualObjects(callbacksOrder, (@[@1,@2,@3]), @"Resolve callbacks not called in order");
}

//7. then must return a promise [3.3]
- (void)test_then_returnsAnotherPromise{
    CKPromise *promise2 = promise.then(nil, nil);
    STAssertTrue([promise2 isKindOfClass:[CKPromise class]], @"Expected a promise to be returned");
    STAssertFalse(promise2==promise, @"Expected a different promise");
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
    STAssertEqualObjects(value, @19, @"Incorrect promise2 value");
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
    STAssertEqualObjects(value, @29, @"Incorrect promise2 value");

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
    STAssertEquals(reason, ex, @"Incorrect promise2 reason");
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
    STAssertEquals(reason, ex, @"Incorrect promise2 reason");
    
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
    STAssertEqualObjects(value, @18, @"Incorrect promise2 value");
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
    STAssertEqualObjects(reason, @18, @"Incorrect promise2 value");
}

// #The Promise Resolution Procedure

//The promise resolution procedure is an abstract operation taking as input a promise and a value, which we denote as [[Resolve]](promise, x). If x is a thenable, it attempts to make promise adopt the state of x, under the assumption that x behaves at least somewhat like a promise. Otherwise, it fulfills promise with the value x.
//
//This treatment of thenables allows promise implementations to interoperate, as long as they expose a Promises/A+-compliant then method. It also allows Promises/A+ implementations to "assimilate" nonconformant implementations with reasonable then methods.
//
//To run [[Resolve]](promise, x), perform the following steps:

//1. If promise and x refer to the same object, reject promise with a TypeError as the reason.
- (void)test_resolve_samePromise_raiseException{
    STAssertThrowsSpecific([promise resolve:promise], CKTypeErrorException, @"Should raise TypeError exception");
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
    STAssertFalse(handlerExecuted, @"Should be in pending");
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
    STAssertTrue(handlerExecuted, @"Should be in resolved");
    STAssertEqualObjects(value, @"x", @"Should have been resolved with same value");
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
    STAssertEqualObjects(reason, @"y", @"Should have been rejected with same reason");
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
    STAssertEqualObjects(value, @"z", @"Should have been resolved with the provided value");
}

// If a promise is resolved with a thenable that participates in a circular thenable chain, such that the recursive nature of [[Resolve]](promise, thenable) eventually causes [[Resolve]](promise, thenable) to be called again, following the above algorithm will lead to infinite recursion. Implementations are encouraged, but not required, to detect such recursion and reject promise with an informative TypeError as the reason. [3.6]

- (void)test_chained_onePromiseFails{
    NSMutableArray *callbacksOrder = [NSMutableArray arrayWithCapacity:3];
    promise.done(^id(id value){
        [callbacksOrder addObject:@1];
        return [CKPromise resolved:@1];
    }).done(^id(id value){
        [callbacksOrder addObject:@2];
        return [CKPromise rejected:@2];
    }).done(^id(id value){
        [callbacksOrder addObject:@3];
        return [CKPromise resolved:@3];
    }).fail(^id(id reason){
        [callbacksOrder addObject:@4];
        return nil;
    });
    [promise resolve:@0];
    wait(callbacksOrder.count < 3, 0.1);
    STAssertEqualObjects(callbacksOrder, (@[@1,@2,@4]), @"Not the expected callbacks");
}

- (void)test_aggregate_waitsForAllPromises{
    CKPromise *promise1 = [CKPromise promise];
    CKPromise *promise2 = [CKPromise promise];
    CKPromise *promise3 = [CKPromise promise];
    promise = [CKPromise when:@[promise1, promise2, promise3]];
    [promise1 resolve:nil];
    [promise2 resolve:nil];
    __block BOOL handlerExecuted = NO;;
    promise.then(^{
        handlerExecuted = YES;
    }, ^{
        handlerExecuted = YES;
    });
    wait(!handlerExecuted, 0.02);
    STAssertFalse(handlerExecuted, @"Should be in pending until all promises have a resolution");
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
    STAssertTrue(handlerExecuted, @"Should be resolved if all promises have are resolved");
}

- (void)test_aggregate_rejectsIfOnePromiseFails{
    CKPromise *promise1 = [CKPromise promise];
    CKPromise *promise2 = [CKPromise promise];
    promise = [CKPromise when:@[promise1, promise2]];
    [promise1 reject:nil];
    [promise2 resolve:nil];
    __block BOOL handlerExecuted = NO;;
    promise.then(nil, ^{
        handlerExecuted = YES;
    });
    wait(!handlerExecuted, 0.02);
    STAssertTrue(handlerExecuted, @"Should be resolved if all promises have are resolved");
}

- (void)test_OnResolveReject_returnsSamePromise{
    STAssertEquals(promise.on(nil, nil), promise, @"Expected same promise");
}

@end
