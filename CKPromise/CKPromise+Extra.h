//
//  CKPromise+Extra.h
//  CKPromise
//
//  Created by Cristian Kocza on 22/09/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import "CKPromise.h"

typedef NS_ENUM(NSUInteger, CKPromiseState){
    CKPromiseStatePending,
    CKPromiseStateResolved,
    CKPromiseStateRejected
};

@interface CKPromise(Extra)

+ (CKPromise*)resolved:(id)value;
+ (CKPromise*)rejected:(id)reason;
+ (CKPromise*)when:(NSArray*)promises;

- (CKPromiseState)state;
- (id)value;
- (id)reason;

// alias for [promise then:resolveHandler :nil]
- (CKPromise*)done:(id)resolveHandler;
// alias for [promise then:nil :rejectHandler]
- (CKPromise*)fail:(id)rejectHandler;
// alias for [promise then:handler :handler]
- (CKPromise*)always:(id)handler;

@end
