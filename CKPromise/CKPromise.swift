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

import Foundation

/**
 * A promise represents the eventual result of an asynchronous operation. The
 * primary way of interacting with a promise is through its "then" method,
 * which registers callbacks to receive either a promise’s eventual value or
 * the reason why the promise cannot be resolved.
 *
 * A promise can be in one of three states: pending, resolved, or rejected.
 *
 * When pending, a promise may transition to either the resolved or rejected
 * state.
 * When resolved, a promise will not transition to any other state, and has
 * a value, which will not change.
 * When rejected, a promise will not transition to any other state, and has
 * a reason, which will not change.
 * Here, “must not change” means immutable identity (i.e. ==), but does not
 * imply deep immutability.
 *
 * Subclassing notes. Although CKPromise can be extended without much
 * difficulty, it is recommended to not extend the CKPromose class, and
 * instead provide methods of other classes that create/return a promise.
 * For example a NSURLConnection object can return a promise to allow watching
 * it's state. The object that creates the promise will then be responsible
 * with resolving or rejecting the promise.
 *
 * Other notes. CKPromise doesn't have an abort (or cancel) method, as in the
 * current design a promise instance doesn't do much work excepting allowing
 * to be observed and moving from pending to resolved or rejected (this keeps
 * things simple and provides reduced coupling between classes). The abort of
 * an async operation should be taken care by objects that are very familliar
 * to the domain of the async operation. Given the NSURLConnection example,
 * cancelling the async operation should be handled by the NSURLConnection
 * instance, or by a manager if the url requests are managed by other objects.
 */
public class CKPromise<T> {
    internal var state: CKPromiseState<T> = .pending
    private var successCallbacks: [(T)->Void] = []
    private var failureCallbacks: [(Error)->Void] = []
    private let mutex = CKMutex(type: .normal)
    
    public init() {
        
    }
    
    private func register(success callback: @escaping (T) -> Void) {
        switch state {
        case .pending: successCallbacks.append { value in DispatchQueue.main.async { callback(value) } }
        case let .success(value): DispatchQueue.main.async { callback(value) }
        case .failure: break
        }
    }
    
    private func register(failure callback: @escaping (Error) -> Void) {
        switch state {
        case .pending: failureCallbacks.append { reason in DispatchQueue.main.async { callback(reason) } }
        case .success: break
        case let .failure(reason): DispatchQueue.main.async { callback(reason) }
        }
    }
    
    public func resolve(_ value: T) {
        mutex.locked {
            guard case .pending = state else { return }
            state = .success(value)
            successCallbacks.forEach { $0(value) }
            successCallbacks.removeAll()
            failureCallbacks.removeAll()
        }
    }
    
    public func resolve(_ promise: CKPromise<T>) {
        mutex.locked {
            
        }
    }
    
    public func reject(_ reason: Error) {
        mutex.locked {
            guard case .pending = state else { return }
            state = .failure(reason)
            failureCallbacks.forEach { $0(reason) }
            successCallbacks.removeAll()
            failureCallbacks.removeAll()
        }
    }
    
    @discardableResult
    public func on<U>(success successCallback: ((T) throws -> U)?,
                     failure failureCallback: ((Error) throws -> U)?) -> CKPromise<U> {
        let promise2 = CKPromise<U>()
        switch state {
        case .pending:
            successCallbacks.append {
                do {
                    try promise2.resolve(successCallback($0))
                } catch {
                    promise2.reject(error)
                }
            }
            failureCallback.append {
                do {
                    try promise2.resolve(successCallback($0))
                } catch {
                    promise2.reject(error)
                }
            }
            failureCallbacks.append { reason in DispatchQueue.main.async { callback(reason) } }
        case .success: break
        case let .failure(reason): DispatchQueue.main.async { callback(reason) }
        }
        return promise
        register(success: {
            do { try promise.resolve(successCallback($0)) }
            catch { promise.reject(error) }
        })
        register(failure: {
            do { try promise.resolve(failureCallback($0)) }
            catch { promise.reject(error) }
            })
        return promise
    }
    
