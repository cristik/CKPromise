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

@interface CKPromiseCallbacksTests : CKPromiseTestsBase
@end

@implementation CKPromiseCallbacksTests

// then variants equivalence
- (void)test_thenMethodWhenPromiseSucceedsExecutesOnlyTheSuccessCallback {
    __block BOOL successCalled = NO;
    __block BOOL failureCalled = NO;
    [promise then:^{
        successCalled = YES;
    } :^{
        failureCalled = YES;
    }];
    [promise resolve:@19];
    wait(!successCalled, 0.02);
    XCTAssertTrue(successCalled);
    XCTAssertFalse(failureCalled);
}

- (void)test_thenMethodWhenPromiseFailsExecutesOnlyTheFailureCallback {
    __block BOOL successCalled = NO;
    __block BOOL failureCalled = NO;
    [promise then:^{
        successCalled = YES;
    } :^{
        failureCalled = YES;
    }];
    [promise reject:@291];
    wait(!failureCalled, 0.02);
    XCTAssertFalse(successCalled);
    XCTAssertTrue(failureCalled);
}

- (void)test_thenMethodWhenPromiseFailsExecutesAlsoTheAnyCallback {
    __block BOOL anyCalled = NO;
    [promise always:^{
        anyCalled = YES;
    }];
    [promise reject:@129];
    wait(!anyCalled, 0.02);
    XCTAssertTrue(anyCalled);
}

- (void)test_thenMethodWhenPromiseSucceedsExecutesAlsoTheAnyCallback {
    __block BOOL anyCalled = NO;
    [promise always:^{
        anyCalled = YES;
    }];
    [promise resolve:@119];
    wait(!anyCalled, 0.02);
    XCTAssertTrue(anyCalled);
}

