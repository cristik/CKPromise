// Copyright (c) 2014-2017, Cristian Kocza
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

import XCTest

extension CKPromiseState {
    var isPending: Bool {
        if case .pending = self { return true } else { return false }
    }
    
    var isSuccess: Bool {
        if case .success = self { return true } else { return false }
    }
    
    var isFailure: Bool {
        if case .failure = self { return true } else { return false }
    }
    
    var value: T? {
        if case let .success(value) = self { return value } else { return nil }
    }
    
    var reason: Error? {
        if case let .failure(reason) = self { return reason } else { return nil }
    }
}

extension CKPromiseResult {
    var value: T? {
        if case let .success(value) = self { return value } else { return nil }
    }
    
    var error: Error? {
        if case let .failure(error) = self { return error } else { return nil }
    }
}

extension Either {
    var left: A? {
        switch self {
        case let .left(a): return a
        case .right: return nil
        }
    }
    
    var right: B? {
        switch self {
        case .left: return nil
        case let .right(b): return b
        }
    }
}

enum TestError: Error {
    case error1
    case error2
    case error3
    case error4
    case error5
    case error6
    case error7
    case error8
    case error9
}

class CKPromiseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
//    Promise States
//    A promise must be in one of three states: pending, fulfilled, or rejected.
    func test_init_pending() {
        let promise = CKPromise<Int>()
        XCTAssertTrue(promise.state.isPending)
    }
//    
//    When pending, a promise:
//    may transition to either the fulfilled or rejected state.
    func test_resolve_movesToSuccess() {
        let promise = CKPromise<Int>()
        promise.resolve(1)
        XCTAssertTrue(promise.state.isSuccess)
        XCTAssertEqual(1, promise.state.value)
    }
    
    func test_reject_movesToFailure() {
        let promise = CKPromise<Int>()
        promise.reject(TestError.error1)
        XCTAssertTrue(promise.state.isFailure)
        XCTAssertNotNil(promise.state.reason as? TestError)
        XCTAssertEqual(TestError.error1, promise.state.reason as? TestError)
    }
    
//    When fulfilled, a promise:
//    must not transition to any other state.
    func test_reject_doesntRejectAResolvedPromise() {
        let promise = CKPromise<Int>()
        promise.resolve(1)
        promise.reject(TestError.error1)
        XCTAssertTrue(promise.state.isSuccess)
    }
//    must have a value, which must not change.
    func test_resolve_doesntChangeValueOfAResolvedPromise() {
        let promise = CKPromise<NSString>()
        let value = "abc" as NSString
        promise.resolve(value)
        promise.resolve("bcd" as NSString)
        XCTAssertTrue(value === promise.state.value)
    }
//    When rejected, a promise:
//    must not transition to any other state.
    func test_resolve_doesntResolveARejectedPromise() {
        let promise = CKPromise<Int>()
        promise.reject(TestError.error1)
        promise.resolve(1)
        XCTAssertTrue(promise.state.isFailure)
    }
//    must have a reason, which must not change.
    func test_reject_doesntChangeReasonIfRejectingTwice() {
        let promise = CKPromise<Int>()
        let reason = NSError(domain: "TestErrorDomain", code: -1, userInfo: nil)
        promise.reject(reason)
        promise.reject(TestError.error1)
        XCTAssertTrue((promise.state.reason ?? TestError.error1) as NSError === reason)
    }
//    Here, “must not change” means immutable identity (i.e. ===), but does not imply deep immutability.

//    The then Method
//    A promise must provide a then method to access its current or eventual value or reason.
//    
//    A promise’s then method accepts two arguments:
//    
//    promise.then(onFulfilled, onRejected)
//    Both onFulfilled and onRejected are optional arguments:
//    If onFulfilled is not a function, it must be ignored.
//    If onRejected is not a function, it must be ignored.
    
