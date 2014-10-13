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
- (CKPromise*(^)(id resolveHandler))done;
// alias for [promise then:nil :rejectHandler]
- (CKPromise*(^)(id resolveHandler))fail;
// alias for [promise then:handler :handler]
- (CKPromise*(^)(id resolveHandler))always;

@end
