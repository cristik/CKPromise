// Copyright (c) 2014, Cristian Kocza
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

@interface CKPromiseCallbacksTests : XCTestCase
@end

@implementation CKPromiseCallbacksTests{
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
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
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
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @15, @"Incorrect resolve value");
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
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @15, @"Incorrect resolve value");
}

- (void)test_acceptsResolveHandlerIdVoid{
    __block BOOL handlerExecuted = NO;
    promise.done(^id{
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
    CKPromise *promise2 = promise.done(^NSString*{
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
    promise.done(^id(id val){
        handlerExecuted = YES;
        resolveValue = val;
        return nil;
    });
    [promise resolve:@16];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @16, @"Incorrect resolve value");
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
    promise.fail(^{
        handlerExecuted = YES;
    });
    [promise reject:nil];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
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
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
    XCTAssertEqualObjects(resolveValue, @17, @"Incorrect resolve value");
}

- (void)test_acceptsRejectHandlerIdVoid{
    __block BOOL handlerExecuted = NO;
    promise.fail(^id{
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
    promise.fail(^id(id val){
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

- (void)test_always_executes_resolveHandler{
    __block BOOL handlerExecuted = NO;
    promise.always(^(){
        handlerExecuted = YES;
    });
    [promise resolve:@18];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted, @"Completion handler was not executed");
}

- (void)test_always_executes_rejectHandler{
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

- (void)test_allowsCallbacksWith2Arguments{
    promise.then(^(id val1, id val2){
        
    }, ^(int val3, NSNumber *val4){
        
    });
    [promise resolve:@18];
    wait(YES, 0.02);
}

- (void)test_allowsCallbacksWith3Arguments{
    promise.then(^(char val1, id val2, id val3){
        
    }, ^(short val4, NSNumber *val5, NSString *val6){
        
    });
    [promise resolve:@18];
    wait(YES, 0.02);
}

- (void)test_allowsCallbacksWith4Arguments{
    promise.then(^(float val1, id val2, id val3, id val4){
        
    }, ^(double val5, NSNumber *val6, NSString *val7, NSURL *val8){
        
    });
    [promise resolve:@18];
    wait(YES, 0.02);
}

- (void)test_allowsCallbacksWith5Arguments{
    promise.then(^(long long val1, id val2, id val3, id val4, id val5){
        
    }, ^(NSError *val6, NSNumber *val7, NSString *val8, NSURL *val9, NSArray *val10){
        
    });
    [promise resolve:@18];
    wait(YES, 0.02);
}

- (void)test_resolve_2values{
    __block BOOL handlerExecuted = NO;
    __block int value1 = 0;
    __block id value2 = nil;
    promise.done(^(int val1, id val2){
        value1 = val1;
        value2 = val2;
        handlerExecuted = YES;
    });
    [promise resolve2:@19, @20, nil];
    wait(!handlerExecuted, 0.02);
    XCTAssertTrue(handlerExecuted);
    XCTAssertEqual(value1, 19);
    XCTAssertEqualObjects(value2, @20);
}

- (void)test_acceptsOnlyIdForOtherArguments{
    XCTAssertThrowsSpecific((promise.then(^(int val1, int val2){
        
    }, nil)), CKInvalidHandlerException);
}

- (void)test_when_multipleValues_returnedAsArray{
    CKPromise *promise1 = [CKPromise promise];
    CKPromise *promise2 = [CKPromise promise];
    CKPromise *promise3 = [CKPromise promise];
    promise = [CKPromise when:@[promise1, promise2, promise3]];
    __block BOOL succeeded = NO;
    __block BOOL failed = NO;
    __block id value1 = nil, value2 = nil, value3 = nil;
    promise.then(^(id val1, id val2, id val3){
        value1 = val1;
        value2 = val2;
        value3 = val3;
        succeeded = YES;
    }, ^{
        failed = YES;
    });
    [promise1 resolve:@"promise1"];
    [promise2 resolve2:@"promise2.1", @"promise2.2", @"promise2.3", nil];
    [promise3 resolve:@"promise3"];
    wait(!succeeded || !failed, 0.02);
    XCTAssertTrue(succeeded);
    XCTAssertFalse(failed);
    XCTAssertEqualObjects(value1, @"promise1");
    XCTAssertEqualObjects(value2, (@[@"promise2.1", @"promise2.2", @"promise2.3"]));
    XCTAssertEqualObjects(value3, @"promise3");
}

- (void)test_when_nil_returnedAsNil{
    CKPromise *promise1 = [CKPromise promise];
    CKPromise *promise2 = [CKPromise promise];
    CKPromise *promise3 = [CKPromise promise];
    promise = [CKPromise when:@[promise1, promise2, promise3]];
    __block BOOL succeeded = NO;
    __block BOOL failed = NO;
    __block id value1 = nil, value2 = nil, value3 = nil;
    promise.then(^(id val1, id val2, id val3){
        value1 = val1;
        value2 = val2;
        value3 = val3;
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
    XCTAssertEqualObjects(value1, @"promise1");
    XCTAssertEqualObjects(value2, nil);
    XCTAssertEqualObjects(value3, @"promise3");
}

@end
