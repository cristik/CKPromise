//
//  CKPromise.h
//  CKPromise
//
//  Created by Cristian Kocza on 9/16/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id(^CKPromiseHandler)(id);

typedef NS_ENUM(NSUInteger, CKPromiseState){
    CKPromiseStatePending,
    CKPromiseStateResolved,
    CKPromiseStateRejected
};

@interface CKTypeErrorException: NSException
@end

@interface CKHasResolutionException: NSException
@end

/**
 * Promise A+ implementation for Objective-C. See http://promisesaplus.com/ for detailed specs
 */
@interface CKPromise : NSObject

+ (CKPromise*)promise;
+ (CKPromise*)resolvedPromise:(id)value;
+ (CKPromise*)rejectedPromise:(id)reason;
+ (CKPromise*)aggregatePromise:(NSArray*)promises;


- (CKPromise*)then:(CKPromiseHandler)resolveHandler :(CKPromiseHandler)rejectHandler;
- (CKPromise*)done:(CKPromiseHandler)resolveHandler;
- (CKPromise*)fail:(CKPromiseHandler)rejectHandler;
- (CKPromise*)always:(CKPromiseHandler)handler;

- (void)resolve:(id)value;
- (void)reject:(id)reason;

- (CKPromiseState)state;
- (id)value;
- (id)reason;

@end
