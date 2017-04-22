// Copyright (c) 2014-2017, Cristian Kocza
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
#include <vector>

using namespace std;

struct CKBlockLiteral {
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

typedef NS_ENUM(NSUInteger, CKPromiseState) {
    CKPromiseStatePending,
    CKPromiseStateResolved,
    CKPromiseStateRejected
};

typedef void (^CKPromiseCallbackWrapper)(id);


@implementation CKTypeErrorException
+ (instancetype)exception {
    return [[self alloc] initWithName:@"TypeError"
                      reason:@"TypeError"
                    userInfo:nil];
}
@end


@implementation CKHasResolutionException
+ (instancetype)exception {
    return [[self alloc] initWithName:@"HasResolution"
                      reason:@"Already resolved/rejected"
                    userInfo:nil];
}
@end

@implementation CKInvalidHandlerException
+ (instancetype)exception {
    return [[self alloc] initWithName:@"InvalidHandler"
                      reason:@"Passed handler is not a valid promise handler"
                    userInfo:nil];
}
@end

@implementation CKPromise {
    CKPromiseState _state;
    id _valueOrReason;
    vector<CKPromiseCallbackWrapper> _resolveHandlers;
    vector<CKPromiseCallbackWrapper> _rejectHandlers;
}

static Class globalBlockClass = nil,
stackBlockClass = nil,
heapBlockClass = nil;

+ (void)initialize {
    if(self == CKPromise.class) {
        globalBlockClass = NSClassFromString(@"__NSGlobalBlock__");
        stackBlockClass = NSClassFromString(@"__NSStackBlock__");
        heapBlockClass = NSClassFromString(@"__NSMallocBlock__");
    }
}

+ (CKPromise*)promise {
    return [[self alloc] init];
}

+ (CKPromise*)resolvedWith:(id)value {
    CKPromise *promise = [self promise];
    [promise resolve:value];
    return promise;
}

+ (CKPromise*)rejectedWith:(id)reason {
    CKPromise *promise = [self promise];
    [promise reject:reason];
    return promise;
}

+ (CKPromise*)when:(NSArray*)promises {
    if(!promises.count) return [CKPromise resolvedWith:nil];
    
    CKPromise *resultPromise = [self promise];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:promises.count];
    __block NSUInteger runningPromises = promises.count;
    
    for(CKPromise *promise in promises){
        [promise then:^id(id value) {
            [values addObject:value ?: NSNull.null];
            if(--runningPromises == 0) [resultPromise resolve:values];
            return nil;
        } :^id(id reason) {
            [resultPromise reject: reason];
            return nil;
        }];
    }
    return resultPromise;
}

- (instancetype)init {
    if(self = [super init]) {
        _state = CKPromiseStatePending;
    }
    return self;
}

- (CKPromise* (^)(id resolveHandler, id rejectHandler))then {
    return ^CKPromise*(id resolveHandler, id rejectHandler) {
        return [self strictThen:[CKPromise transformHandler:resolveHandler]
                               :[CKPromise transformHandler:rejectHandler]];
    };
}

- (CKPromise* (^)(id(^resolveHandler)(id value), id(^rejectHandler)(id reason)))strictThen {
    return ^CKPromise*(id resolveHandler, id rejectHandler) {
        return [self strictThen:resolveHandler
                               :rejectHandler];
    };
}

- (CKPromise*)then:(id)resolveHandler :(id)rejectHandler {
    return [self strictThen:[CKPromise transformHandler:resolveHandler]
                           :[CKPromise transformHandler:rejectHandler]];
}

- (CKPromise*)strictThen:(id(^)(id value))resolveHandler :(id(^)(id reason))rejectHandler {
    return [self queuedStrictThen:dispatch_get_main_queue()
                                 :resolveHandler
                                 :rejectHandler];
}

- (CKPromise* (^)(dispatch_queue_t queue, id resolveHandler, id rejectHandler))queuedThen {
    return ^CKPromise*(dispatch_queue_t queue, id resolveHandler, id rejectHandler) {
        return [self queuedStrictThen:queue
                                     :[CKPromise transformHandler:resolveHandler]
                                     :[CKPromise transformHandler:rejectHandler]];
    };
}

