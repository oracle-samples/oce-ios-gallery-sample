// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import UIKit
import SwiftUI
import OracleContentDelivery

/// Actions supported by the image preview
public enum ImagePreviewAction {
    case previous
    case next
    case fetch(Int)
    case preview(AssetIndex)
    case finishedDownload(UIImage)
    case error(Error)
}

/// Errors returned while displaying or navigating preview
public enum ImagePreviewError: Error {
    case assetNotFound
    case endOfAssetListing
    case startOfAssetListing
    case emptyAssetListing
}

/// State of the preview itself
public enum ImagePreviewState {
    case loading
    case done(UIImage)
    case error(Error)
}

/// Model object that is responsible for downloading the preview
public class GalleryPreviewModel: ObservableObject {
    
    /// Contains the asset to preview
    @Binding var gallery: GalleryCategory
    
    /// Publishers used to control whether the preview/next buttons are displayed on the preivew
    @Published var showPreviousButton: Bool = false
    @Published var showNextButton: Bool = false
    
    /// Publisher which determines whether the error property should be shown
    @Published var showError = false
    @Published var error: Error!
    
    /// The state of UI
    @Published var state: ImagePreviewState = .loading
    
    /// Object that controls networking. Assigned through dependency injection
    private var networking: GalleryNetworkingProtocol
    
    /// The CacheProvider used. Assigned through dependency injection
    private var cacheProvider: GalleryFileCache
    private var currentIndex: Int = 0
    
    /// Used to ensure that we can show a loading indicator when network requests take a long time
    private var timer: Timer!
    
    /// Initializer 
    /// - parameter gallery: Binding<GalleryCategroy>. Contains asset to preview
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
    public func send(_ action: ImagePreviewAction) {
        switch action {
        case .previous:
            do {
                self.showError = false
                self.error = nil
                let foundIndex = try self.gallery.previousIndex(before: self.currentIndex)
                self.send(.preview(foundIndex))
            } catch let error {
                self.error = error
                self.showError = true
            }
            
        case .next:
            do {
                self.showError = false
                self.error = nil
                let foundIndex = try self.gallery.nextIndex(after: self.currentIndex)
                self.send(.preview(foundIndex))
            } catch let error {
                self.error = error
            }
            
        case .fetch(let indexToRetreive):
            do {
                self.showError = false
                self.error = nil
                let foundIndex = try self.gallery.assetIndex(for: indexToRetreive)
                self.send(.preview(foundIndex))
            } catch let error {
                self.error = error
            }
            
        case .preview(let index):
            
            self.timer?.invalidate()
            
            self.showPreviousButton = !index.isFirst
            self.showNextButton = !index.isLast
            self.currentIndex = index.index
            
            // If an image can be retrieved quickly, SwiftUI animation will handle the transition from the previous image to the next
            // However, if network conditions result in a more-lengthy download, we need to a way to indicate that the download is in progress.
            // Here will initialize our timer that (unless cancelled) will set the state to .loading in 0.75 seconds
            // In the happy path, the preview image will be obtained in less than that amount of time and the timer will be invalidated
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false) { _ in
                DispatchQueue.main.async {
                    self.state = .loading
                }
            }
            
            self.downloadPreview(for: index.asset)
            
        case .finishedDownload(let image):
            self.timer?.invalidate()
            self.state = .done(image)

        case .error(let error):
            self.timer?.invalidate()
            self.error = error
            self.showError = true
        }
    }
    
    public var previewCounterText: String {
        return "\(self.currentIndex + 1) / \(self.gallery.assets.count)"
    }
    
    @MainActor
    func downloadPreview(for asset: Asset) {
        Task {
            do {
                let image = try await self.networking
                                          .downloadPreview(identifier: asset.identifier,
                                                           cacheProvider: self.cacheProvider,
                                                           cacheKey: "\(asset.identifier)_native")
                
                self.send(.finishedDownload(image))
            } catch {
                self.send(.error(error))
            }
        }
    }
}
