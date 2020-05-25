/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import SwiftyJSON

/**
 * Given an array, return an array of slices of size `by` (possibly excepting the last slice).
 *
 * If `by` is longer than the input, returns a single chunk.
 * If `by` is less than 1, acts as if `by` is 1.
 * If the length of the array isn't a multiple of `by`, the final slice will
 * be smaller than `by`, but never empty.
 *
 * If the input array is empty, returns an empty array.
 */

public func chunk<T>(_ arr: [T], by: Int) -> [ArraySlice<T>] {
    var result = [ArraySlice<T>]()
    var chunk = -1
    let size = max(1, by)
    for (index, elem) in arr.enumerated() {
        if index % size == 0 {
            result.append(ArraySlice<T>())
            chunk += 1
        }
        result[chunk].append(elem)
    }
    return result
}

public extension Sequence {
    // [T] -> (T -> K) -> [K: [T]]
    // As opposed to `groupWith` (to follow Haskell's naming), which would be
    // [T] -> (T -> K) -> [[T]]
    func groupBy<Key, Value>(_ selector: (Self.Iterator.Element) -> Key, transformer: (Self.Iterator.Element) -> Value) -> [Key: [Value]] {
        var acc: [Key: [Value]] = [:]
        for x in self {
            let k = selector(x)
            var a = acc[k] ?? []
            a.append(transformer(x))
            acc[k] = a
        }
        return acc
    }

    func zip<S: Sequence>(_ elems: S) -> [(Self.Iterator.Element, S.Iterator.Element)] {
        var rights = elems.makeIterator()
        return self.compactMap { lhs in
            guard let rhs = rights.next() else {
                return nil
            }
            return (lhs, rhs)
        }
    }
}

/**
 * Return members of `a` that aren't nil, changing the type of the sequence accordingly.
 */
public func optFilter<T>(_ a: [T?]) -> [T] {
    return a.compactMap { $0 }
}

/**
 * Return a new map with only key-value pairs that have a non-nil value.
 */
public func optFilter<K, V>(_ source: [K: V?]) -> [K: V] {
    var m = [K: V]()
    for (k, v) in source {
        if let v = v {
            m[k] = v
        }
    }
    return m
}

/**
 * Take a JSON array, returning the String elements as an array.
 * It's usually convenient for this to accept an optional.
 */
public func jsonsToStrings(_ arr: [JSON]?) -> [String]? {
    return arr?.compactMap { $0.stringValue }
}

// Encapsulate a callback in a way that we can use it with NSTimer.
private class Callback {
    private let handler:() -> Void

    init(handler:@escaping () -> Void) {
        self.handler = handler
    }

    @objc
    func go() {
        handler()
    }
}

/**
 * Taken from http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call
 * Allows creating a block that will fire after a delay. Resets the timer if called again before the delay expires.
 **/
public func debounce(_ delay: TimeInterval, action:@escaping () -> Void) -> () -> Void {
    let callback = Callback(handler: action)
    var timer: Timer?

    return {
        // If calling again, invalidate the last timer.
        if let timer = timer {
            timer.invalidate()
        }
        timer = Timer(timeInterval: delay, target: callback, selector: #selector(Callback.go), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)
    }
}
