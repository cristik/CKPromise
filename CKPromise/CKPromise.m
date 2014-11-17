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
    int reserved;
    void (*invoke)(void *, ...);
    struct CKBlockDescriptor {
        unsigned long int reserved;
    	unsigned long int size;
    	void (*copy_helper)(void *dst, void *src);
    	void (*dispose_helper)(void *src);
    } *descriptor;
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

@interface CKPromiseArray: NSObject{
@public
    NSArray *_objects;
}

- (id)initWithVaList:(va_list)valist arg0:(id)arg0;
- (id)initWithObjects:(NSArray*)objects;
- (id)objectAtIndex:(NSUInteger)index;
- (id)objectAtIndexedSubscript:(NSUInteger)index;
@end

@interface CKNull: NSObject
+ (id)null;
@end

@implementation CKPromiseArray

- (id)initWithVaList:(va_list)valist arg0:(id)arg0{
    NSMutableArray *objects = [NSMutableArray array];
    if(arg0){
        [objects addObject:arg0];
        for(id obj; (obj = va_arg(valist, id));){
            [objects addObject:obj];
        }
    }
    return [self initWithObjects:objects];
}

- (id)initWithObjects:(NSArray*)objects{
//    if(objects.count == 0) return nil;
//    else if(objects.count == 1) return _objects[0];
    if(self = [super init]){
        _objects = objects;
    }
    return self;
}

