//
//  Thenable.swift
//  CancelForPromiseKit
//
//  Created by Doug on 5/11/18.
//

import PromiseKit

struct CancelContextKey {
    public static var cancelContext: UInt8 = 0
}

extension Thenable {
    var cancelContext: CancelContext? {
        get {
            return objc_getAssociatedObject(self, &CancelContextKey.cancelContext) as? CancelContext
        }
        set(newValue) {
            objc_setAssociatedObject(self, &CancelContextKey.cancelContext, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func cancel(error: Error? = nil, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        cancelContext?.cancel(error: error, file: file, function: function, line: line)
    }
    
    var isCancelled: Bool {
        return cancelContext?.isCancelled ?? false
    }
    
    var cancelAttempted: Bool {
        return cancelContext?.cancelAttempted ?? false
    }
    
    var cancelledError: Error? {
        return cancelContext?.cancelledError
    }

    func thenCC<U: Thenable>(on: DispatchQueue? = conf.Q.map, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, _ body: @escaping(T) throws -> U) -> Promise<U.T> {
        if self.cancelContext == nil {
            ErrorConditions.cancelContextMissingInChain(className: "Promise", functionName: "thenCC", file: file, function: function, line: line)
            self.cancelContext = CancelContext()
        }
        
        let cancelBody = { (value: T) throws -> U in
            if let error = self.cancelContext?.cancelledError {
                throw error
            } else {
                let rv = try body(value)
                if let rvContext = rv.cancelContext {
                    self.cancelContext?.append(context: rvContext)
                } else {
                    ErrorConditions.cancelContextMissingFromBody(className: "Promise", functionName: "thenCC", file: file, function: function, line: line)
                }
                // TODO: remove the CancelItem for this promise from the CancelContext
                return rv
            }
        }

        let promise = self.then(on: on, file: file, line: line, cancelBody)
        promise.cancelContext = self.cancelContext
        return promise
    }
    
    func mapCC<U>(on: DispatchQueue? = conf.Q.map, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, _ transform: @escaping(T) throws -> U) -> Promise<U> {
        if self.cancelContext == nil {
            ErrorConditions.cancelContextMissingInChain(className: "Promise", functionName: "mapCC", file: file, function: function, line: line)
            self.cancelContext = CancelContext()
        }
        
        let cancelTransform = { (value: T) throws -> U in
            if let error = self.cancelContext?.cancelledError {
                throw error
            } else {
                // TODO: remove the CancelItem for this promise from the CancelContext
                return try transform(value)
            }
        }
        
        let promise = self.map(on: on, cancelTransform)
        promise.cancelContext = self.cancelContext
        return promise
    }
    
    func compactMapCC<U>(on: DispatchQueue? = conf.Q.map, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, _ transform: @escaping(T) throws -> U?) -> Promise<U> {
        if self.cancelContext == nil {
            ErrorConditions.cancelContextMissingInChain(className: "Promise", functionName: "compactMapCC", file: file, function: function, line: line)
            self.cancelContext = CancelContext()
        }
        
        let cancelTransform = { (value: T) throws -> U? in
            if let error = self.cancelContext?.cancelledError {
                throw error
            } else {
                // TODO: remove the CancelItem for this promise from the CancelContext
                return try transform(value)
            }
        }
        
        let promise = self.compactMap(on: on, cancelTransform)
        promise.cancelContext = self.cancelContext
        return promise
    }
    
    func doneCC(on: DispatchQueue? = conf.Q.return, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, _ body: @escaping(T) throws -> Void) -> Promise<Void> {
        if self.cancelContext == nil {
            ErrorConditions.cancelContextMissingInChain(className: "Promise", functionName: "doneCC", file: file, function: function, line: line)
            self.cancelContext = CancelContext()
       }
        
        let cancelBody = { (value: T) throws -> Void in
            if let error = self.cancelContext?.cancelledError {
                throw error
            } else {
                // TODO: remove the CancelItem for this promise from the CancelContext
                try body(value)
            }
        }
        
        let promise = self.done(on: on, cancelBody)
        promise.cancelContext = self.cancelContext
        return promise
    }
    
    func getCC(on: DispatchQueue? = conf.Q.return, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, _ body: @escaping (T) throws -> Void) -> Promise<T> {
        if self.cancelContext == nil {
            ErrorConditions.cancelContextMissingInChain(className: "Promise", functionName: "getCC", file: file, function: function, line: line)
            self.cancelContext = CancelContext()
        }

        return mapCC(on: on) {
            try body($0)
            return $0
        }
    }
}

extension Optional where Wrapped: DispatchQueue {
    func async(_ body: @escaping() -> Void) {
        switch self {
        case .none:
            body()
        case .some(let q):
            q.async(execute: body)
        }
    }
}
