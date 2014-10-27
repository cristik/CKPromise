// Copyright (c) 2014, Cristian Kocza
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "CKPromise.h"

struct CKBlockLiteral{
    void *isa;
    int flags;
    int reserved; // is actually the retain count of heap allocated blocks
    void (*invoke)(void *, ...); // a pointer to the block's compiled code
    struct CKBlockDescriptor {
        unsigned long int reserved;  // always nil
    	unsigned long int size;  // size of the entire CKBlockLiteral
        
        // functions used to copy and dispose of the block (if needed)
    	void (*copy_helper)(void *dst, void *src);
    	void (*dispose_helper)(void *src);
    } *descriptor;
    
    // Here the struct contains one entry for every surrounding scope variable.
    // For non-pointers, these entries are the actual const values of
    // the variables. For pointers, there are a range of possibilities
    // (__block pointer, object pointer, weak pointer, ordinary pointer)

};

typedef NS_OPTIONS(NSUInteger, CKBlockDescriptionFlags) {
    CKBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    CKBlockDescriptionFlagsHasCtor = (1 << 26),
    CKBlockDescriptionFlagsIsGlobal = (1 << 28),
    CKBlockDescriptionFlagsHasStret = (1 << 29),
    CKBlockDescriptionFlagsHasSignature = (1 << 30)
};

typedef NS_ENUM(NSUInteger, CKPromiseState){
    CKPromiseStatePending,
    CKPromiseStateResolved,
    CKPromiseStateRejected
};


@implementation CKTypeErrorException
+ (void)raise{
    [[self exceptionWithName:@"TypeError"
                      reason:@"TypeError"
                    userInfo:nil] raise];
}
@end


@implementation CKHasResolutionException
+ (void)raise{
    [[self exceptionWithName:@"HasResolution"
                      reason:@"Already resolved/rejected"
                    userInfo:nil] raise];
}
@end

