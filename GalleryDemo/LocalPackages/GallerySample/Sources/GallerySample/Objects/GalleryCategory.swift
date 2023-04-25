// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import OracleContentDelivery

/// Object representing a taxonomy category and its related assets
/// Contains helper methods to help navigate through the collection of assets 
public struct GalleryCategory: Hashable {
    
    public var id: String = UUID().uuidString
    public var categoryName: String
    public var assets: [Asset]
    public var currentAsset = 0
    
    public init(id: String, categoryName: String, assets: [Asset]) {
        self.id = id
        self.categoryName = categoryName
        self.assets = assets
    }
    
    public init?(_ listing: [(String, String, Asset)]) {
        
        guard let name = listing.first?.0 else {
            return nil
        }
        
        self.categoryName = name
        self.assets = listing.map { $0.2 }
    }
    
    public func assetIndex(for index: Int) throws -> AssetIndex {
        if assets.isEmpty {
            throw ImagePreviewError.emptyAssetListing
        }
        
        let newIndex: Int = index < 0 ? 0 : index
        
        return AssetIndex(index: newIndex, asset: assets[newIndex], isFirst: newIndex == 0, isLast: newIndex == self.assets.count - 1)
    }
    
    public func nextIndex(after index: Int) throws -> AssetIndex {
        return try self.assetIndex(for: index + 1)
    }
    
    mutating public func previousIndex(before index: Int) throws -> AssetIndex {
        return try self.assetIndex(for: index - 1)
    }
}