//    If onFulfilled is a function:
//    it must be called after promise is fulfilled, with promise’s value as its first argument.
//    it must not be called before promise is fulfilled.
//    it must not be called more than once.
    func test_onSuccessFailure_whenScheduledBeforeResolve() {
        let promise = CKPromise<Int>()
        var value: Int?
        var callCount = 0
        var failureCalled = false
        promise.on(success: { _ in }, failure: { _ in })
        promise.on(success: { val in value = val; callCount+=1 }, failure: { _ in failureCalled = true })
        XCTAssertEqual(0, callCount)
        promise.resolve(15)
        XCTAssertNil(value)
        XCTAssertEqualEventually(value, 15)
        XCTAssertEqual(1, callCount)
        XCTAssertFalse(failureCalled)
    }
    
    func test_onSuccessFailure_whenScheduledAfterResolve() {
        let promise = CKPromise<Int>()
        var value: Int?
        var callCount = 0
        var failureCalled = false
        promise.resolve(15)
        promise.on(success: { val in value = val; callCount+=1 },
                   failure: { _ in failureCalled = true })
        promise.on(success: { _ in }, failure: { _ in })
        XCTAssertNil(value)
        XCTAssertEqualEventually(value, 15)
        XCTAssertEqual(1, callCount)
        XCTAssertFalse(failureCalled)
    }
    
    func test_onSuccess_whenScheduledBeforeResolve() {
        let promise = CKPromise<Int>()
        var value: Int?
        var callCount = 0
        promise.on(success: { _ in })
        promise.on(success: { val in value = val; callCount+=1 })
        XCTAssertEqual(0, callCount)
        promise.resolve(15)
        XCTAssertNil(value)
        XCTAssertEqualEventually(value, 15)
        XCTAssertEqual(1, callCount)
    }
    
    func test_onSuccess_whenScheduledAfterResolve() {
        let promise = CKPromise<Int>()
        var value: Int?
        var callCount = 0
        promise.resolve(15)
        promise.on(success: { val in value = val; callCount+=1 })
        promise.on(success: { _ in })
        XCTAssertNil(value)
        XCTAssertEqualEventually(value, 15)
        XCTAssertEqual(1, callCount)
    }
    
    func test_onCompletion_whenScheduledBeforeResolve() {
        let promise = CKPromise<Int>()
        var result: CKPromiseResult<Int>?
        var callCount = 0
        promise.on(completion: { _ in })
        promise.on(completion: { res in result = res; callCount+=1 })
        XCTAssertEqual(0, callCount)
        promise.resolve(15)
        XCTAssertNil(result)
        XCTAssertEqualEventually(result?.value, 15)
        XCTAssertEqual(1, callCount)
    }
    
    func test_onCompletion_whenScheduledAfterResolve() {
        let promise = CKPromise<Int>()
        var result: CKPromiseResult<Int>?
        var callCount = 0
        promise.resolve(15)
        promise.on(completion: { res in result = res; callCount+=1 })
        promise.on(completion: { _ in })
        XCTAssertNil(result)
        XCTAssertEqualEventually(result?.value, 15)
        XCTAssertEqual(1, callCount)
    }
    
