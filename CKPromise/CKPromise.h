//
//  CKPromise.h
//  CKPromise
//
//  Created by Cristian Kocza on 9/16/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CKTypeErrorException: NSException
@end

@interface CKHasResolutionException: NSException
@end

@interface CKInvalidHandlerException: NSException
@end

/**
  * Promise A+ implementation for Objective-C. See http://promisesaplus.com/ for detailed specs
  */
@interface CKPromise: NSObject

/**
  * Designated initializer. Returns a pending promise. Call resolve or reject to change the promise
  * state
  */
+ (CKPromise*)promise;

/** allows callers to observe the promise state
  * resolveHanlder is called with the promise value when the promise is resolved
  * rejectHanlder is called with the promise fail reason when the promise is rejected
  * @returns a new promise
  */
- (CKPromise*(^)(id resolveHandler, id rejectHandler))then;

/** 
  * similar to then::, however it doesn't create a new promise, it returns itself
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
