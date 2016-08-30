//
//  PromiseQueue.swift
//  PinkyPromise
//
//  Created by Kevin Conner on 8/19/16.
//
//  The MIT License (MIT)
//  Copyright © 2016 WillowTree, Inc. All rights reserved.
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

import Foundation

// A FIFO queue that runs one Promise at a time.

public final class PromiseQueue<T> {

    public typealias Value = T

    private var runningPromise: Promise<Value>?
    private var remainingPromises: [Promise<Value>] = []

    public init() {}

    // Create a promise that enqueues many promises and completes when the last has finished.
    public func batch(promises: [Promise<Value>]) -> Promise<[Value]> {
        return Promise { fulfill in
            var results: [Result<Value>] = []

            guard let lastPromise = promises.last else {
                fulfill(zipArray(results))
                return
            }

            for promise in promises.dropLast() {
                promise
                    .result { result in
                        results.append(result)
                    }
                    .enqueue(in: self)
            }

            lastPromise
                .result { result in
                    results.append(result)
                    fulfill(zipArray(results))
                }
                .enqueue(in: self)
        }
    }

    // MARK: Helpers

    // Enqueue a promise. It will run when no others remain ahead of it in the queue.
    private func add(promise: Promise<Value>) {
        remainingPromises.append(promise)

        continueIfIdle()
    }

    // Run the next promise if there is one, and if none is already running.
    private func continueIfIdle() {
        guard runningPromise == nil, let promise = remainingPromises.first else {
            return
        }

        remainingPromises.removeFirst()
        runningPromise = promise

        promise.call { _ in
            self.runningPromise = nil
            self.continueIfIdle()
        }
    }

}

public extension Promise {

    // Use instead of .call to enqueue a promise for running in turn with others.
    public func enqueue(in queue: PromiseQueue<Value>) {
        queue.add(self)
    }
    
}