// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import SwiftUI
import OracleContentCore

/// Available actions for the CategoryAssetsModel
public enum CategoryAssetsAction {
    case fetch(Int)
}

/// Possible values for the image displayed
public enum CategoryAssetsMediumImageValue: Equatable {
    case none
    case error
    case image(UIImage)
}

open class CategoryAssetsModel: ObservableObject {
    
    /// Contains the assets to be displayed
    @Binding public var gallery: GalleryCategory
    @Published public var mediumImages = [String: CategoryAssetsMediumImageValue]()
    
    /// The CacheProvider used. Assigned through dependency injection
    private let cacheProvider: GalleryFileCache
    
    /// Object that controls networking. Assigned through dependency injection
    private let networking: GalleryNetworkingProtocol
    
    /// Initializer
    ///
    /// - parameter gallery: Binding<GalleryCategroy>. Contains the assets to be displayed
    /// - parameter networking: An implementation of GalleryNetworkingProtocol. Default value will be GalleryNetworking.instance
    /// - parameter cacheProvidcer: An implementation of CacheProvider. Default value will be GalleryFileCache.instance
    public init(gallery: Binding<GalleryCategory>, networking: GalleryNetworkingProtocol = GalleryNetworking.instance, cacheProvider: GalleryFileCache = GalleryFileCache.instance) {
        _gallery = gallery
        self.networking = networking
        self.cacheProvider = cacheProvider 
        
        // Convert a collection of Assets into a dictionary keyed by the asset identifier
        mediumImages = self.gallery.assets.reduce([String: CategoryAssetsMediumImageValue](), { partialResult, asset in
            var newDict = partialResult
            newDict[asset.identifier] = CategoryAssetsMediumImageValue.none
            return newDict
        })
    }
    
    /// Communication from the view to the model is handled by sending actions
    /// Whenever possible, state is modified from this method
    @MainActor
    public func send(_ action: CategoryAssetsAction) {
        switch action {
        case .fetch(let index):
           
            guard index >= 0,
                  index < gallery.assets.count else {
                return
            }
            
            let identifier = self.gallery.assets[index].identifier
            
            Task {
                self.mediumImages[identifier] = await self.fetchImage(for: identifier)
            }
        }
    }
    
    /// Formats the text indicating the number of assets in the taxonomy category
    public var ImageCountText: String {
        switch gallery.assets.count {
        case 1:
            return "1 image"
            
        default:
            return "\(self.gallery.assets.count) Images"
        }
    }
    
    /// Retrieve the "Medium" rendition of the asset
    @MainActor
    internal func fetchImage(for identifier: String) async -> CategoryAssetsMediumImageValue {
        
        return await self.networking
                         .downloadMediumJPGRendition(for: identifier,
                                                     cacheProvider: self.cacheProvider,
                                                     cacheKey: "\(identifier)_medium")
    }
}
