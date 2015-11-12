//
//  CKPromise-Swift.swift
//  Pods
//
//  Created by Cristian Kocza on 29/10/15.
//
//

import Foundation
import CKPromise

public class CKSwiftPromise {
    private var objcPromise: CKPromise
    
    public class func resolvedWith(value: AnyObject) -> CKSwiftPromise {
        return CKSwiftPromise(objcPromise: CKPromise.resolvedWith(value))
    }
    
    public class func rejectedWith(value: AnyObject) -> CKSwiftPromise {
        return CKSwiftPromise(objcPromise: CKPromise.rejectedWith(value))
    }
    
    public class func when(promises: [CKSwiftPromise]) -> CKSwiftPromise {
        return CKSwiftPromise(objcPromise: CKPromise.when(promises.map({$0.objcPromise})))
    }
       
    public init() {
        objcPromise = CKPromise()
    }
    
    private init(objcPromise: CKPromise) {
        self.objcPromise = objcPromise
    }
    
    public func resolve(value: AnyObject?) {
        objcPromise.resolve(value)
    }
    
    public func reject(value: AnyObject?) {
        objcPromise.reject(value)
    }
    
    public func then(success: ()->Void) -> CKSwiftPromise{
        return then(
            {(value:AnyObject?) -> AnyObject? in success(); return nil},
            failure: nil
        )
    }
    
    public func then(success: ()->AnyObject?) -> CKSwiftPromise{
        return then(
            {(value:AnyObject?) -> AnyObject? in return success()},
            failure: nil
        )
    }
    
    public func then(success: (value: AnyObject?)->Void) -> CKSwiftPromise{
        return then(
            {(value:AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: nil
        )
    }
    
    public func then(success: (value: AnyObject?)->AnyObject?) -> CKSwiftPromise {
        return then(success, failure: nil)
    }
    
    public func then(success: ()->Void, failure: ()->Void) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in success(); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(); return nil}
        )
    }
    
    public func then(success: ()->Void, failure: ()->AnyObject?) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in success(); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure()}
        )
    }
    
    public func then(success: ()->Void, failure: (reason: AnyObject?)->Void) -> CKSwiftPromise {
        return then(
            {(value: AnyObject?) -> AnyObject? in success(); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(reason: reason); return nil}
        )
    }
    
    public func then(success: ()->Void, failure: (reason: AnyObject?)->AnyObject?) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in success(); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure(reason: reason)}
        )
    }
    
    public func then(success: ()->AnyObject?, failure: ()->Void) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in return success()},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(); return nil}
        )
    }
    
    public func then(success: ()->AnyObject?, failure: ()->AnyObject?) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in return success()},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure()}
        )
    }
    
    public func then(success: ()->AnyObject?, failure: (reason: AnyObject?)->Void) -> CKSwiftPromise {
        return then(
            {(value: AnyObject?) -> AnyObject? in return success()},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(reason: reason); return nil}
        )
    }
    
    public func then(success: ()->AnyObject?, failure: (reason: AnyObject?)->AnyObject?) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in return success()},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure(reason: reason)}
        )
    }
    
    public func then(success: (value: AnyObject?)->Void, failure: ()->Void) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(); return nil}
        )
    }
    
    public func then(success: (value: AnyObject?)->Void, failure: ()->AnyObject?) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure()}
        )
    }
    
    public func then(success: (value: AnyObject?)->Void, failure: (reason: AnyObject?)->Void) -> CKSwiftPromise {
        return then(
            {(value: AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(reason: reason); return nil}
        )
    }
    
    public func then(success: (value: AnyObject?)->Void, failure: (reason: AnyObject?)->AnyObject?) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure(reason: reason)}
        )
    }
    
    public func then(success: (value: AnyObject?)->AnyObject?, failure: ()->Void) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in return success(value: value)},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(); return nil}
        )
    }
    
    public func then(success: (value: AnyObject?)->AnyObject?, failure: ()->AnyObject?) -> CKSwiftPromise {
        return then(
            {(value:AnyObject?) -> AnyObject? in return success(value: value)},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure()}
        )
    }
    
    public func then(success: (value: AnyObject?)->AnyObject?, failure: (reason: AnyObject?)->Void) -> CKSwiftPromise {
        return then(
            {(value: AnyObject?) -> AnyObject? in return success(value: value)},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(reason: reason); return nil}
        )
    }
    
    public func then(success: ((object: AnyObject?)->AnyObject?)?, failure: ((reason: AnyObject?)->AnyObject?)?) -> CKSwiftPromise {
        return CKSwiftPromise(objcPromise: objcPromise.strictThen(success, failure))
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->Void) -> CKSwiftPromise{
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in success(); return nil},
            failure: nil
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->AnyObject?) -> CKSwiftPromise{
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in return success()},
            failure: nil
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->Void) -> CKSwiftPromise{
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: nil
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->AnyObject?) -> CKSwiftPromise {
        return queuedThen(queue, success: success, failure: nil)
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->Void, failure: ()->Void) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in success(); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(); return nil}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->Void, failure: ()->AnyObject?) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in success(); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure()}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->Void, failure: (reason: AnyObject?)->Void) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value: AnyObject?) -> AnyObject? in success(); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(reason: reason); return nil}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->Void, failure: (reason: AnyObject?)->AnyObject?) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in success(); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure(reason: reason)}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->AnyObject?, failure: ()->Void) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in return success()},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(); return nil}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->AnyObject?, failure: ()->AnyObject?) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in return success()},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure()}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->AnyObject?, failure: (reason: AnyObject?)->Void) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value: AnyObject?) -> AnyObject? in return success()},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(reason: reason); return nil}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ()->AnyObject?, failure: (reason: AnyObject?)->AnyObject?) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in return success()},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure(reason: reason)}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->Void, failure: ()->Void) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(); return nil}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->Void, failure: ()->AnyObject?) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure()}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->Void, failure: (reason: AnyObject?)->Void) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value: AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(reason: reason); return nil}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->Void, failure: (reason: AnyObject?)->AnyObject?) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in success(value: value); return nil},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure(reason: reason)}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->AnyObject?, failure: ()->Void) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in return success(value: value)},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(); return nil}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->AnyObject?, failure: ()->AnyObject?) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value:AnyObject?) -> AnyObject? in return success(value: value)},
            failure: {(reason: AnyObject?) -> AnyObject? in return failure()}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: (value: AnyObject?)->AnyObject?, failure: (reason: AnyObject?)->Void) -> CKSwiftPromise {
        return queuedThen(queue,
            success: {(value: AnyObject?) -> AnyObject? in return success(value: value)},
            failure: {(reason: AnyObject?) -> AnyObject? in failure(reason: reason); return nil}
        )
    }
    
    public func queuedThen(queue: dispatch_queue_t, success: ((object: AnyObject?)->AnyObject?)?, failure: ((reason: AnyObject?)->AnyObject?)?) -> CKSwiftPromise {
        return CKSwiftPromise(objcPromise: objcPromise.queuedStrictThen(queue, success, failure))
    }
}