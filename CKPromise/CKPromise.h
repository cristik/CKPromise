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
@interface CKPromise : NSObject

+ (CKPromise*)promise;

// allows callers to observe the promise state
// resolveHanlder is called with the promise value when the promise is resolved
// rejectHanlder is called with the promise fail reason when the promise is rejected
// returns a new promise
- (CKPromise*(^)(id resolveHandler, id rejectHandler))then;

// similar to then::, however it doesn't create a new promise, it returns itself
- (CKPromise*(^)(id resolveHandler, id rejectHandler))on;

- (void)resolve:(id)value;
- (void)reject:(id)reason;

@end