//    If onRejected is a function,
//    it must be called after promise is rejected, with promise’s reason as its first argument.
//    it must not be called before promise is rejected.
//    it must not be called more than once.
    func test_onSuccessFailure_whenScheduledBeforeReject() {
        let promise = CKPromise<Int>()
        var reason: Error?
        var callCount = 0
        var successCalled = false
        promise.on(success: { _ in }, failure: { _ in })
        promise.on(success: { _ in successCalled = true }, failure: { reason = $0; callCount += 1})
        XCTAssertEqual(0, callCount)
        promise.reject(TestError.error1)
        XCTAssertNil(reason)
        XCTAssertEqualEventually(TestError.error1, reason as? TestError)
        XCTAssertEqual(1, callCount)
        XCTAssertFalse(successCalled)
    }
    
    func test_onSuccessFailure_whenScheduledAfterReject() {
        let promise = CKPromise<Int>()
        var reason: Error?
        var callCount = 0
        var successCalled = false
        promise.reject(TestError.error2)
        promise.on(success: { _ in successCalled = true }, failure: { reason = $0; callCount += 1})
        promise.on(success: { _ in }, failure: { _ in })
        XCTAssertNil(reason)
        XCTAssertEqualEventually(TestError.error2, reason as? TestError)
        XCTAssertEqual(1, callCount)
        XCTAssertFalse(successCalled)
    }
    
    func test_onSuccess_whenScheduledBeforeReject() {
        let promise = CKPromise<Int>()
        var reason: Error?
        var callCount = 0
        promise.on(success: { _ in })
        promise.on(failure: { reason = $0; callCount += 1 })
        XCTAssertEqual(0, callCount)
        promise.reject(TestError.error3)
        XCTAssertNil(reason)
        XCTAssertEqualEventually(TestError.error3, reason as? TestError)
        XCTAssertEqual(1, callCount)
    }
    
    func test_onSuccess_whenScheduledAfterReject() {
        let promise = CKPromise<Int>()
        var reason: Error?
        var callCount = 0
        promise.reject(TestError.error4)
        promise.on(failure: { reason = $0; callCount += 1 })
        promise.on(success: { _ in })
        XCTAssertNil(reason)
        XCTAssertEqualEventually(TestError.error4, reason as? TestError)
        XCTAssertEqual(1, callCount)
    }
    
    func test_onCompletion_whenScheduledBeforeReject() {
        let promise = CKPromise<Int>()
        var result: CKPromiseResult<Int>?
        var callCount = 0
        promise.on(completion: { _ in })
        promise.on(completion: { result = $0; callCount += 1})
        XCTAssertEqual(0, callCount)
        promise.reject(TestError.error5)
        XCTAssertNil(result)
        XCTAssertEqualEventually(TestError.error5, result?.error as? TestError)
        XCTAssertEqual(1, callCount)
    }
    
    func test_onCompletion_whenScheduledAfterReject() {
        let promise = CKPromise<Int>()
        var result: CKPromiseResult<Int>?
        var callCount = 0
        promise.reject(TestError.error6)
        promise.on(completion: { result = $0; callCount += 1})
        promise.on(completion: { _ in })
        XCTAssertNil(result)
        XCTAssertEqualEventually(TestError.error6, result?.error as? TestError)
        XCTAssertEqual(1, callCount)
    }
    
//    onFulfilled or onRejected must not be called until the execution context stack contains only platform code. [3.1].
    func test_onSuccessFailure_executesAfterOnMainThreadWhenResolvedBeforeScheduling() {
        let promise = CKPromise<Int>()
        var executedOnMainThread: Bool?
        promise.resolve(20)
        promise.on(success: { _ in executedOnMainThread = Thread.isMainThread },
            failure: { _ in })
        XCTAssertNil(executedOnMainThread)
        XCTAssertTrueEventually(executedOnMainThread ?? false)
    }
    
    func test_onSuccessFailure_executesAfterOnMainThreadWhenResolvedAfterScheduling() {
        let promise = CKPromise<Int>()
        var executedOnMainThread: Bool?
        promise.on(success: { _ in executedOnMainThread = Thread.isMainThread },
                   failure: { _ in })
        promise.resolve(20)
        XCTAssertNil(executedOnMainThread)
        XCTAssertTrueEventually(executedOnMainThread ?? false)
    }
    
    func test_onSuccessFailure_executesAfterOnMainThreadWhenRejectedBeforeScheduling() {
        let promise = CKPromise<Int>()
        var executedOnMainThread: Bool?
        promise.resolve(20)
        promise.on(success: { _ in executedOnMainThread = Thread.isMainThread },
                   failure: { _ in })
        XCTAssertNil(executedOnMainThread)
        XCTAssertTrueEventually(executedOnMainThread ?? false)
    }
    
    func test_onSuccessFailure_executesAfterOnMainThreadWhenRejectedAfterScheduling() {
        let promise = CKPromise<Int>()
        var executedOnMainThread: Bool?
        promise.on(success: { _ in executedOnMainThread = Thread.isMainThread },
                   failure: { _ in })
        promise.resolve(20)
        XCTAssertNil(executedOnMainThread)
        XCTAssertTrueEventually(executedOnMainThread ?? false)
    }
    
