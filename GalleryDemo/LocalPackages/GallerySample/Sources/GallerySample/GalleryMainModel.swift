// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import OracleContentCore
import OracleContentDelivery
import UIKit

/// Possible Main UI states
enum CategoryListingState: Equatable {
    case loading
    case done
    case error(String)
}

/// Supported actions from GalleryMain
enum GalleryMainAction {
    case clearCache
    case refresh
    
    case fetchInitialData
    case reset
    case done
    case error(Error)
}

/// Thumbnail states
public enum ThumbnailImageState {
    case placeholder
    case image(UIImage)
    case error
}

enum GalleryModelError: Error {
    case noFetchPerformed
    case other(Error)
}

/// Model object that is responsible for executing the initial requests for data
///
/// Contains the collection of GalleryCategory objects
class GalleryMainModel: ObservableObject {
    
    /// The collection of GalleryCategory objects that will make up the main listing
    @Published var items: [GalleryCategory] = []
    @Published var state: CategoryListingState = .loading
    
    /// Controls whether to display an alert indicating that the cache has been cleared
    @Published var cacheIsCleared = false 
    
    /// Object that controls networking. Assigned through dependency injection
    private var networking: GalleryNetworkingProtocol
    
    /// The CacheProvider used. Assigned through dependency injection
    private var cacheProvider: GalleryFileCache
    
    /// Initializer
    ///
    /// - parameter networking: An implementation of GalleryNetworkingProtocol. Default value will be GalleryNetworking.instance
    /// - parameter cacheProvidcer: An implementation of CacheProvider. Default value will be GalleryFileCache.instance
    init(networking: GalleryNetworkingProtocol = GalleryNetworking.instance, cacheProvider: GalleryFileCache = GalleryFileCache.instance) {
        self.networking = networking
        self.cacheProvider = cacheProvider
    }
    
    /// Communication from the view to the model is handled by sending actions
    /// Whenever possible, state is modified from this method
    @MainActor
    func send(_ action: GalleryMainAction)  {
        switch action {
            
        case .refresh:
            self.cacheProvider.clear()
            self.send(.reset)
            self.send(.fetchInitialData)
            
        case .clearCache:
            self.cacheProvider.clear()
            self.cacheIsCleared = true
            
        case .fetchInitialData:
            self.state = .loading
            Task {
                do {
                    let values = try await self.fetchInitialData()
                    if !values.isEmpty {
                        self.items = values
                    }
                    self.send(.done)
                } catch GalleryModelError.noFetchPerformed {
                    self.send(.done)
                } catch {
                    print(error)
                    self.send(.error(error))
                }
            }
            
        case .reset:
            self.items.removeAll()
            
        case .done:
            self.state = .done
            
        case .error(let error):
            self.state = .error(error.localizedDescription)
        }
    }
    
    @MainActor
    func fetchInitialData() async throws -> [GalleryCategory] {
        
        guard items.isEmpty else {
            throw GalleryModelError.noFetchPerformed
        }
        
        return try await self.networking.fetchInitialData()
    }
}