// Callback types
- (void)test_acceptsResolveHandlerVoidVoid{
    __block BOOL handlerExecuted = NO;
    promise.success(^{
        handlerExecuted = YES;
    });
    [promise resolve:nil];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_acceptsResolveHandlerVoidId{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.success(^(id val){
        handlerExecuted = YES;
        resolveValue = val;
    });
    [promise resolve:@15];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @15, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerVoidBOOL{
    __block BOOL handlerExecuted = NO;
    __block BOOL resolveValue = NO;
    promise.success(^(BOOL val){
        handlerExecuted = YES;
        resolveValue = val;
    });
    [promise resolve:@15];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertTrue(resolveValue, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerVoidClass{
    __block BOOL handlerExecuted = NO;
    __block Class resolveValue = NO;
    promise.success(^(Class val){
        handlerExecuted = YES;
        resolveValue = val;
    });
    [promise resolve:XCTestCase.class];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, XCTestCase.class, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerVoidNSNumber{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.success(^(NSNumber *val){
        handlerExecuted = YES;
        resolveValue = val;
    });
    [promise resolve:@15];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @15, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerIdVoid{
    __block BOOL handlerExecuted = NO;
    promise.success(^id{
        handlerExecuted = YES;
        return nil;
    });
    [promise resolve:nil];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_acceptsResolveHandlerNSStringVoid{
    __block BOOL handlerExecuted = NO;
    __block id value = nil;
    CKPromise *promise2 = promise.success(^NSString*{
        return @"abc";
    });
    promise2.then(^(id val){
        value = val;
        handlerExecuted = YES;
    }, nil);
    [promise resolve:nil];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(value, @"abc", @"Incorrect resolve value for promise2");
}

- (void)test_acceptsResolveHandlerIdId{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.success(^id(id val){
        handlerExecuted = YES;
        resolveValue = val;
        return nil;
    });
    [promise resolve:@16];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @16, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerIdBOOL{
    __block BOOL handlerExecuted = NO;
    __block BOOL resolveValue = NO;
    promise.success(^id(BOOL val){
        handlerExecuted = YES;
        resolveValue = val;
        return nil;
    });
    [promise resolve:@16];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertTrue(resolveValue, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerIdClass{
    __block BOOL handlerExecuted = NO;
    __block Class resolveValue = NO;
    promise.success(^id(Class val){
        handlerExecuted = YES;
        resolveValue = val;
        return nil;
    });
    [promise resolve:NSString.class];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, NSString.class, @"Incorrect resolve value");
}

- (void)test_acceptsRejectHandlerNSRectId{
    XCTAssertThrows(promise.then(^NSRect(NSObject* val){
        return NSZeroRect;
    }, ^NSRect(NSFileManager *val){
        return NSZeroRect;
    }), @"Expected exception");
}

- (void)test_acceptsRejectHandlerVoidVoid{
    __block BOOL handlerExecuted = NO;
    promise.failure(^{
        handlerExecuted = YES;
    });
    [promise reject:nil];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_acceptsRejectHandlerVoidId{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.failure(^(id val){
        handlerExecuted = YES;
        resolveValue = val;
    });
    [promise reject:@17];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @17, @"Incorrect resolve value");
}

- (void)test_acceptsRejectHandlerIdVoid{
    __block BOOL handlerExecuted = NO;
    promise.failure(^id{
        handlerExecuted = YES;
        return nil;
    });
    [promise reject:nil];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_acceptsRejectHandlerIdId{
    __block BOOL handlerExecuted = NO;
    __block id resolveValue = nil;
    promise.failure(^id(id val){
        handlerExecuted = YES;
        resolveValue = val;
        return nil;
    });
    [promise reject:@18];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @18, @"Incorrect resolve value");
}

- (void)test_acceptsRejectHandlerNSRectChar{
    XCTAssertThrows(promise.then(^NSRect(char val){
        return NSZeroRect;
    }, ^NSRect(char val){
        return NSZeroRect;
    }), @"Expected exception");
}

// scalar values
- (void)test_acceptsResolveHandlerVoidInt{
    __block int value = 0;
    promise.then(^(int val){
        value = val;
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, 27, @"Unexpected promise value");
}

- (void)test_acceptsRejectHandlerNSRectInt{
    XCTAssertThrows(promise.then(^NSRect(int val){
        return NSZeroRect;
    }, ^NSRect(int val){
        return NSZeroRect;
    }), @"Expected exception");
}

- (void)test_acceptsResolveHandlerVoidChar{
    __block char value = 0;
    promise.then(^(char val){
        value = val;
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (char)27, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerIdChar{
    __block char value = 0;
    promise.then(^id(char val){
        value = val;
        return @"aa";
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (char)27, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerVoidShort{
    __block short value = 0;
    promise.then(^(short val){
        value = val;
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (short)27, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerIdShort{
    __block short value = 0;
    promise.then(^id(short val){
        value = val;
        return @"aa";
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (short)27, @"Unexpected promise value");
}

- (void)test_acceptsRejectHandlerNSRectShort{
    XCTAssertThrows(promise.then(^NSRect(short val){
        return NSZeroRect;
    }, ^NSRect(short val){
        return NSZeroRect;
    }), @"Expected exception");
}

- (void)test_acceptsResolveHandlerVoidLong{
    __block long value = 0;
    promise.then(^(long val){
        value = val;
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (long)27, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerIdLong{
    __block long value = 0;
    promise.then(^id(long val){
        value = val;
        return @"aa";
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (long)27, @"Unexpected promise value");
}

- (void)test_acceptsRejectHandlerNSRectLong{
    XCTAssertThrows(promise.then(^NSRect(long val){
        return NSZeroRect;
    }, ^NSRect(long val){
        return NSZeroRect;
    }), @"Expected exception");
}

- (void)test_acceptsResolveHandlerVoidLong1{
    __block long value = 0;
    promise.then(^(long val){
        value = val;
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (long)27, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerIdLong1{
    __block long value = 0;
    promise.then(^id(long val){
        value = val;
        return @"aa";
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (long)27, @"Unexpected promise value");
}

- (void)test_acceptsRejectHandlerNSRectLong1{
    XCTAssertThrows(promise.then(^NSRect(long val){
        return NSZeroRect;
    }, ^NSRect(long val){
        return NSZeroRect;
    }), @"Expected exception");
}

- (void)test_acceptsResolveHandlerVoidLongLong{
    __block long long value = 0;
    promise.then(^(long long val){
        value = val;
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (long long)27, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerIdLongLong{
    __block long long value = 0;
    promise.then(^id(long long val){
        value = val;
        return @"aa";
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (long long)27, @"Unexpected promise value");
}

- (void)test_acceptsRejectHandlerNSRectLongLong{
    XCTAssertThrows(promise.then(^NSRect(long long val){
        return NSZeroRect;
    }, ^NSRect(long long val){
        return NSZeroRect;
    }), @"Expected exception");
}

- (void)test_acceptsResolveHandlerVoidFloat{
    __block float value = 0;
    promise.then(^(float val){
        value = val;
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (float)27, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerIdFloat{
    __block float value = 0;
    promise.then(^id(float val){
        value = val;
        return @"aa";
    }, nil);
    [promise resolve:@27];
    wait(YES, 0.02);
    XCTAssertEqual(value, (float)27, @"Unexpected promise value");
}

- (void)test_acceptsRejectHandlerNSRectFloat{
    XCTAssertThrows(promise.then(^NSRect(float val){
        return NSZeroRect;
    }, ^NSRect(float val){
        return NSZeroRect;
    }), @"Expected exception");
}


- (void)test_acceptsResolveHandlerVoidDouble{
    __block double value = 0;
    promise.then(^(double val){
        value = val;
    }, nil);
    [promise resolve:@28.98];
    wait(YES, 0.02);
    XCTAssertEqual(value, 28.98, @"Unexpected promise value");
}

- (void)test_acceptsResolveHandlerIdDouble{
    __block double value = 0;
    promise.then(^id(double val){
        value = val;
        return @132;
    }, nil);
    [promise resolve:@28.98];
    wait(YES, 0.02);
    XCTAssertEqual(value, 28.98, @"Unexpected promise value");
}

- (void)test_acceptsRejectHandlerNSRectDouble{
    XCTAssertThrows(promise.then(^NSRect(double val){
        return NSZeroRect;
    }, ^NSRect(double val){
        return NSZeroRect;
    }), @"Expected exception");
}

//invalid handler
- (void)test_acceptsResolveHandlerVoidNSRect{
    __block NSRect value = NSZeroRect;
    XCTAssertThrows(
                   promise.then(^(NSRect val){
        value = val;
        return 8.1;
    }, nil), @"Expected exception");
}

- (void)test_always_executes_ifResolved{
    __block BOOL handlerExecuted = NO;
    promise.always(^(){
        handlerExecuted = YES;
    });
    [promise resolve:@18];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_always_executes_ifRejected{
    __block BOOL handlerExecuted = NO;
    promise.always(^(){
        handlerExecuted = YES;
    });
    [promise reject:@18];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_ignores_nonBlock_handler{
    promise.then(@15, @16);
    [promise resolve:@17];
    wait(YES, 0.02);
}

- (void)test_acceptsOnlyIdForOtherArguments {
    XCTAssertThrowsSpecific((promise.then(^(int val1, int val2){
        
    }, nil)), CKInvalidHandlerException);
}

- (void)test_when_nil_returnedAsNSNull{
    CKPromise *promise1 = [CKPromise promise];
    CKPromise *promise2 = [CKPromise promise];
    CKPromise *promise3 = [CKPromise promise];
    promise = [CKPromise when:@[promise1, promise2, promise3]];
    __block BOOL succeeded = NO;
    __block BOOL failed = NO;
    __block id value;
    promise.then(^(id val){
        value = val;
        succeeded = YES;
    }, ^{
        failed = YES;
    });
    [promise1 resolve:@"promise1"];
    [promise2 resolve:nil];
    [promise3 resolve:@"promise3"];
    wait(!succeeded || !failed, 0.02);
    XCTAssertTrue(succeeded);
    XCTAssertFalse(failed);
    XCTAssertEqualObjects(value, (@[@"promise1", [NSNull null], @"promise3"]));
}

- (void)test_when_emptyArrayReturnsAResolvedPromise {
    promise = [CKPromise when: @[]];
    __block BOOL succeeded = NO;
    promise.success(^{
        succeeded = YES;
    });
    wait(!succeeded, 0.02);
    XCTAssertTrue(succeeded);
}

- (void)test_when_nilArrayReturnsAResolvedPromise {
    promise = [CKPromise when: nil];
    __block BOOL succeeded = NO;
    promise.success(^{
        succeeded = YES;
    });
    wait(!succeeded, 0.02);
    XCTAssertTrue(succeeded);
}

@end
