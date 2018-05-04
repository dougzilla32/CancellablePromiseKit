//
//  CancellablePromise.swift
//  CancellablePromiseKit
//
//  Created by Doug on 4/28/18.
//  Copyright © 2018 Doug Stein. All rights reserved.
//

import Foundation
import PromiseKit

// MARK: Cancellable Tasks

public protocol CancellableTask {
    func cancel()
    
    var isCancelled: Bool { get }
}

open class DispatchWorkItemTask: CancellableTask {
    var task: DispatchWorkItem?
    
    init() { }
    
    init(_ task: DispatchWorkItem) {
        self.task = task
    }
    
    public func cancel() {
        // Invoke the work item now, causing it to error out with a cancellation error
        task?.perform()
        
        // Cancel the work item so that it doesn't get invoked later.  'perform' must be called before 'cancel', otherwise the perform will get ignored.
        task?.cancel()
    }
    
    public var isCancelled: Bool {
        get {
            return task?.isCancelled ?? false
        }
    }
}

// MARK: Cancel Context

public enum CancelType {
    case enable
    case disable
    case context(CancelContext)
    
    public static func createContext() -> CancelType {
        return CancelType.context(CancelContext())
    }
    
    public func cancelAll(file: String = #file, function: String = #function, line: Int = #line) {
        switch self {
        case .context(let context):
            context.cancelAll(file: file, function: function, line: line)
        case .enable, .disable:
            break
        }
    }
}

public class CancelContext {
    private var cancelFunctions = [(String, String, Int) -> Void]()
    
    fileprivate init() { }
    
    func add(cancel: @escaping (String, String, Int) -> Void) {
        cancelFunctions.append(cancel)
    }
    
    public func cancelAll(file: String = #file, function: String = #function, line: Int = #line) {
        for cancel in cancelFunctions {
            cancel(file, function, line)
        }
    }
}

// MARK: Promise extensions

public extension Promise {
    public class func value(_ value: T, cancel: CancelType) -> Promise<T> {
        if case .disable = cancel {
            return Promise.value(value)
        }
        
        let task = DispatchWorkItemTask()
        var reject: ((Error) -> Void)?
        
        let promise = Promise<T> { seal in
            reject = seal.reject
            Swift.print("SEAL ME valueWithCancel")
//            task.task = DispatchWorkItem() {
            seal.fulfill(value)
//            }
//            Swift.print("SET WORK ITEM HOLDER \(task)")
//            DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime.now() + 0.001, execute: task.task!)
        }
        
        if case .context(let context) = cancel {
            context.add(cancel: promise.cancel)
        }
        promise.cancellableTask = task
        promise.cancelReject = reject
        return promise
    }
    
    public convenience init(task: CancellableTask, cancel: CancelType, resolver body: @escaping (Resolver<T>) throws -> Void) {
        var reject: ((Error) -> Void)?
        if case .disable = cancel {
            self.init(resolver: body)
            return
        }

        self.init() { seal in
            reject = seal.reject
            Swift.print("SEAL ME CancellableTask")
            do {
                try body(seal)
            } catch {
                seal.reject(error)
            }
        }
        
        if case .context(let context) = cancel {
            context.add(cancel: self.cancel)
        }
        self.cancellableTask = task
        self.cancelReject = reject
    }
    
    public func cancel(file: String = #file, _ function: String = #function, line: Int = #line) {
        Swift.print("try cancel")
        cancelAttempted = true
        cancelReject?(PromiseCancelledError(file: file, function: function, line: line))
        cancellableTask?.cancel()
   }
    
    public var isCancelled: Bool {
        get {
            if let cancelItem = cancellableTask {
                return cancelItem.isCancelled
            } else {
                return false
            }
        }
    }
    
    public var isCancellable: Bool {
        get {
            return cancellableTask != nil
        }
    }

    public var cancellableTask: CancellableTask? {
        get {
            return objc_getAssociatedObject(self, &CancellablePromiseAssociatedKeys.cancellableTask) as? CancellableTask
        }
        set {
            objc_setAssociatedObject(self, &CancellablePromiseAssociatedKeys.cancellableTask, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var cancelAttempted: Bool {
        get {
            return (objc_getAssociatedObject(self, &CancellablePromiseAssociatedKeys.cancelAttempted) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &CancellablePromiseAssociatedKeys.cancelAttempted, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var cancelReject: ((Error) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &CancellablePromiseAssociatedKeys.cancelReject) as? (Error) -> Void
        }
        set {
            objc_setAssociatedObject(self, &CancellablePromiseAssociatedKeys.cancelReject, newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

struct CancellablePromiseAssociatedKeys {
    static var cancellableTask: UInt8 = 0
    static var cancelAttempted: UInt8 = 0
    static var cancelReject: UInt8 = 0
}
