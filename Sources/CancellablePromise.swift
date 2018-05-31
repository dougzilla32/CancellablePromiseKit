//
//  CancellablePromise.swift
//  CancelForPromiseKit
//
//  Created by Doug Stein on 4/28/18.
//

import PromiseKit

public class CancellablePromise<T>: CancellableThenable, CancellableCatchMixin {
    public let promise: Promise<T>
    
    public typealias U = Promise<T>
    
    public var thenable: U {
        return promise
    }

    public typealias M = Promise<T>
    
    public var catchable: M {
        return promise
    }
    
    init(_ promise: Promise<T>, context: CancelContext? = nil) {
        self.promise = promise
        self.cancelContext = context ?? CancelContext()
    }
    
    /// Initialize a new rejected cancellable promise.
    public convenience init(error: Error) {
        self.init(Promise(error: error))
    }
    
    /// Initialize a new cancellable promise bound to the provided `Thenable`.
    public convenience init<U: Thenable>(_ bridge: U) where U.T == T {
        self.init(Promise(bridge))
    }
    
    /// Initialize a new cancellable promise that can be resolved with the provided `Resolver`.
    public convenience init(resolver body: (Resolver<T>) throws -> Void) {
        self.init(Promise(resolver: body))
    }
    
    /// Initialize a new cancellable promise with a cancellable task that can be resolved with the provided `Resolver`.
    public convenience init(task: CancellableTask, resolver body: @escaping (Resolver<T>) throws -> Void) {
        var reject: ((Error) -> Void)!
        self.init { seal in
            reject = seal.reject
            try body(seal)
        }
        self.appendCancellableTask(task: task, reject: reject)
    }
    
    /// Initialize a new cancellable promise with a cancellable task and rejected with the provided error.
    public convenience init(task: CancellableTask, error: Error) {
        var reject: ((Error) -> Void)!
        self.init { seal in
            reject = seal.reject
            seal.reject(error)
        }
        self.appendCancellableTask(task: task, reject: reject)
    }

    /// - Returns: a tuple of a new cancellable pending promise and its `Resolver`.
    public class func pending() -> (promise: CancellablePromise<T>, resolver: Resolver<T>) {
        let rp = Promise<T>.pending()
        return (promise: CancellablePromise(rp.promise), resolver: rp.resolver)
    }
    
    /// - Returns: a new fulfilled cancellable promise.
    public class func value(_ value: T) -> CancellablePromise<T> {
        var reject: ((Error) -> Void)!
        
        let promise = Promise<T> { seal in
            reject = seal.reject
            seal.fulfill(value)
        }
        
        let cp = CancellablePromise(promise)
        cp.appendCancellableTask(task: nil, reject: reject)
        return cp
    }

    /// Internal function required for `Thenable` conformance.
    public func pipe(to: @escaping (Result<T>) -> Void) {
        promise.pipe(to: to)
    }
    
    /// - Returns: The current `Result` for this cancellable promise.
    public var result: Result<T>? {
        return promise.result
    }

    /**
     Immutably and asynchronously inspect the current `Result`:
     
        promise.tap{ print($0) }.then{ /*…*/ }
     */
    public func tap(_ body: @escaping(Result<T>) -> Void) -> CancellablePromise {
        _ = promise.tap(body)
        return self
    }
    
    /**
     Blocks this thread, so—you know—don’t call this on a serial thread that
     any part of your chain may use. Like the main thread for example.
     */
    public func wait() throws -> T {
        return try promise.wait()
    }
}

#if swift(>=3.1)
extension CancellablePromise where T == Void {
    /// Initializes a new promise fulfilled with `Void`
    public convenience init() {
        self.init(Promise())
    }

    public convenience init(task: CancellableTask) {
        self.init()
        self.appendCancellableTask(task: task, reject: nil)
    }
}
#endif

public extension DispatchQueue {
    /**
     Asynchronously executes the provided closure on a dispatch queue.

         DispatchQueue.global().async(.promise) {
             try md5(input)
         }.done { md5 in
             //…
         }

     - Parameter body: The closure that resolves this promise.
     - Returns: A new `Promise` resolved by the result of the provided closure.
     */
    @available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *)
    final func asyncCC<T>(_: PMKNamespacer, group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], execute body: @escaping () throws -> T) -> CancellablePromise<T> {
        let rp = CancellablePromise<T>.pending()
        async(group: group, qos: qos, flags: flags) {
            if let error = rp.promise.cancelContext.cancelledError {
                rp.resolver.reject(error)
            } else {
                do {
                    rp.resolver.fulfill(try body())
                } catch {
                    rp.resolver.reject(error)
                }
            }
        }
        return rp.promise
    }
}
