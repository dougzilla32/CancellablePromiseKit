//
//  Error.swift
//  CancelForPromiseKit
//
//  Created by Doug on 4/28/18.
//

import PromiseKit

public class PromiseCancelledError: CancellableError, CustomDebugStringConvertible {
    public init(file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
        let fileBasename = URL(fileURLWithPath: "\(file)").lastPathComponent
        debugDescription = "'\(type(of: self)) at \(fileBasename) \(function):\(line)'"
    }
    
    public var isCancelled: Bool {
        return true
    }
    
    public var debugDescription: String
}

extension PromiseCancelledError: LocalizedError {
    public var errorDescription: String? {
        return debugDescription
    }
}

class ErrorConditions {
    enum Severity {
        case warning, error
    }

    static func cancelContextMissingInChain(className: String, functionName: String, severity: Severity = .error, file: StaticString, function: StaticString, line: UInt) {
        let fileBasename = URL(fileURLWithPath: "\(file)").lastPathComponent
        let message = """
        \(className).\(functionName): the cancel context is missing from the previous link in the cancel chain at \(fileBasename) \(function):\(line).
        Be sure to use the 'CC' varient for all PromiseKit functions in the cancel chain, and for custom Promises be sure to specify the 'cancel: CancelContext' initializer parameter.
        
        """
        switch severity {
        case .warning:
            print("*** WARNING *** \(message)")
        case .error:
            assert(false, message, file: file, line: line)
            print("*** ERROR *** \(message)")
        }
    }

    static func cancelContextMissingFromBody(className: String, functionName: String, severity: Severity = .error, file: StaticString, function: StaticString, line: UInt) {
        let fileBasename = URL(fileURLWithPath: "\(file)").lastPathComponent
        let message = """
        \(className).\(functionName): the cancel context is missing from the promise returned by the closure at \(fileBasename) \(function):\(line).
        Be sure to use the 'CC' varient for all PromiseKit functions in the cancel chain, and for custom Promises be sure to specify the 'cancel: CancelContext' initializer parameter.
        
        """
        switch severity {
        case .warning:
            print("*** WARNING *** \(message)")
        case .error:
            assert(false, message, file: file, line: line)
            print("*** ERROR *** \(message)")
        }
    }
}

func rawPointerDescription(obj: AnyObject) -> String {
    let id = ObjectIdentifier(obj)
    let idDesc = id.debugDescription
    let index = idDesc.index(idDesc.startIndex, offsetBy: "\(type(of: id))".count)
#if swift(>=3.2)
    let pointerString = idDesc[index...]
#else
    let pointerString = idDesc.substring(from: index)
#endif
    return "\(type(of: obj))\(pointerString)"
}

extension Optional {
    public var optionalDescription: Any {
        switch self {
        case .none:
            return "nil"
        case let .some(value):
            return value
        }
    }
}
