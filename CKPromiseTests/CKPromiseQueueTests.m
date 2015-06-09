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

#import "CKPromise.h"

@interface CKPromiseQueueTests : XCTestCase {
    CKPromise *promise;
}
@end

@implementation CKPromiseQueueTests

- (void)setUp {
    [super setUp];
    promise = [CKPromise promise];
}

- (void)test_resolvedPromiseRunsResolveCallbackOnTheSpecifiedQueue {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    promise = [CKPromise resolved:@12];
    [promise queuedThen:queue :^{
        callbackQueue = dispatch_get_current_queue();
    }];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_resolvedPromiseRunsResolveCallbackOnTheSpecifiedQueue_2nd {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    promise = [CKPromise resolved:@12];
    [promise queuedThen:queue :^{
        callbackQueue = dispatch_get_current_queue();
    } :nil];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_resolvedPromiseRunsResolveCallbackOnTheSpecifiedQueue_3nd {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    promise = [CKPromise resolved:@12];
    [promise queuedThen:queue :^{
        callbackQueue = dispatch_get_current_queue();
    } :nil :nil];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_resolvedPromiseRunsAnyCallbackOnTheSpecifiedQueue {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    promise = [CKPromise resolved:@12];
    [promise queuedThen:queue :nil :nil :^{
        callbackQueue = dispatch_get_current_queue();
    }];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_rejectedPromiseRunsRejectCallbackOnTheSpecifiedQueue {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    promise = [CKPromise rejected:@123];
    [promise queuedThen:queue :nil :^{
        callbackQueue = dispatch_get_current_queue();
    }];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_resolvingPromiseRunsResolveCallbackOnTheSpecifiedQueue {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    [promise queuedThen:queue :^{
        callbackQueue = dispatch_get_current_queue();
    }];
    [promise resolve:@1234];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_rejectingPromiseRunsRejectCallbackOnTheSpecifiedQueue {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    [promise queuedThen:queue :nil :^{
        callbackQueue = dispatch_get_current_queue();
    }];
    [promise reject:@12345];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_rejectingPromiseRunsRejectCallbackOnTheSpecifiedQueue_3rd {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    [promise queuedThen:queue :nil :^{
        callbackQueue = dispatch_get_current_queue();
    } :nil];
    [promise reject:@12345];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

@end