- (id)objectAtIndex:(NSUInteger)index{
    if(index >= _objects.count) return nil;
    id result = _objects[index];
    return result == [CKNull null] ? nil : result;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index{
    return [self objectAtIndex:index];
}
@end

@implementation CKNull
+ (id)null{
    static dispatch_once_t onceToken;
    static CKNull *null = nil;
    dispatch_once(&onceToken, ^{
        null = [[CKNull alloc] init];
    });
    return null;
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
    __block NSUInteger runningPromises = promises.count;

    void(^handler)(id, BOOL) = ^(CKPromiseArray *arr, BOOL resolved){
        if(!resolved) {
            [promise reject:arr];
        } else {
            runningPromises--;
            if(arr->_objects.count == 0) {
                [values addObject:[NSNull null]];
            } else if(arr->_objects.count == 1) {
                [values addObject:arr[0]];
            } else {
                BOOL hasCKNull = NO;
                for(id val in arr->_objects){
                    if(val == [CKNull null]){
                        hasCKNull = YES;
                        break;
                    }
                }
                if(hasCKNull) {
                    NSMutableArray *mappedArr =
                    [NSMutableArray arrayWithCapacity:arr->_objects.count];
                    for(id val in arr->_objects) {
                        if(val == [CKNull null]) {
                            [mappedArr addObject:[NSNull null]];
                        } else {
                            [mappedArr addObject:val];
                        }
                    }
                } else {
                    [values addObject:arr->_objects];
                }
            }
            if(runningPromises == 0) {
                id value = [[CKPromiseArray alloc] initWithObjects:@[values]];
                [promise resolve:value];
            }
        }
    };
    
    for(CKPromise *promise in promises){
        promise.then(^id(id value) {
            handler(promise->_value, YES);
            return nil;
        }, ^id(id reason) {
            handler(promise->_reason, NO);
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

- (void)resolve:(id)value{
    [self resolveWith:value, nil];
}

- (void)resolveWith:(id)value, ... {
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
    if([value isKindOfClass:[CKPromiseArray class]]){
        _value = value;
    } else {
        va_list valist;
        va_start(valist, value);
        _value = [[CKPromiseArray alloc] initWithVaList:valist arg0:value];
        va_end(valist);
    }
    [self dispatch:^{
        for(dispatch_block_t resolveHandler in _resolveHandlers){
            resolveHandler();
        }
        [_resolveHandlers removeAllObjects];
        [_rejectHandlers removeAllObjects];
    }];
}

- (void)reject:(id)reason{
    [self rejectWith:reason, nil];
}

- (void)rejectWith:(id)reason, ... {
    if(_state != CKPromiseStatePending){
        [CKHasResolutionException raise];
    }
    _state = CKPromiseStateRejected;
    if([reason isKindOfClass:[CKPromiseArray class]]){
        _reason = reason;
    } else {
        va_list valist;
        va_start(valist, reason);
        _reason = [[CKPromiseArray alloc] initWithVaList:valist arg0:reason];
        va_end(valist);
    }
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

    NSMethodSignature *signature = nil;
    if (flags & CKBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);

        if (flags & CKBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }

        const char *sigStr = (*(const char **)signatureLocation);
        signature = [NSMethodSignature signatureWithObjCTypes:sigStr];
    }
    return signature;
}

+ (id(^)(id))transformHandler:(id)block{
    if(!block) return nil;
    
    NSMethodSignature *blockSignature = [self methodSignatureForBlock:block];
    if(!blockSignature) return nil;
    
    NSUInteger blockArgumentCount = blockSignature.numberOfArguments;
    const char *blockReturnType = blockSignature.methodReturnType;
    BOOL blockReturnsVoid = blockReturnType[0] == 'v';
    BOOL blockReturnsObject = blockReturnType[0] == '@';
    
    if(blockArgumentCount == 1){
        if(blockReturnsVoid){
            return ^id(id arg){
                ((void(^)(void))block)();
                return nil;
            };
        } else if(blockReturnsObject){
            return ^id(id arg){
                return ((id(^)(void))block)();
            };
        }
    }else if(blockArgumentCount >= 2 && blockArgumentCount <= 4){
        for(int i=2;i<blockArgumentCount;i++){
            // check if the rest of the parameters are objects, we only allow
            // those
            if([blockSignature getArgumentTypeAtIndex:i][0] != '@'){
                [CKInvalidHandlerException raise];
                return nil;
            }
        }
#define buildBlock(type, selector)\
        if(blockReturnsVoid){\
            return ^id(CKPromiseArray *arr) {\
                type arg0 = [arr[0] selector];\
                switch(blockArgumentCount) {\
                    case 2:\
                        ((void(^)(type))block)(arg0);\
                        break;\
                    case 3:\
                        ((void(^)(type, id))block)(arg0, arr[1]);\
                        break;\
                    case 4:\
                        ((void(^)(type, id, id))block)(arg0, arr[1], arr[2]);\
                        break;\
                    default:\
                        break;\
                }\
                return nil;\
            };\
        } else if(blockReturnsObject) {\
            return ^id(CKPromiseArray *arr) {\
                type arg0 = [arr[0] selector];\
                switch(blockArgumentCount) {\
                    case 2:\
                        return ((id(^)(type))block)(arg0);\
                    case 3:\
                        return ((id(^)(type, id))block)(arg0, arr[1]);\
                    case 4:\
                        return ((id(^)(type, id, id))block)(arg0, arr[1],\
                            arr[2]);\
                    default:\
                        return nil;\
                }\
            };\
        }\
        break;\

        switch([blockSignature getArgumentTypeAtIndex:1][0]){
            case 'c':
            case 'C':
                buildBlock(char, charValue)
            case 'i':
            case 'I':
                buildBlock(int, intValue)
            case 's':
            case 'S':
                buildBlock(short, shortValue)
//            case 'l':
//            case 'L':
//                buildBlock(long, longValue)
            case 'q':
            case 'Q':
                buildBlock(long long, longLongValue)
            case 'f':
                buildBlock(float, floatValue)
            case 'd':
                buildBlock(double, doubleValue)
            case '@':
                buildBlock(id, self)
            default:
                break;
                
        }
    }
    
    // The block doesn't match any of the supported ones,
    // raise an exception
    [CKInvalidHandlerException raise];
    return nil;
}

@end
