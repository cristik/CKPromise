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


#import <Foundation/Foundation.h>

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
NS_ASSUME_NONNULL_BEGIN
@interface CKPromise: NSObject

/**
  * Returns a pending promise. Call resolve/reject to change the promise state.
  */
+ (CKPromise* __nonnull)promise;

/** 
  * A promise provides a "then" method to access its current or eventual value 
  * or reason.
  *
  * A promise’s then method accepts two arguments:
  * promise.then(resolveHandler, rejectHandler)
  * Both resolveHandler and rejectHandler are optional arguments:
  * - if resolveHandler is not a valid block, it is ignored.
  * - if rejectHandler is not a valid block, it is ignored.
  * - if resolveHandler is a valid block:
  *   - it will be called after promise is resolved, with promise’s value as 
  *     its first argument.
  *   - it will not be called before promise is resolved.
  *   - it will not be called more than once.
  * - if rejectHandler is a valid block:
  *   - it will be called after promise is rejected, with promise’s reason as 
  *     its first argument.
  *   - it will not be called before promise is rejected.
  *   - it will not be called more than once.
  * - resolveHandler or rejectHandler will be async dispatched on the main 
  *   thread, which means they will be executed after the current context ends
  *
  * "then" may be called multiple times on the same promise.
  * If/when promise is resolved, all respective resolveHandler callbacks will
  * execute in the order of their originating calls to "then".
  * If/when promise is rejected, all respective rejectHandler callbacks will 
  * execute in the order of their originating calls to "then".
  * 
  * "then" returns a promise: 
  * promise2 = promise1.then(resolveHandler, rejectHandler);
  * 
  * If either resolveHandler or rejectHandler returns a value x, run the Promise
  * Resolution Procedure [[Resolve]](promise2, x).
  * If either resolveHandler or rejectHandler throws an exception e, promise2
  * will be rejected with e as the reason.
  * If resolveHandler is not a valid block and promise1 is resolved, promise2
  * will be resolved with the same value as promise1.
  * If rejectHandler is not a function and promise1 is rejected, promise2 will 
  * be rejected with the same reason as promise1.
  * 
  * A valid promise callback handler is a block that has one of the following
  * signatures:
  * - void(^)(void) 
  *   (no return value, nu arguments)
  * - void(^)(char/short/int/long/long long/float/double/id_or_class)
  *   (no return value, scalar or object to receive as promise value)
  * - id_or_class(^)(void)
  *   (with return value, no arguments)
  * - id_or_class(^)(scalar/object)
  *   (with return value, expects the promise value)
  * - void/id_or_class(^)(scalar/id_or_class, id_or_class [, id_or_class])
  *   (handler that accepts two or more values, for promises that resolve with 
  *    multiple values)
  */

- (CKPromise* (^)(id _Nullable resolveHandler,
                  id _Nullable rejectHandler))then;

- (CKPromise* (^)(id _Nullable (^ _Nullable resolveHandler)(id _Nullable value),
                  id _Nullable (^ _Nullable rejectHandler)(id _Nullable reason)))strictThen;

- (CKPromise*)then:(id _Nullable)resolveHandler
                  :(id _Nullable)rejectHandler;

- (CKPromise*)strictThen:(id _Nullable (^ _Nullable)(id _Nullable value))resolveHandler
                        :(id _Nullable (^ _Nullable)(id _Nullable reason))rejectHandler;

- (CKPromise* (^)(dispatch_queue_t queue,
                  id _Nullable resolveHandler,
                  id _Nullable rejectHandler))queuedThen;

- (CKPromise* (^)(dispatch_queue_t queue,
                  id _Nullable (^ _Nullable resolveHandler)(id _Nullable value),
                  id _Nullable (^ _Nullable rejectHandler)(id _Nullable reason)))queuedStrictThen;

- (CKPromise*)queuedThen:(dispatch_queue_t)queue
                        :(id _Nullable)resolveHandler
                        :(id _Nullable)rejectHandler;

- (CKPromise*)queuedStrictThen:(dispatch_queue_t)queue
                              :(id _Nullable (^ _Nullable)(id _Nullable value))resolveHandler
                              :(id _Nullable (^ _Nullable)(id _Nullable reason))rejectHandler;

/**
  * Resolves the promise with the provided value
  *
  * The promise resolution procedure is an abstract operation taking as input 
  * a value x. If x is a promise, it attempts to make promise adopt the state 
  * of x. Otherwise, it resolves promise with the value x.
  *
  * [promise resolve:x] performs the following steps:
  * - if promise and x refer to the same object, reject promise with a
  *   TypeErrorException as the reason.
  * - If x is a promise, adopt its state:
  *   -  if x is pending, promise will remain pending until x is resolved
  *      or rejected.
  *   - if/when x is resolved, resolve promise with the same value.
  *   - if/when x is rejected, reject promise with the same reason.
  *
  * - If x is not a promise, resolve promise with x.
  */
- (void)resolve:(id _Nullable)value;

/**
  * Rejects the promise with the provided value
  */
- (void)reject:(id _Nullable)reason;

@end

@interface CKPromise(Extra)

/**
  * Returns a resolved promise
  */
+ (CKPromise*)resolvedWith:(id _Nullable)value;

/**
  * Returns a rejected promise
  */
+ (CKPromise*)rejectedWith:(id _Nullable)reason;

/**
  * Returns a promise that gets resolved when all input promises are resolved
  * The resolve value consists in a NSArray populated with the results from
  * the aggregated promises.
  * In case of the promises fails, the aggregate promise fails with the reason
  * of the first failed promise. In this scenario, the other promises are kept
  * running.
  */
+ (CKPromise*)when:(NSArray* _Nullable)promises;

/**
  * Alias for then(resolveHandler, nil)
  */
- (CKPromise*(^)(id resolveHandler))success;
- (CKPromise*(^)(id _Nullable (^ resolveHandler)(id _Nullable value)))strictSuccess;
- (CKPromise*)success:(id)resolveHandler;
- (CKPromise*)strictSuccess:(id _Nullable (^)(id _Nullable value))resolveHandler;

/** 
  * Alias for then(nil, rejectHandler)
  */
- (CKPromise*(^)(id rejectHandler))failure;
- (CKPromise*(^)(id _Nullable (^ rejectHandler)(id _Nullable reason)))strictFailure;
- (CKPromise*)failure:(id)rejectHandler;
- (CKPromise*)strictfailure:(id _Nullable (^)(id _Nullable reason))rejectHandler;

/**
  * Alias for then(handler, handler)
  */
- (CKPromise*(^)(void (^ handler)()))always;
- (CKPromise*)always:(void (^)())handler;

@end

/**
 * Thrown if a promise callback returns the same promise
 */
@interface CKTypeErrorException: NSException
@end

/**
 * Thrown if a promise is attempted to be resolved/rejected twice
 * or the promise is attempted to be rejected after being resolved,
 * or vice-versa
 */
@interface CKHasResolutionException: NSException
@end

/**
 * Thrown if a passed promise callback is not a valid block
 */
@interface CKInvalidHandlerException: NSException
@end
NS_ASSUME_NONNULL_END
