//
//  CKPromise+Extra.h
//  CKPromise
//
//  Created by Cristian Kocza on 22/09/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import "CKPromise.h"

@interface CKPromise(Extra)

+ (CKPromise*)resolved:(id)value;
+ (CKPromise*)rejected:(id)reason;
+ (CKPromise*)when:(NSArray*)promises;

// alias for [promise then:resolveHandler :nil]
- (CKPromise*(^)(id resolveHandler))done;
// alias for [promise then:nil :rejectHandler]
- (CKPromise*(^)(id rejectHandler))fail;
// alias for [promise then:handler :handler]
- (CKPromise*(^)(id handler))always;

@end