- (CKPromise* (^)(dispatch_queue_t queue,
                                    id(^resolveHandler)(id value),
                                    id(^rejectHandler)(id reason)))queuedStrictThen {
    return ^CKPromise*(dispatch_queue_t queue, id resolveHandler, id rejectHandler) {
        return [self queuedStrictThen:queue :resolveHandler :rejectHandler];
    };
}

- (CKPromise*)queuedThen:(dispatch_queue_t)queue
                                  :(id)resolveHandler
                                  :(id)rejectHandler {
    return [self queuedStrictThen:queue
                                 :[CKPromise transformHandler:resolveHandler]
                                 :[CKPromise transformHandler:rejectHandler]];
}

- (CKPromise*)queuedStrictThen:(dispatch_queue_t)queue
                                        :(id(^)(id value))resolveHandler
                                        :(id(^)(id reason))rejectHandler {

    CKPromise *resultPromise = [CKPromise promise];
    
    CKPromiseCallbackWrapper successHandlerWrapper = ^(id value){
        dispatch_block_t blk = ^{
            @try{
                if(resolveHandler) {
                    [resultPromise resolve:resolveHandler(value)];
                }else {
                    [resultPromise resolve:value];
                }
            }@catch (NSException *ex) {
                [resultPromise reject:ex];
            }
        };
        dispatch_async(queue, blk);
    };
    
    CKPromiseCallbackWrapper rejectHandlerWrapper = ^(id reason){
        dispatch_block_t blk = ^{
            @try{
                if(rejectHandler) {
                    [resultPromise resolve:rejectHandler(reason)];
                } else {
                    [resultPromise reject:reason];
                }
            } @catch (NSException *ex) {
                [resultPromise reject:ex];
            }
        };
        dispatch_async(queue, blk);
    };
    
    @synchronized(self) {
        if(_state == CKPromiseStateResolved) {
            successHandlerWrapper(_valueOrReason);
        } else if(_state == CKPromiseStateRejected) {
            rejectHandlerWrapper(_valueOrReason);
        } else {
            _resolveHandlers.push_back(successHandlerWrapper);
            _rejectHandlers.push_back(rejectHandlerWrapper);
        }
    };
    return resultPromise;
}

- (CKPromise*(^)(id resolveHandler))success {
    return ^CKPromise*(id resolveHandler) {
        return [self then:resolveHandler :nil];
    };
}

- (CKPromise* __nonnull(^__nonnull)(id __nullable (^ __nonnull resolveHandler)(id __nullable value)))strictSuccess {
    return ^CKPromise*(id resolveHandler) {
        return [self then:resolveHandler :nil];
    };
}

- (CKPromise*)success:(id)resolveHandler {
    return [self then:resolveHandler :nil];
}

- (CKPromise* __nonnull)strictSuccess:(id __nullable (^ __nonnull)(id __nullable value))resolveHandler {
    return [self then:resolveHandler :nil];
}

- (CKPromise*(^)(id rejectHandler))failure {
    return ^CKPromise*(id rejectHandler) {
        return [self then:nil :rejectHandler];
    };
}

- (CKPromise* __nonnull(^__nonnull)(id __nullable (^ __nonnull rejectHandler)(id __nullable reason)))strictFailure {
    return ^CKPromise*(id rejectHandler) {
        return [self then:nil :rejectHandler];
    };
}

- (CKPromise*)failure:(id)rejectHandler {
    return [self then:nil :rejectHandler];
}

- (CKPromise* __nonnull)strictfailure:(id __nullable (^ __nonnull)(id __nullable reason))rejectHandler {
    return [self then:nil :rejectHandler];
}

- (CKPromise*(^)(void (^handler)()))always {
    return ^CKPromise*(id handler){
        return [self then:handler :handler];
    };
}

- (CKPromise*)always:(void(^)())handler {
    return [self then:handler :handler];
}

