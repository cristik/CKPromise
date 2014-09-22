//
//  CKPromise+Extra.h
//  CKPromise
//
//  Created by Cristian Kocza on 22/09/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import "CKPromise.h"

typedef void(^CKPromiseHandler2)(id);

@interface CKPromise(Extra)

+ (CKPromise*)resolvedPromise:(id)value;
+ (CKPromise*)rejectedPromise:(id)reason;
+ (CKPromise*)aggregatePromise:(NSArray*)promises;

- (CKPromiseState)state;
- (id)value;
- (id)reason;

// simplified version of then::, if no promise chaining is needed
- (CKPromise*)then2:(CKPromiseHandler2)resolveHandler :(CKPromiseHandler2)rejectHandler;
// alias for [promise then:resolveHandler :nil]
- (CKPromise*)done:(CKPromiseHandler)resolveHandler;
// alias for [promise then:nil :rejectHandler]
- (CKPromise*)fail:(CKPromiseHandler)rejectHandler;
// alias for [promise then:handler :handler]
- (CKPromise*)always:(CKPromiseHandler)handler;

@end
