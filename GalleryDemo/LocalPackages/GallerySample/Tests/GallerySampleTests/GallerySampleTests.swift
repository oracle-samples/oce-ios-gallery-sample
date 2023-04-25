// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import XCTest
@testable import GallerySample
import OracleContentCore
import OracleContentDelivery
import OracleContentTest
import Combine

/// Sample tests illustrating how network requests may be handled in several different ways
final class GallerySampleTests: XCTestCase {

    override func setUpWithError() throws {
        // Begin intercepting any requests made to the server
        URLProtocolMock.startURLOverride(timeout: 400)
    }

    override func tearDownWithError() throws {
        // Stop intercepting requests
        URLProtocolMock.stopURLOverride()
    }
    
    /// This test illustrates how a model (GalleryMainModel) can be tested by providing your own networking implementation
    /// This test validates that state eventually gets set to .done and that the items are populated with the data from your networking call
    func testGalleryMain_UsingNetworkingOverride() async throws {
        // ---------- ARRANGE -----------
        var cancellables = [AnyCancellable]()
        
        // Dependency injection
        let myNetworking = MyNetworking()
        let sut = GalleryMainModel(networking: myNetworking)

        let expectation = XCTestExpectation()
        
        // Subscribe to the model's state publisher and fulfill your expectation
        // when it receives a `.done` value
        sut.$state
            .filter { $0 == .done}
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // ---------- ACT -----------
        Task(priority: .high) {
            await sut.send(.fetchInitialData)
        }

        // ---------- ASSERT -----------
        self.wait(for: [expectation], timeout: 5)
        

        XCTAssertEqual(sut.items.count, 1)
        XCTAssertEqual(sut.items.first?.assets.count, 3)
        
    }
    
    /// This test validates the functionality of GalleryNetworking's fetchInitialData method
    /// It serves up requests from the JSON files provided.
    /// This can be useful when testing out complex responses.
    func testNetworking_UsingStaticResponses() async throws {
        // ---------- ARRANGE -----------
        // Enqueue responses from the static JSON files provided
        URLProtocolMock.enqueueStaticResponse(key: .taxonomies, filename: "taxonomies.json", bundle: .module)
        URLProtocolMock.enqueueStaticResponse(key: .taxonomyCategories, filename: "taxonomyCategories.json", bundle: .module)
        URLProtocolMock.enqueueStaticResponse(key: .items, filename: "assets.json", bundle: .module)
        
        // ---------- ACT -----------
        let sut = GalleryNetworking.instance
        let result = try await sut.fetchInitialData()

        // ---------- ASSERT -----------
        XCTAssertEqual(result.count, 1)
        
        let firstItem = try XCTUnwrap(result.first)
        XCTAssertEqual(firstItem.categoryName, "Breakfast")
        XCTAssertEqual(firstItem.assets.count, 12)
    }
    
    /// This test validates the functionality of GalleryNetworking's fetchInitialData method using
    /// dummy objects that you can create.
    func testNetworking_UsingMockedObjects() async throws {
        // ---------- ARRANGE -----------
        // Create dummy Taxonomies object containing a single dummy Taxonomy
        let taxonomies = Taxonomies()
        taxonomies.count = 1
        
        let t = Taxonomy()
        t.identifier = "123"
        taxonomies.items = [t]
        
        // Create dummy TaxonomyCategories object containing a single dummy TaxonomyCategory
        let taxonomyCategories = TaxonomyCategories()
        taxonomyCategories.count = 1
        let tc = TaxonomyCategory()
        tc.identifier = "456"
        tc.name = "Breakfast"
        taxonomyCategories.items = [tc]
        
        // Create dummy Assets object containing a single dummy Asset
        let assets = Assets()
        assets.count = 1
        
        let a = Asset()
        a.identifier = "789"
        assets.items = [a]
        
        // Enqueue the objects so they're used as responses for the appropriate services
        URLProtocolMock.enqueueDataResponse(key: .taxonomies, object: taxonomies)
        URLProtocolMock.enqueueDataResponse(key: .taxonomyCategories, object: taxonomyCategories)
        URLProtocolMock.enqueueDataResponse(key: .items, object: assets)
        
        // ---------- ACT -----------
        let sut = GalleryNetworking.instance
        let result = try await sut.fetchInitialData()

        // ---------- ASSERT -----------
        XCTAssertEqual(result.count, 1)
        
        let firstItem = try XCTUnwrap(result.first)
        XCTAssertEqual(firstItem.categoryName, "Breakfast")
        XCTAssertEqual(firstItem.assets.count, 1)
        
    }
    
//    func testMixture() async throws {
//        // ---------- ARRANGE -----------
//
//        var cancellables = [AnyCancellable]()
//        
//        // Enqueue responses from the static JSON files provided
//        URLProtocolMock.enqueueStaticResponse(key: .taxonomies, filename: "taxonomies.json", bundle: .module)
//        URLProtocolMock.enqueueErrorResponse(key: .taxonomyCategories, error:  OracleContentError.invalidDataReturned)
//        
//       
//        
//        let sut = GalleryMainModel()
//        
//        let expectation = XCTestExpectation()
//        
//        // Subscribe to the model's state publisher and fulfill your expectation
//        // when it receives a `.done` value
//        
//        var errorString: String?
//        
//        sut.$state
//            .compactMap { foundState in
//                switch foundState {
//                case .error(let foundErrorString):
//                    return foundErrorString
//                    
//                default:
//                    return nil
//                }
//            }
//            .sink { stringValue in
//                errorString = stringValue
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//        
//        // ---------- ACT -----------
//        Task(priority: .high) {
//            await sut.send(.fetchInitialData)
//        }
//
//        // ---------- ASSERT -----------
//        self.wait(for: [expectation], timeout: 5)
//        
//        XCTAssertNotNil(errorString)
//        XCTAssertEqual(errorString, OracleContentError.invalidDataReturned.localizedDescription)
//
//    }

}

/// Dummy implementation of the GalleryNetworkingProtocol which may be injected into a model instance.
private class MyNetworking: GalleryNetworkingProtocol {
    static var instance: GallerySample.GalleryNetworkingProtocol = MyNetworking()
    
    /// Return dummy GalleryCategory data instead of performing a real request to the server
    func fetchInitialData() async throws -> [GallerySample.GalleryCategory] {
        return [
            GalleryCategory(id: "123", categoryName: "foo", assets: [ Asset(), Asset(), Asset() ])
        ]
    }
    
    func downloadThumbnail(asset: OracleContentDelivery.Asset, cacheProvider: OracleContentCore.CacheProvider, cacheKey: String) async -> GallerySample.ThumbnailImageState {
        return .placeholder
    }
    
    func downloadMediumJPGRendition(for identifier: String, cacheProvider: OracleContentCore.CacheProvider, cacheKey: String) async -> GallerySample.CategoryAssetsMediumImageValue {
        return .none
    }
    
    func downloadPreview(identifier: String, cacheProvider: OracleContentCore.CacheProvider, cacheKey: String) async throws -> UIImage {
        return UIImage(systemName: "circle")!
    }
}
