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




#import <Foundation/Foundation.h>


@interface CKTypeErrorException: NSException
@end

@interface CKHasResolutionException: NSException
@end

@interface CKInvalidHandlerException: NSException
@end

/**
  * Promise A+ implementation for Objective-C. See http://promisesaplus.com/ 
  * for detailed specs
  */
@interface CKPromise: NSObject

/**
  * Designated initializer. Returns a pending promise. Call resolve or reject to 
  * change the promise state
  */
+ (CKPromise*)promise;

/** allows callers to observe the promise state
  * resolveHanlder is called with the promise value when the promise is resolved
  * rejectHanlder is called with the promise fail reason when the promise is 
  * rejected
  * @returns a new promise
  */
- (CKPromise*(^)(id resolveHandler, id rejectHandler))then;

/** 
  * similar to then::, however it doesn't create a new promise, it returns 
  * itself
  */
- (CKPromise*(^)(id resolveHandler, id rejectHandler))on;

/**
  * Resolves the promise with the provided value
  */
- (void)resolve:(id)value;

/**
  * Rejects the promise with the provided value
  */
- (void)reject:(id)reason;

/**
  * Aborts the promise. No callbacks are called. Subclasses need to call super in order to avoid
  * any memory leaks due to circular references in the callbacks
  */
- (void)abort;

@end

@interface CKPromise(Extra)

/**
  * Returns a resolved promise
  */
+ (CKPromise*)resolved:(id)value;

/**
 * Returns a rejected promise
 */
+ (CKPromise*)rejected:(id)reason;

/**
 * Returns a promise that gets resolved when all input promises are resolved
 */
+ (CKPromise*)when:(NSArray*)promises;

/**
  * alias for then(,resolveHandler, nil)
  */
- (CKPromise*(^)(id resolveHandler))done;

/** 
  * alias for then(nil, rejectHandler)
  */
- (CKPromise*(^)(id rejectHandler))fail;
/**
  * alias for then(handler, handler)
  */
- (CKPromise*(^)(id handler))always;

/**
  * alias for promise.on(resolveHander, reject)
  */
- (CKPromise*(^)(id resolveHandler))onResolve;

/**
  * alias for promise.on(nil, rejectHandler)
  */
- (CKPromise*(^)(id rejectHandler))onReject;

/**
  * alias for promise.onResolve(handler, handler)
  */
- (CKPromise*(^)(id rejectHandler))onAny;

@end
