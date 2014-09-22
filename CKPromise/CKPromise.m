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
    BOOL _resolved;
    BOOL _rejected;
    id _value;
    id _reason;
    NSMutableArray *_resolveHandlers;
    NSMutableArray *_rejectHandlers;
}

- (CKPromise*)then:(CKPromiseHandler)fulfillHandler :(CKPromiseHandler)rejectHandler{
    CKPromise *resultPromise = [CKPromise promise];
    dispatch_block_t successHandlerWrapper = ^{
        @try{
            if(fulfillHandler){
                [resultPromise resolve:fulfillHandler(_value)];
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
    if(_resolved){
        dispatch_async(dispatch_get_main_queue(), successHandlerWrapper);
    }else if(_rejected){
        dispatch_async(dispatch_get_main_queue(), errorHandlerWrapper);
    }else{
        [_resolveHandlers addObject:successHandlerWrapper];
        [_rejectHandlers addObject:errorHandlerWrapper];
    }
    return resultPromise;
}

+ (CKPromise*)promise{
    return [[self alloc] init];
}

+ (CKPromise*)resolved:(id)value{
    CKPromise *promise = [self promise];
    [promise resolve:value];
    return promise;
}

+ (CKPromise*)rejected:(id)reason{
    CKPromise *promise = [self promise];
    [promise reject:reason];
    return promise;
}

- (id)init{
    if(self = [super init]){
        _resolveHandlers = [[NSMutableArray alloc] init];
        _rejectHandlers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)resolve:(id)value{
    if(_resolved || _rejected){
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
    _resolved = YES;
    _value = value;
    dispatch_async(dispatch_get_main_queue(), ^{
        for(dispatch_block_t resolveHandler in _resolveHandlers){
            resolveHandler();
        }
        [_resolveHandlers removeAllObjects];
        [_rejectHandlers removeAllObjects];
    });
}

- (void)reject:(id)reason{
    if(_resolved || _rejected){
        [[CKHasResolutionException exception] raise];
    }
    _rejected = YES;
    _reason = reason;
    dispatch_async(dispatch_get_main_queue(), ^{
        for(dispatch_block_t rejectHandler in _rejectHandlers){
            rejectHandler();
        }
        [_resolveHandlers removeAllObjects];
        [_rejectHandlers removeAllObjects];
    });
}

- (CKPromiseState)state{
    if(_resolved) return CKPromiseStateResolved;
    else if(_rejected) return CKPromiseStateRejected;
    else return CKPromiseStatePending;
}
@end
