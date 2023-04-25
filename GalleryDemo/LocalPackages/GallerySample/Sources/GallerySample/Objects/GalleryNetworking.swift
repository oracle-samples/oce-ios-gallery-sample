// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import OracleContentCore
import OracleContentDelivery
import UIKit

/// Protocol defining the methods supported in this demo
/// Having a protocol makes for an easier time when you want to provide a custom implementation
public protocol GalleryNetworkingProtocol {
    static var instance: GalleryNetworkingProtocol { get set }
    
    func fetchInitialData() async throws -> [GalleryCategory]
    func downloadThumbnail(asset: Asset, cacheProvider: CacheProvider, cacheKey: String) async -> ThumbnailImageState
    func downloadMediumJPGRendition(for identifier: String, cacheProvider: CacheProvider, cacheKey: String) async -> CategoryAssetsMediumImageValue
    func downloadPreview(identifier: String, cacheProvider: CacheProvider, cacheKey: String) async throws -> UIImage
}

/// The networking implementation for this demo. It conforms to the GalleryNetworkingProtocol.
/// The class is marked as public rather than open because subclassing is not really an option. The static variable "instance" cannot be overridden in a subclass
public class GalleryNetworking: GalleryNetworkingProtocol, ObservableObject {
    
    private var downloadNativeService: DownloadCacheProviderNative!
    
    public static var instance: GalleryNetworkingProtocol = GalleryNetworking.init()
    
    private init() { }
    
    /// Retrieves the assets for each taxonomy category in each taxonomy
    /// Illustrates how multiple requests may be made one after the other
    /// - throws: Error
    /// - returns: [GalleryCategory]
    @MainActor
    public func fetchInitialData() async throws -> [GalleryCategory] {
        
        // First find the list of available taxonomies
        // In this demo, we're limiting the number of responses to 50
        let taxonomies = try await DeliveryAPI
            .listTaxonomies()
            .limit(50)
            .fetchNextAsync()

        // For each taxonomy, retrieve the collection of taxonomy categories
        // Utilizes the standard "map" functionality to create a collection of
        // tasks to be executed - one for each taxonomy.
        // It then utilizes a custom flatMap operator to execute each task concurrently
        let taxonomyCategories = try await taxonomies
            .items
            .map(createListTaxonomyCategoriesTask(for:))        // standard map functionality
            .flatMap { task in                                  // custom flatMap in Sequence+Extension
                // execute each task concurrently
                try await task.value
            }
        
        // Retrieve the list of assets for each category
        // Convert the collection of assets into a Gallery object.
        // Utilizes standard map functionality to create a collection
        // of tasks to be executed.
        // It then utilizes a custom tryMap operator execute each task concurrently
        let galleries = try await taxonomyCategories
            .map(createGalleryCategoryTask(for:))               // standard map functionality
            .tryMap { task in                                   // custom tryMap in Sequence+Extension
                try await task.value
            }
            .sorted(by: { left, right in
                left.categoryName < right.categoryName
            })
    
        return galleries
    }
    
    /// Returns a task that wraps an async request to list the taxonomy categories for a taxonomy
    ///
    /// Each Task returned will ultimately be executed by an async/await flatMap operation.
    /// While this code could be inlined inside the flatMap, having this function makes the call-site much cleaner
    /// - parameter taxonomy: The Taxonomy for which to fetch taxonomy categories
    /// - returns: Task<[TaxonomyCateory>, Error>
    internal func createListTaxonomyCategoriesTask(for taxonomy: Taxonomy) -> Task<[TaxonomyCategory], Error> {
        Task {
            try await DeliveryAPI
                .listTaxonomyCategories(taxonomyId: taxonomy.identifier)
                .limit(50)
                .order(.name(.asc))
                .fetchNextAsync()
                .items
        }
    }
    
