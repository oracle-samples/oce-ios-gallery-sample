// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import OracleContentDelivery
import SwiftUI

/// Available UI states for a GalleryCategoryCard
public enum GalleryCardModelAction {
    case fetch
}

/// Model object responsible for obtaining the images used by a CategoryCard
public class GalleryCategoryCardModel: ObservableObject {
    
    /// The gallery category which contains the name and assets to be displayed on the card
    @Binding public var gallery: GalleryCategory

    /// The larger image of the card
    @Published public var heroImage: ThumbnailImageState = .placeholder
    
    /// The collection of smaller thumbnail images on the card
    @Published public var thumbnailImages = [ThumbnailImageState]()

    /// Object that controls networking. Assigned through dependency injection
    private var networking: GalleryNetworkingProtocol
    
    /// The CacheProvider used. Assigned through dependency injection
    private let cacheProvider: GalleryFileCache

    /// Initializer
    /// - parameter gallery: Binding<GalleryCategroy>. Contains the name and assets to be displayed on the card
    /// - parameter networking: An implementation of GalleryNetworkingProtocol. Default value will be GalleryNetworking.instance
    /// - parameter cacheProvidcer: An implementation of CacheProvider. Default value will be GalleryFileCache.instance
    init(_ gallery: Binding<GalleryCategory>, networking: GalleryNetworkingProtocol = GalleryNetworking.instance, cacheProvider: GalleryFileCache = GalleryFileCache.instance) {
        _gallery = gallery
        self.networking = networking
        self.cacheProvider = cacheProvider
    }
    
    /// Communication from the view to the model is handled by sending actions
    /// Whenever possible, state is modified from this method
    @MainActor
    public func send(_ action: GalleryCardModelAction) {
        switch action {
        case .fetch:
            Task {
                self.heroImage = await fetchHeroImageAsync()
            }

            self.thumbnailImages.append(.placeholder)
            self.thumbnailImages.append(.placeholder)
            self.thumbnailImages.append(.placeholder)

            self.gallery.assets
                .indices
                .filter { idx in
                    idx > 0 && idx < 4
                }.forEach { idx in
                    self.fetchThumbnailImageAsync(idx)
                }
        }
    }
    
    public var CategoryName: String {
        gallery.categoryName
    }

    public var ImageCountText: String {
        switch gallery.assets.count {
        case 1:
            return "1 image"

        default:
            return "\(self.gallery.assets.count) Images"
        }
    }

    public func showThumbnailImage(_ index: Int) -> ThumbnailImageState {
        
        if self.thumbnailImages.isEmpty || self.thumbnailImages.count <= index {
            return .placeholder
        } else {
            return self.thumbnailImages[index]
        }
    }

    @MainActor
    internal func fetchThumbnailImageAsync(_ index: Int) {
        guard gallery.assets.count >= index else {
            return
        }

        let thumbnailAsset = self.gallery.assets[index]

        Task {
            let image = await networking
                .downloadThumbnail(
                    asset: thumbnailAsset,
                    cacheProvider: self.cacheProvider,
                    cacheKey: "\(thumbnailAsset.identifier)_thumbnail"
                )
            
            self.thumbnailImages[index - 1] = image
        }
    }

    @MainActor
    internal func fetchHeroImageAsync() async -> ThumbnailImageState {
        guard !gallery.assets.isEmpty else {
            return .error
        }

        let heroAsset = gallery.assets[0]

        let image = await networking
            .downloadThumbnail(
                asset: heroAsset,
                cacheProvider: self.cacheProvider,
                cacheKey: "\(heroAsset.identifier)_thumbnail"
            )
        
        return image
       
    }
}
