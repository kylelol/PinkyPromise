//
//  AnyPromise.swift
//  PinkyPromise_iOS
//
//  Created by Will Ellis on 5/2/18.
//

import Foundation

@objc public enum AnyResultEnum: Int {
    case success
    case failure
}

@objc public class AnyResult: NSObject {
    @objc let value: Any?
    @objc let error: Error?

    @objc public init(value: Any?) {
        self.value = value
        self.error = nil
        super.init()
    }

    @objc public init(error: Error) {
        self.value = nil
        self.error = error
        super.init()
    }

    var asResult: Result<Any?> {
        guard let error = error else {
            return .success(value)
        }
        return .failure(error)
    }
}

extension Result {
    var asAnyResult: AnyResult {
        switch self {
        case .success(let value):
            return AnyResult(value: value)
        case .failure(let error):
            return AnyResult(error: error)
        }
    }
}

public typealias AnyObserver = (AnyResult) -> Void

func getObserverFrom(anyObserver: @escaping (AnyResult) -> Void) -> (Result<Any?>) -> Void {
    return { (result: Result<Any?>) -> Void in
        anyObserver(result.asAnyResult)
    }
}

func getAnyObserverFrom(observer: @escaping (Result<Any?>) -> Void) -> (AnyResult) -> Void {
    return { (anyResult: AnyResult) -> Void in
        observer(anyResult.asResult)
    }
}

func getTaskFrom(anyTask: @escaping (@escaping (AnyResult) -> Void) -> Void) -> (@escaping (Result<Any?>) -> Void) -> Void {
    return { (observer: @escaping (Result<Any?>) -> Void) -> Void in
        let anyObserver = getAnyObserverFrom(observer: observer)
        anyTask(anyObserver)
    }
}

@objc public class AnyPromise: NSObject {
    private let promise: Promise<Any?>
    
    @objc public init(anyTask: @escaping (@escaping (AnyResult) -> Void) -> Void) {
        promise = Promise(task: getTaskFrom(anyTask: anyTask))
        super.init()
    }

    @objc public func call(completion: ((AnyResult) -> Void)?) {
        guard let anyObserver = completion else {
            promise.call()
            return
        }
        let observer = getObserverFrom(anyObserver: anyObserver)
        promise.call(completion: observer)
    }

}
