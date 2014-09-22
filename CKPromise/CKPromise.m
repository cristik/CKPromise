//
//  CKPromise.m
//  CKPromise
//
//  Created by Cristian Kocza on 9/16/14.
//  Copyright (c) 2014 Cristik. All rights reserved.
//

#import "CKPromise.h"

@implementation CKTypeErrorException
+ (id)exception{
    return [self exceptionWithName:@"TypeError" reason:@"TypeError" userInfo:nil];
}
@end


@implementation CKHasResolutionException
+ (id)exception{
    return [self exceptionWithName:@"HasResolution" reason:@"Already resolved/rejected" userInfo:nil];
}
@end

@implementation CKPromise{
    CKPromiseState _state;
    id _value;
    id _reason;
    NSMutableArray *_resolveHandlers;
    NSMutableArray *_rejectHandlers;
}

+ (CKPromise*)promise{
    return [[self alloc] init];
}

+ (CKPromise*)resolvedPromise:(id)value{
    CKPromise *promise = [self promise];
    [promise resolve:value];
    return promise;
}

+ (CKPromise*)rejectedPromise:(id)reason{
    CKPromise *promise = [self promise];
    [promise reject:reason];
    return promise;
}

+ (CKPromise*)aggregatePromise:(NSArray*)promises{
    CKPromise *promise = [self promise];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:promises.count];
    NSMutableArray *reasons = [NSMutableArray arrayWithCapacity:promises.count];
    __block NSUInteger runningPromises = promises.count;
    __block BOOL hadError = NO;
    void(^handler)(id, BOOL) = ^(id obj, BOOL resolved){
        if(resolved && obj) [values addObject:obj];
        else if(!resolved && obj) [reasons addObject:obj];
        if(!resolved) hadError = YES;
        runningPromises --;
        if(runningPromises == 0){
            if(hadError){
                [promise reject:reasons];
            }else{
                [promise resolve:values];
            }
        }

    };
    for(CKPromise *promise in promises){
        [promise then:^id(id value) {
            handler(value, YES);
            return nil;
        } :^id(id reason) {
            handler(reason, NO);
            return nil;
        }];
    }
    return promise;
}

- (id)init{
    if(self = [super init]){
        _resolveHandlers = [[NSMutableArray alloc] init];
        _rejectHandlers = [[NSMutableArray alloc] init];
        _state = CKPromiseStatePending;
    }
    return self;
}

- (void)dispatch:(dispatch_block_t)block{
    dispatch_async(dispatch_get_main_queue(), block);
}

- (CKPromise*)then:(CKPromiseHandler)resolveHandler :(CKPromiseHandler)rejectHandler{
    CKPromise *resultPromise = [CKPromise promise];
    dispatch_block_t successHandlerWrapper = ^{
        @try{
            if(resolveHandler){
                [resultPromise resolve:resolveHandler(_value)];
            }else{
                [resultPromise resolve:_value];
            }
        }@catch (NSException *ex) {
            [resultPromise reject:ex];
        }
    };
    dispatch_block_t errorHandlerWrapper = ^{
        @try{
            if(rejectHandler){
                [resultPromise resolve:rejectHandler(_reason)];
            }else{
                [resultPromise reject:_reason];
            }
        }@catch (NSException *ex) {
            [resultPromise reject:ex];
        }
    };
    if(_state == CKPromiseStateResolved){
        [self dispatch:successHandlerWrapper];
    }else if(_state == CKPromiseStateRejected){
        [self dispatch:errorHandlerWrapper];
    }else{
        [_resolveHandlers addObject:successHandlerWrapper];
        [_rejectHandlers addObject:errorHandlerWrapper];
    }
    return resultPromise;
}

- (CKPromise*)done:(CKPromiseHandler)resolveHandler{
    return [self then:resolveHandler :nil];
}

- (CKPromise*)fail:(CKPromiseHandler)rejectHandler{
    return [self then:nil :rejectHandler];
}

- (CKPromise*)always:(CKPromiseHandler)handler{
    return [self then:handler :handler];
}

- (void)resolve:(id)value{
    if(_state != CKPromiseStatePending){
        [[CKHasResolutionException exception] raise];
    }
    //1. If promise and x refer to the same object, reject promise with a TypeError as the reason.
    if(value == self){
        [[CKTypeErrorException exception] raise];
    }
    
    //2. If x is a promise, adopt its state [3.4]:
    if([value isKindOfClass:[CKPromise class]]){
        //i. If x is pending, promise must remain pending until x is fulfilled or rejected.
        //ii. If/when x is fulfilled, fulfill promise with the same value.
        //iii. If/when x is rejected, reject promise with the same reason.
        [value then:^id(id value) {
            [self resolve:value];
            return nil;
        } :^id(id reason){
            [self reject:reason];
            return nil;
        }];
        return;
    }
    
    //3. Otherwise, if x is an object or function,
    // this doesn't apply to Objective-C
    
    //4. If x is not an object or function, fulfill promise with x.
    _state = CKPromiseStateResolved;
    _value = value;
    [self dispatch:^{
        for(dispatch_block_t resolveHandler in _resolveHandlers){
            resolveHandler();
        }
        [_resolveHandlers removeAllObjects];
        [_rejectHandlers removeAllObjects];
    }];
}

- (void)reject:(id)reason{
    if(_state != CKPromiseStatePending){
        [[CKHasResolutionException exception] raise];
    }
    _state = CKPromiseStateRejected;
    _reason = reason;
    [self dispatch:^{
        for(dispatch_block_t rejectHandler in _rejectHandlers){
            rejectHandler();
        }
        [_resolveHandlers removeAllObjects];
        [_rejectHandlers removeAllObjects];
    }];
}

- (CKPromiseState)state{
    return _state;
}

- (id)value{
    return _value;
}

- (id)reason{
    return _reason;
}
@end
