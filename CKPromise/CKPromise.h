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

@interface CKPromise : NSObject

- (CKPromise*)then:(CKPromiseHandler)fulfillHandler :(CKPromiseHandler)rejectHandler;

+ (CKPromise*)promise;

- (void)resolve:(id)value;
- (void)reject:(id)reason;

- (CKPromiseState)state;

@end