    /// Returns a task that wraps an async request to list the assets for a given taxonomy category
    ///
    /// Each task returned will ultimately be executed by an async/await tryMap operation
    /// While this code could be inlined inside the tryMap, having this function makes the call-site much cleaner
    /// - parameter for: The taxonomy category for which assets should be retrieved
    /// - returns: Task<GalleryCategory, Error>
    internal func createGalleryCategoryTask(for taxonomyCategory: TaxonomyCategory) -> Task<GalleryCategory, Error> {
        Task {
            Onboarding.logDebug("GALLERY DEMO: - START Fetching assets for tc \(taxonomyCategory.identifier)")
        
            let idNode = QueryNode.equal(field: "taxonomies.categories.nodes.id", value: taxonomyCategory.identifier)
            let typeNode = QueryNode.equal(field: "type", value: "Image")
            let query = QueryBuilder(node: idNode).and(typeNode)
            
            let assets = try await DeliveryAPI
                .listAssets()
                .query(query)
                .fields(.all)  // need the fileGroup field to download the thumbnail
                .limit(100)
                .fetchNextAsync()
            
            Onboarding.logDebug("GALLERY DEMO: - END Fetching assets for tc \(taxonomyCategory.identifier)")
            
            return GalleryCategory(id: taxonomyCategory.identifier, categoryName: taxonomyCategory.name, assets: assets.items)
        }
    }
    
    /// Downloads the thumbnail rendition for the specified asset
    ///
    /// - parameter asset: The asset whose rendition will be downloaded
    /// - parameter cacheProvider: The CacheProvider implementation to use
    /// - parameter cacheKey: The key for the rendition in cache
    /// - returns: UIImage? 
    public func downloadThumbnail(
        asset: Asset,
        cacheProvider: CacheProvider,
        cacheKey: String
    ) async -> ThumbnailImageState {

        do {
            let downloadResult = try await DeliveryAPI
                .downloadThumbnail(
                    identifier: asset.identifier,
                    fileGroup: asset.fileGroup,
                    cacheProvider: cacheProvider,
                    cacheKey: "\(asset.identifier)_thumbnail"
                )
                .downloadAsync(progress: nil)

            if let image = UIImage(contentsOfFile: downloadResult.result.path) {
                return .image(image)
            } else {
                Onboarding.logError(OracleContentError.couldNotCreateImageFromURL(downloadResult.result).localizedDescription)
                return .error
            }

        } catch {
            Onboarding.logError(error.localizedDescription)
            return .error
        }
    }
    
    /// Downloads the rendition named "Medium" with a a JPG format
    /// - parameter for: The identifier of the asset
    /// - parameter cacheProvider: The CacheProvider implementation to use
    /// - parameter cacheKey: The key for the rendition in cache
    /// - returns CategoryAssetsMediumImageValue
    public func downloadMediumJPGRendition(
        for identifier: String,
        cacheProvider: CacheProvider,
        cacheKey: String
    ) async -> CategoryAssetsMediumImageValue {
        do {
            let downloadResult = try await DeliveryAPI
                .downloadRendition(identifier: identifier,
                                   renditionName: "Medium",
                                   cacheProvider: cacheProvider,
                                   cacheKey: cacheKey,
                                   format: "jpg")
                .downloadAsync(progress: nil)
            
            if let image = UIImage(contentsOfFile: downloadResult.result.path) {
                return .image(image)
            } else {
                Onboarding.logError("Could not obtain image from path")
                return .error
            }
           
        } catch {
            Onboarding.logError(error.localizedDescription)
            return .error
        }
    }
    
    /// Downloads the native file to use for previews
    /// - parameter identifier: The identifier of the asset
    /// - parameter cacheProvider: The CacheProvider implementation to use
    /// - parameter cacheKey: The key for the rendition in cache 
    public func downloadPreview(
        identifier: String,
        cacheProvider: CacheProvider,
        cacheKey: String
    ) async throws -> UIImage {
        
        downloadNativeService?.cancel()
        
        downloadNativeService = DeliveryAPI
            .downloadNative(identifier: identifier,
                            cacheProvider: cacheProvider,
                            cacheKey: cacheKey)
         
        let downloadResult = try await downloadNativeService.downloadAsync(progress: nil)
            
        guard let image = UIImage(contentsOfFile: downloadResult.result.path) else {
            throw ImagePreviewError.assetNotFound
        }
        
        return image
    }
}
