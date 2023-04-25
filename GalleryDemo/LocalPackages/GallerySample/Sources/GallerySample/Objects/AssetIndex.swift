// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import OracleContentDelivery

/// Temporary structure used to help determine whether an asset is the first or last in the collection
public struct AssetIndex {
    let index: Int
    let asset: Asset
    let isFirst: Bool
    let isLast: Bool
}
