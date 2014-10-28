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

@interface CKPromiseCallbacksTests : SenTestCase
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

@end