//    onFulfilled and onRejected must be called as functions (i.e. with no this value). [3.2]
//    then may be called multiple times on the same promise.
//    If/when promise is fulfilled, all respective onFulfilled callbacks must execute in the order of their originating calls to then.
    func test_successCallbacksCalledInTheCorrectOrder() {
        let promise = CKPromise<String>()
        var callbacks: [Int] = []
        promise.on(success: { _ in callbacks.append(1) })
        promise.on(success: { _ in callbacks.append(2) })
        promise.resolve("abc")
        promise.on(success: { _ in callbacks.append(3) })
        promise.on(success: { _ in callbacks.append(4) })
        XCTAssertEqualEventually(4, callbacks.count)
        XCTAssertEqual([1,2,3,4], callbacks)
    }
    
//    If/when promise is rejected, all respective onRejected callbacks must execute in the order of their originating calls to then.
    
    func test_failureCallbacksCalledInTheCorrectOrder() {
        let promise = CKPromise<String>()
        var callbacks: [Int] = []
        promise.on(failure: { _ in callbacks.append(1) })
        promise.on(failure: { _ in callbacks.append(2) })
        promise.reject(TestError.error1)
        promise.on(failure: { _ in callbacks.append(3) })
        promise.on(failure: { _ in callbacks.append(4) })
        XCTAssertEqualEventually(4, callbacks.count)
        XCTAssertEqual([1,2,3,4], callbacks)
    }
    
//    then must return a promise [3.3].
//    promise2 = promise1.then(onFulfilled, onRejected);
//    If either onFulfilled or onRejected returns a value x, run the Promise Resolution Procedure [[Resolve]](promise2, x).
    func test_resolve_onSuccessFailure_ResolvesOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(success: { _ in return "a"}, failure: { _ in return "b"})
        promise.resolve(2)
        XCTAssertEqualEventually("a", promise2.state.value)
    }
    
    func test_resolve_onSuccess_ResolvesOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(success: { _ in return "c"})
        promise.resolve(2)
        XCTAssertEqualEventually("c", promise2.state.value)
    }
    
    func test_resolve_onCompletion_ResolvesOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(completion: { _ in return "d"})
        promise.resolve(2)
        XCTAssertEqualEventually("d", promise2.state.value)
    }
    
    func test_reject_onSuccessFailure_ResolvesOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(success: { _ in return "e"}, failure: { _ in return "f"})
        promise.reject(TestError.error1)
        XCTAssertEqualEventually("f", promise2.state.value)
    }
    
    func test_reject_onFailure_ResolvesOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(failure: { _ in return "g"})
        promise.reject(TestError.error2)
        XCTAssertEqualEventually("g", promise2.state.value?.right)
    }
    
    func test_reject_onCompletion_ResolvesOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(failure: { _ in return "g"})
        promise.reject(TestError.error3)
        XCTAssertEqualEventually("h", promise2.state.value?.right)
    }
    
//    If either onFulfilled or onRejected throws an exception e, promise2 must be rejected with e as the reason.
    func test_resolve_onSuccessFailureThrows_RejectsOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(success: { _ in throw TestError.error4 }, failure: { _ in })
        promise.resolve(2)
        XCTAssertEqualEventually(TestError.error4, promise2.state.reason as? TestError)
    }
    
    func test_resolve_onSuccessThrows_RejectsOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(success: { _ in throw TestError.error5 })
        promise.resolve(2)
        XCTAssertEqualEventually(TestError.error5, promise2.state.reason as? TestError)
    }
    
    func test_resolve_onCompletionThrows_RejectsOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(completion: { _ in throw TestError.error6 })
        promise.resolve(2)
        XCTAssertEqualEventually(TestError.error6, promise2.state.reason as? TestError)
    }
    
    func test_reject_onSuccessFailureThrows_RejectsOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(success: { _ in return "e"}, failure: { _ in throw TestError.error7 })
        promise.reject(TestError.error1)
        XCTAssertEqualEventually(TestError.error7, promise2.state.reason as? TestError)
    }
    
    func test_reject_onFailureThrows_ResolvesOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(failure: { _ in throw TestError.error8})
        promise.reject(TestError.error2)
        XCTAssertEqualEventually(TestError.error8, promise2.state.reason as? TestError)
    }
    
    func test_reject_onCompletionThrows_ResolvesOtherPromise() {
        let promise = CKPromise<Int>()
        let promise2 = promise.on(completion: { _ in throw TestError.error9})
        promise.reject(TestError.error3)
        XCTAssertEqualEventually(TestError.error9, promise2.state.reason as? TestError)
    }
    