- (void)resolve:(id)value {
    @synchronized(self) {
        if(_state != CKPromiseStatePending) {
            @throw [CKHasResolutionException exception];
        }
        // 1. If promise and x refer to the same object, reject promise with a
        //    TypeError as the reason.
        if(value == self) {
            @throw [CKTypeErrorException exception];
        }
        
        //2. If x is a promise, adopt its state [3.4]:
        if([value isKindOfClass:CKPromise.class]) {
            //   i. If x is pending, promise must remain pending until x is fulfilled
            //      or rejected.
            //  ii. If/when x is fulfilled, fulfill promise with the same value.
            // iii. If/when x is rejected, reject promise with the same reason.
            [(CKPromise*)value then:^(id value) {
                [self resolve:value];
            } :^(id reason) {
                [self reject:reason];
            }];
            return;
        }
        
        // 3. Otherwise, if x is an object or function,
        // (this doesn't apply to Objective-C)
        
        // 4. If x is not an object or function, fulfill promise with x.
        _state = CKPromiseStateResolved;
        _valueOrReason = value;
    
        for(CKPromiseCallbackWrapper resolveHandler: _resolveHandlers){
                resolveHandler(_valueOrReason);
        }
        _resolveHandlers.clear();
        _rejectHandlers.clear();
    }
}

- (void)reject:(id)reason {
    @synchronized(self) {
        if(_state != CKPromiseStatePending){
            @throw [CKHasResolutionException exception];
        }
        _state = CKPromiseStateRejected;
        _valueOrReason = reason;
        for(CKPromiseCallbackWrapper rejectHandler: _rejectHandlers) {
                rejectHandler(_valueOrReason);
        }
        _resolveHandlers.clear();
        _rejectHandlers.clear();
    }
}

#pragma mark - Privates -

+ (NSMethodSignature*)methodSignatureForBlock:(id)block {
    struct CKBlockLiteral *blockRef = (__bridge struct CKBlockLiteral *)block;
    // skip tagged pointers and non-block objects
    if (((NSInteger)blockRef & 0x7) != 0x00 ||
        (blockRef->isa != (__bridge void *)heapBlockClass &&
        blockRef->isa != (__bridge void *)globalBlockClass &&
         blockRef->isa != (__bridge void *)stackBlockClass)) {
            return nil;
        }
    
    CKBlockDescriptionFlags flags = (CKBlockDescriptionFlags)blockRef->flags;
    NSMethodSignature *signature = nil;
    
    if (flags & CKBlockDescriptionFlagsHasSignature) {
        char *signatureLocation = (char*)blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);

        if (flags & CKBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }

        const char *sigStr = *(char**)signatureLocation;
        signature = [NSMethodSignature signatureWithObjCTypes:sigStr];
    }
    return signature;
}

+ (id(^)(id))transformHandler:(id)block {
    if(!block) return nil;
    
    NSMethodSignature *blockSignature = [self methodSignatureForBlock:block];
    if(!blockSignature) return nil;
    
    NSUInteger blockArgumentCount = blockSignature.numberOfArguments;
    const char *blockReturnType = blockSignature.methodReturnType;
    BOOL blockReturnsVoid = blockReturnType[0] == 'v';
    BOOL blockReturnsObject = blockReturnType[0] == '@';
    
    if(blockArgumentCount == 1) {
        if(blockReturnsVoid) {
            return ^id(id arg) {
                ((void(^)(void))block)();
                return nil;
            };
        } else if(blockReturnsObject) {
            return ^id(id arg) {
                return ((id(^)(void))block)();
            };
        }
    } else if(blockArgumentCount == 2) {
    #define buildBlock(type, selector)\
        if(blockReturnsVoid) {\
            return ^id(id val) {\
                ((void(^)(type))block)([val selector]);\
                return nil;\
            };\
        } else if(blockReturnsObject) {\
            return ^id(id val) {\
                return ((id(^)(type))block)([val selector]);\
            };\
        }\
        break;\

        switch([blockSignature getArgumentTypeAtIndex:1][0]) {
            case '@':
            case '#':
                if(blockReturnsVoid) {
                    return ^id(id val) {
                        ((void(^)(id))block)(val);
                        return nil;
                    };
                } else if(blockReturnsObject) {
                    return ^id(id val) {
                        return ((id(^)(id))block)(val);
                    };
                }
                break;
            case 'c':
            case 'C':
            case 'B':
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
            // the following types are not currently supported
            case '*':
            case ':':
            case '[':
            case '{':
            case 'b':
            case '^':
            default:
                break;
                
        }
    }
    
    // The block doesn't match any of the supported ones,
    // raise an exception
    @throw [CKInvalidHandlerException exception];
    return nil;
}

@end
