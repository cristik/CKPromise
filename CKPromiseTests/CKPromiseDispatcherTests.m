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

@interface CKPromiseDispatcherTests : CKPromiseTestsBase
@end

@implementation CKPromiseDispatcherTests

- (void)test_defaultPromiseExecutesResolveOnMainQueue {
    __block dispatch_queue_t queue = nil;
    [promise success:^{
        queue = dispatch_get_current_queue();
    }];
    [promise resolve:@17];
    wait(!queue, 0.02);
    XCTAssertEqual(queue, dispatch_get_main_queue());
}

- (void)test_defaultPromiseExecutesRejectOnMainQueue {
    __block dispatch_queue_t queue = nil;
    [promise then:nil :^{
        queue = dispatch_get_current_queue();
    }];
    [promise reject:@2];
    wait(!queue, 0.02);
    XCTAssertEqual(queue, dispatch_get_main_queue());
}

- (void)test_resolvedPromiseRunsResolveCallbackOnTheSpecifiedQueue {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    promise.queuedThen(queue, ^{
        callbackQueue = dispatch_get_current_queue();
    }, nil);
    [promise resolve:@12];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_rejectedPromiseRunsRejectCallbackOnTheSpecifiedQueue {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    [promise queuedThen:queue :nil :^{
        callbackQueue = dispatch_get_current_queue();
    }];
    [promise reject:@123];
    wait(!callbackQueue, 0.02);
    XCTAssertEqual(callbackQueue, queue);
}

- (void)test_resolvingPromiseRunsResolveCallbackOnTheSpecifiedQueue {
    dispatch_queue_t queue = dispatch_queue_create(sel_getName(_cmd), NULL);
    __block dispatch_queue_t callbackQueue = NULL;
    [promise queuedThen:queue :^{
        callbackQueue = dispatch_get_current_queue();
    } :nil];
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

- (void)test_addingCallbacksFromMultipleQueuesWorksAsExpected {
    __block int counter = 0;\
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for(int i=0;i<10000;i++) {
            promise.then(^{
                counter++;
            }, nil);
        }
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [promise resolve:@1];
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for(int i=0;i<10000;i++) {
            promise.then(^{
                counter++;
            }, nil);
        }
    });
    wait(counter < 20000, 0.5);
    XCTAssertEqual(counter, 20000);
}

@end