@implementation CKInvalidHandlerException
+ (void)raise{
    [[self exceptionWithName:@"InvalidHandler"
                      reason:@"Passed handler is not a valid promise handler"
                    userInfo:nil] raise];
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

+ (CKPromise*)when:(NSArray*)promises{
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
        promise.then(^id(id value) {
            handler(value, YES);
            return nil;
        }, ^id(id reason) {
            handler(reason, NO);
            return nil;
        });
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

- (CKPromise*(^)(id resolveHandler, id rejectHandler))then{
    return ^CKPromise*(id resolveHandler, id rejectHandler){
        id (^actualResolveHandler)(id) = [CKPromise transformHandler:resolveHandler];
        id (^actualRejectHandler)(id) = [CKPromise transformHandler:rejectHandler];
        CKPromise *resultPromise = [CKPromise promise];
        dispatch_block_t successHandlerWrapper = ^{
            @try{
                if(actualResolveHandler){
                    [resultPromise resolve:actualResolveHandler(_value)];
                }else{
                    [resultPromise resolve:_value];
                }
            }@catch (NSException *ex) {
                [resultPromise reject:ex];
            }
        };
        dispatch_block_t errorHandlerWrapper = ^{
            @try{
                if(actualRejectHandler){
                    [resultPromise resolve:actualRejectHandler(_reason)];
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
    };
}

- (CKPromise*(^)(id resolveHandler, id rejectHandler))on{
    return ^CKPromise*(id resolveHandler, id rejectHandler){
        id (^actualResolveHandler)(id) = [CKPromise transformHandler:resolveHandler];
        id (^actualRejectHandler)(id) = [CKPromise transformHandler:rejectHandler];
        if(actualResolveHandler){
            dispatch_block_t successHandlerWrapper = ^{
                actualResolveHandler(_value);
            };
            if(_state == CKPromiseStateResolved){
                [self dispatch:successHandlerWrapper];
            }else{
                [_resolveHandlers addObject:successHandlerWrapper];
            }
        }
        if(actualRejectHandler){
            dispatch_block_t errorHandlerWrapper = ^{
                actualRejectHandler(_reason);
            };
            if(_state == CKPromiseStateRejected){
                [self dispatch:errorHandlerWrapper];
            }else{
                [_rejectHandlers addObject:errorHandlerWrapper];
            }
        }
        return self;
    };
}

- (CKPromise*(^)(id resolveHandler))done{
    return ^CKPromise*(id resolveHandler){
        return self.then(resolveHandler, nil);
    };
}

- (CKPromise*(^)(id rejectHandler))fail{
    return ^CKPromise*(id rejectHandler){
        return self.then(nil, rejectHandler);
    };
}

- (CKPromise*(^)(id handler))always{
    return ^CKPromise*(id handler){
        return self.then(handler, handler);
    };
}

- (CKPromise*(^)(id resolveHandler))onResolve{
    return ^CKPromise*(id resolveHandler){
        return self.on(resolveHandler, nil);
    };
}

- (CKPromise*(^)(id rejectHandler))onReject{
    return ^CKPromise*(id rejectHandler){
        return self.on(nil, rejectHandler);
    };
}

- (CKPromise*(^)(id handler))onAny{
    return ^CKPromise*(id handler){
        return self.on(handler, handler);
    };
}

- (void)resolve:(id)value{
    if(_state != CKPromiseStatePending){
        [CKHasResolutionException raise];
    }
    // 1. If promise and x refer to the same object, reject promise with a
    //    TypeError as the reason.
    if(value == self){
        [CKTypeErrorException raise];
    }
    
    //2. If x is a promise, adopt its state [3.4]:
    if([value isKindOfClass:[CKPromise class]]){
        //   i. If x is pending, promise must remain pending until x is fulfilled
        //      or rejected.
        //  ii. If/when x is fulfilled, fulfill promise with the same value.
        // iii. If/when x is rejected, reject promise with the same reason.
        ((CKPromise*)value).then(^id(id value) {
            [self resolve:value];
            return nil;
        }, ^id(id reason){
            [self reject:reason];
            return nil;
        });
        return;
    }
    
    // 3. Otherwise, if x is an object or function,
    // (this doesn't apply to Objective-C)
    
    // 4. If x is not an object or function, fulfill promise with x.
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
        [CKHasResolutionException raise];
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


#pragma mark -
#pragma mark Privates
#pragma mark -

+ (NSMethodSignature*)methodSignatureForBlock:(id)block{
    if (![block isKindOfClass:NSClassFromString(@"__NSGlobalBlock__")] &&
        ![block isKindOfClass:NSClassFromString(@"__NSStackBlock__")] &&
        ![block isKindOfClass:NSClassFromString(@"__NSMallocBlock__")]) return nil;

    struct CKBlockLiteral *blockRef = (__bridge struct CKBlockLiteral *)block;
    CKBlockDescriptionFlags flags = (CKBlockDescriptionFlags)blockRef->flags;

    if (flags & CKBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);

        if (flags & CKBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }

        const char *signature = (*(const char **)signatureLocation);
        return [NSMethodSignature signatureWithObjCTypes:signature];
    }
    return nil;
}

+ (id(^)(id))transformHandler:(id)block{
    if(!block) return nil;
    
    NSMethodSignature *blockSignature = [self methodSignatureForBlock:block];
    if(!blockSignature) return nil;
    
    NSUInteger blockArgumentCount = blockSignature.numberOfArguments;
    const char *blockReturnType = blockSignature.methodReturnType;
    BOOL blockReturnsVoid = !strcmp(blockReturnType, @encode(void));
    BOOL blockReturnsId = strstr(blockReturnType, @encode(id)) == blockReturnType;
    
    if(blockArgumentCount == 1){
        if(blockReturnsVoid){
            return ^id(id arg){
                ((void(^)(void))block)();
                return nil;
            };
        } else if(blockReturnsId){
            return ^id(id arg){
                return ((id(^)(void))block)();
            };
        }
    }else if(blockArgumentCount == 2 &&
       [blockSignature getArgumentTypeAtIndex:1][0] == '@'){
        if(blockReturnsVoid){
            return ^id(id arg){
                ((void(^)(id))block)(arg);
                return nil;
            };
        }else if(blockReturnsId){
            return (id(^)(id))block;
        }
    }
    
    [CKInvalidHandlerException raise];
    return nil;
}

@end
