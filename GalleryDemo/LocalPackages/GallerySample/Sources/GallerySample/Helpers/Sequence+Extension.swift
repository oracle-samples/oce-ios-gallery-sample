// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation

extension Sequence {
    /// An async/await compatible version of map
    public func tryMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
    
    /// An async/await compatible version of flatMap
    public func flatMap<SegmentOfResult: Sequence>(_ transform: (Element) async throws -> SegmentOfResult) async rethrows -> [SegmentOfResult.Element] {
       var result: [SegmentOfResult.Element] = []
       for element in self {
         result.append(contentsOf: try await transform(element))
       }
       return result
     }
}