//    If onFulfilled is not a function and promise1 is fulfilled, promise2 must be fulfilled with the same value as promise1.

//    If onRejected is not a function and promise1 is rejected, promise2 must be rejected with the same reason as promise1.
    
//    The Promise Resolution Procedure
//    The promise resolution procedure is an abstract operation taking as input a promise and a value, which we denote as [[Resolve]](promise, x). If x is a thenable, it attempts to make promise adopt the state of x, under the assumption that x behaves at least somewhat like a promise. Otherwise, it fulfills promise with the value x.
//    
//    This treatment of thenables allows promise implementations to interoperate, as long as they expose a Promises/A+-compliant then method. It also allows Promises/A+ implementations to “assimilate” nonconformant implementations with reasonable then methods.
//    
//    To run [[Resolve]](promise, x), perform the following steps:
//    
//    If promise and x refer to the same object, reject promise with a TypeError as the reason.
//    If x is a promise, adopt its state [3.4]:
//    If x is pending, promise must remain pending until x is fulfilled or rejected.
//    If/when x is fulfilled, fulfill promise with the same value.
//    If/when x is rejected, reject promise with the same reason.
//    Otherwise, if x is an object or function,
//    Let then be x.then. [3.5]
//    If retrieving the property x.then results in a thrown exception e, reject promise with e as the reason.
//    If then is a function, call it with x as this, first argument resolvePromise, and second argument rejectPromise, where:
//    If/when resolvePromise is called with a value y, run [[Resolve]](promise, y).
//    If/when rejectPromise is called with a reason r, reject promise with r.
//    If both resolvePromise and rejectPromise are called, or multiple calls to the same argument are made, the first call takes precedence, and any further calls are ignored.
//    If calling then throws an exception e,
//    If resolvePromise or rejectPromise have been called, ignore it.
//    Otherwise, reject promise with e as the reason.
//    If then is not a function, fulfill promise with x.
//    If x is not an object or function, fulfill promise with x.
//    If a promise is resolved with a thenable that participates in a circular thenable chain, such that the recursive nature of [[Resolve]](promise, thenable) eventually causes [[Resolve]](promise, thenable) to be called again, following the above algorithm will lead to infinite recursion. Implementations are encouraged, but not required, to detect such recursion and reject promise with an informative TypeError as the reason.
}

func XCTAssertTrueEventually(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 0.1) {
    let start = Date()
    while(!condition() && Date().timeIntervalSince(start) < timeout) {
        CFRunLoopRunInMode(.defaultMode, 0.01, true)
    }
    XCTAssertTrue(condition())
}

func XCTAssertFalseEventually(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 0.1) {
    let start = Date()
    while(condition() && Date().timeIntervalSince(start) < timeout) {
        CFRunLoopRunInMode(.defaultMode, 0.01, true)
    }
    XCTAssertFalse(condition())
}

func XCTAssertEqualEventually<T: Equatable>(_ left: @autoclosure () -> T?, _ right: @autoclosure () -> T?, timeout: TimeInterval = 0.1) {
    let start = Date()
    while(left() != right() && Date().timeIntervalSince(start) < timeout) {
        CFRunLoopRunInMode(.defaultMode, 0.01, true)
    }
    XCTAssertEqual(left(), right())
}