    @discardableResult
    public func on<U>(success successCallback: @escaping (T) throws -> U) -> CKPromise<U> {
        let promise = CKPromise<U>()
        register(success: {
            do { try promise.resolve(successCallback($0)) }
            catch { promise.reject(error) }
        })
        register(failure: { promise.reject($0) })
        return promise
    }
    
    @discardableResult
    public func on<U>(failure failureCallback: @escaping (Error) throws -> U) -> CKPromise<Either<T,U>> {
        let promise = CKPromise<Either<T,U>>()
        register(success: { promise.resolve(.left($0)) })
        register(failure: {
            do { try promise.resolve(.right(failureCallback($0))) }
            catch { promise.reject(error) }
        })
        return promise
    }
    
    @discardableResult
    public func on<U>(completion completionCallback: @escaping (CKPromiseResult<T>) throws -> U) -> CKPromise<U> {
        let promise = CKPromise<U>()
        register(success: {
            do { try promise.resolve(completionCallback(.success($0))) }
            catch { promise.reject(error) }
        })
        register(failure: {
            do { try promise.resolve(completionCallback(.failure($0))) }
            catch { promise.reject(error) }
        })
        return promise
    }
    
    @discardableResult
    public func on<U>(success successCallback: @escaping (T) throws -> CKPromise<U>,
                     failure failureCallback: @escaping (Error) throws -> CKPromise<U>) -> CKPromise<U> {
        let promise = CKPromise<U>()
        register(success: {
            do { try promise.resolve(successCallback($0)) }
            catch { promise.reject(error) }
        })
        register(failure: {
            do { try promise.resolve(failureCallback($0)) }
            catch { promise.reject(error) }
        })
        return promise
    }
    
    @discardableResult
    public func on<U>(success successCallback: @escaping (T) throws -> CKPromise<U>) -> CKPromise<U> {
        let promise = CKPromise<U>()
        register(success: {
            do { try promise.resolve(successCallback($0)) }
            catch { promise.reject(error) }
        })
        register(failure: { promise.reject($0) })
        return promise
    }
    
//    @discardableResult
//    public func on<U>(failure failureCallback: @escaping (Error) throws -> CKPromise<U>) -> CKPromise<T> {
//        let promise = CKPromise<T>()
//        register(success: { promise.resolve($0) })
//        register(failure: {
//            do { try promise.resolve(failureCallback($0)) }
//            catch { promise.reject(error) }
//        })
//        return promise
//    }
    
    @discardableResult
    public func on<U>(completion completionCallback: @escaping (CKPromiseResult<T>) throws -> CKPromise<U>) -> CKPromise<U> {
        let promise = CKPromise<U>()
        register(success: {
            do { try promise.resolve(completionCallback(.success($0))) }
            catch { promise.reject(error) }
        })
        register(failure: {
            do { try promise.resolve(completionCallback(.failure($0))) }
            catch { promise.reject(error) }
        })
        return promise
    }
}

public enum Either<A,B> {
    case left(A)
    case right(B)
}

public enum CKPromiseResult<T> {
    case success(T)
    case failure(Error)
}

internal enum CKPromiseState<T> {
    case pending
    case success(T)
    case failure(Error)
}

class CKMutex {
    enum `Type` {
        case normal
        case errorCheck
        case recursive
        case `default`
        
        var mutexTypeValue: Int32 {
            switch self {
            case .normal: return PTHREAD_MUTEX_NORMAL
            case .errorCheck: return PTHREAD_MUTEX_ERRORCHECK
            case .recursive: return PTHREAD_MUTEX_RECURSIVE
            case .default: return PTHREAD_MUTEX_DEFAULT
            }
        }
    }
    private var mutex = pthread_mutex_t()
    
    init(type: Type = .default) {
        var attr = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure()
        }
        pthread_mutexattr_settype(&attr, type.mutexTypeValue)
        guard pthread_mutex_init(&mutex, &attr) == 0 else {
            preconditionFailure()
        }
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    func locked<T>(_ closure: () -> T) -> T{
        pthread_mutex_lock(&mutex)
        defer { pthread_mutex_unlock(&mutex) }
        return closure()
    }
}
