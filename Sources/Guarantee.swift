//
//  Guarantee.swift
//  CancelForPromiseKit
//
//  Created by Doug on 5/10/18.
//

import PromiseKit

public extension Guarantee {
    public convenience init(cancel: CancelContext, task: CancellableTask? = nil, resolver body: (@escaping(T) -> Void) -> Void) {
        self.init(resolver: body)
        self.cancelContext = cancel
        cancel.append(task: task, reject: nil, description: GuaranteeDescription(self))
    }
    
    public class func pendingCC(cancel: CancelContext? = nil) -> (promise: Promise<T>, resolver: Resolver<T>) {
        return Promise<T>.pendingCC()
    }

    public var cancelContext: CancelContext? {
        get {
            return objc_getAssociatedObject(self, &CancelContextKey.cancelContext) as? CancelContext
        }
        set(newValue) {
            objc_setAssociatedObject(self, &CancelContextKey.cancelContext, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func cancel(error: Error? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        cancelContext?.cancel(error: error, file: file, function: function, line: line)
    }
    
    @discardableResult
    func doneCC(on: DispatchQueue? = conf.Q.return, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, _ body: @escaping(T) -> Void) -> Promise<Void> {
        if self.cancelContext == nil {
            ErrorConditions.cancelContextMissing(className: "Guarantee", functionName: "doneCC", file: file, function: function, line: line)
        }
        
        let cancelBody = { (value: T) throws -> Void in
            if let error = self.cancelContext?.cancelledError {
                throw error
            } else {
                body(value)
            }
        }
        
        let promise = self.done(on: on, cancelBody)
        promise.cancelContext = self.cancelContext
        return promise
    }
    
    func mapCC<U>(on: DispatchQueue? = conf.Q.map, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, _ body: @escaping(T) -> U) -> Promise<U> {
        if self.cancelContext == nil {
            ErrorConditions.cancelContextMissing(className: "Guarantee", functionName: "mapCC", file: file, function: function, line: line)
        }
        
        let cancelBody = { (value: T) throws -> U in
            if let error = self.cancelContext?.cancelledError {
                throw error
            } else {
                return body(value)
            }
        }
        
        let promise = self.map(on: on, cancelBody)
        promise.cancelContext = self.cancelContext
        return promise
    }
    
    @discardableResult
    func thenCC<U>(on: DispatchQueue? = conf.Q.map, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, _ body: @escaping(T) -> Guarantee<U>) -> Promise<U> {        
        let cancelBody = { (value: T) throws -> Guarantee<U> in
            if let error = self.cancelContext?.cancelledError {
                throw error
            } else {
                let rv = body(value)
                if let selfContext = self.cancelContext, let rvContext = rv.cancelContext {
                    selfContext.append(context: rvContext)
                } else if let rvContext = rv.cancelContext {
                    self.cancelContext = rvContext
                } else {
                    ErrorConditions.cancelContextMissing(className: "Guarantee", functionName: "thenCC", file: file, function: function, line: line)
                }
                return rv
            }
        }
        
        let promise = self.then(on: on, file: file, line: line, cancelBody)
        promise.cancelContext = self.cancelContext
        return promise
    }
}

#if swift(>=3.1)
public extension Guarantee where T == Void {
    convenience init(cancel: CancelContext, task: CancellableTask? = nil) {
        self.init()
        self.cancelContext = cancel
        cancel.append(task: nil, reject: nil, description: GuaranteeDescription(self))
    }
}
#endif

public extension DispatchQueue {
    /**
     Asynchronously executes the provided closure on a dispatch queue.

         DispatchQueue.global().asyncCC(.promise) {
             md5(input)
         }.doneCC { md5 in
             //…
         }

     - Parameter cancel: The cancel context to use for this promise.
     - Parameter body: The closure that resolves this promise.
     - Returns: A new `Guarantee` resolved by the result of the provided closure.
     */
    @available(macOS 10.10, iOS 2.0, tvOS 10.0, watchOS 2.0, *)
    final func asyncCC<T>(_: PMKNamespacer, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], cancel: CancelContext? = nil, execute body: @escaping () -> T) -> Promise<T> {
        let rp = Guarantee<T>.pendingCC()
        async(group: group, qos: qos, flags: flags) {
            if let error = rp.promise.cancelContext?.cancelledError {
                rp.resolver.reject(error)
            } else {
                rp.resolver.fulfill(body())
            }
        }
        rp.promise.cancelContext = cancel ?? CancelContext()
        return rp.promise
    }
}
