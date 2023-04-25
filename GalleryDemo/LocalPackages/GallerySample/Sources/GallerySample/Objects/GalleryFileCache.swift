// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import SwiftUI
import OracleContentCore


/// Errors that may be encountered when implementing your own `CacheProvider`
public enum GalleryCacheError: Error {
    case cachedItemNotFound
    case unableToStoreDownloadInCache
}

/// This is the cache that is used to keep track of files which have been downloaded.
/// The cache is keyed by an asset's identifier and usage type (i.e., "CONTF8BA4DDD3FEC41AA864F0B137CCAB207\_thumbnail")
/// The corresponding cache value is the filename of the object. (i.e., "shutterstock_153479393(2)_thumbnail.png")
///
/// The dictionary that associates keys with filenames is located in the file, "ImageCache.json"
/// The files themselves are persisted to the "savedFiles" folder inside the application's "Documents" folder
public class GalleryFileCache: ObservableObject, Codable {
    
    public static var instance = GalleryFileCache()
    
    /// This is the file that maintains the dictionary mapping "keys" to paths on devices
    static let fileLocation = FileManager.default
                                         .urls(for: .documentDirectory, in: .userDomainMask)[0]
                                         .appendingPathComponent("ImageCache.json")
    
    /// This is the location that downloaded files are stored on-device
    public static let deviceCacheLocation = FileManager
        .default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("savedFiles")
    
    /// The in-memory representation of the cache
    /// The key is the identifier of an asset
    /// The value is the location on device where that asset has been downloaded
    internal var items: [String: String]
    
    private init() {
        
        // Create directories
        do {
            var isDir : ObjCBool = true
            if FileManager.default.fileExists(atPath: GalleryFileCache.deviceCacheLocation.path, isDirectory: &isDir) {
                
                // This should not happen - where a FILE exists with the name of the expected FOLDER
                if !isDir.boolValue {
                    try FileManager.default.removeItem(at: GalleryFileCache.deviceCacheLocation)
                    try FileManager.default.createDirectory(at: GalleryFileCache.deviceCacheLocation, withIntermediateDirectories: true)
                }
            } else {
                // Create the folder into which we will persist downloaded files
                try FileManager.default.createDirectory(at: GalleryFileCache.deviceCacheLocation, withIntermediateDirectories: true)
            }
        } catch let error {
            // We should never hit this code
            fatalError("Unexpected error initializing the device cache location. Error: \(error)")
        }
        
        if let cache = GalleryFileCache.read() {
            self.items = cache
        } else {
            self.items = [:]
        }
    }
}

public extension GalleryFileCache {
    
    /// Obtain the persisted cache values
    static func read() -> [String: String]? {
        do {
            let data = try Data(contentsOf: GalleryFileCache.fileLocation)
            let persistedValues = try JSONDecoder().decode([String: String].self, from: data)
            return persistedValues
        } catch {
            Onboarding.logError(error.localizedDescription)
            return nil
        }
    }

    /// Saves a downloaded file into the cache and updates the JSON listing associating the file identifier with the filename
    static func saveDownloadedFile(key: String, downloadedFileURL: URL) throws -> URL {
        // move the file from the tmp directory to the saved files directory
        let downloadedFilename = downloadedFileURL.lastPathComponent
        let newURL = self.deviceCacheLocation.appendingPathComponent(downloadedFilename)
        
        if FileManager.default.fileExists(atPath: newURL.path) {
            try FileManager.default.removeItem(at: newURL)
        }

        try FileManager.default.moveItem(at: downloadedFileURL, to: newURL)
       
        // persist the permanent file location in the cache
        GalleryFileCache.instance.items[key] = downloadedFilename

        GalleryFileCache.instance.write()
        
        return newURL
    }
    
    /// Returns the URL for the cached file corresponding to the requested key
    static func cachedItem(key: String) -> URL? {
        if let foundValue = GalleryFileCache.instance.items[key] {
            let url = GalleryFileCache.deviceCacheLocation.appendingPathComponent(foundValue)
            return url
        } else {
            return nil
        }
    }
    
    func write() {
        
        guard let data = try? JSONEncoder().encode(self.items) else { return }
        
        do {
            try data.write(to: GalleryFileCache.fileLocation)
        } catch {
            Onboarding.logError(error.localizedDescription)
        }
        
    }
    
    func clear() {
        
        let jsonData = "{ }".data(using: .utf8)!
        do {
            try jsonData.write(to: GalleryFileCache.fileLocation)
            self.items = [:]
            
            try FileManager.default.removeItem(at: GalleryFileCache.deviceCacheLocation)
            
            try FileManager.default.createDirectory(at: GalleryFileCache.deviceCacheLocation, withIntermediateDirectories: true)
            
        } catch {
            Onboarding.logError(error.localizedDescription)
        }
    }
}

// MARK: CacheProvider conformance
/**
 While this could be a separate object entirely, here we just conform our existing cache to the CacheProvider protocol.
 The purpose of the CacheProvider conformance is to allow the Oracle Content libraries to interface directly with our cache, saving lots of manual coding work
 */
extension GalleryFileCache: CacheProvider {
    
    /// Our cache is designed to bypass any requests to the server when a cached item is found
    public var cachePolicy: CachePolicy {
        .bypassServerCallOnFoundItem
    }
   
    /// This cache neither requires nor utilizes any special request/response headers
    public func headerValues(for cacheKey: String) -> [String : String] {
       
        return [:]
    }

    /// This method is called by OracleContentCore to determine whether a download request should short-circuit
    public func find(key: String) -> URL? {
        return GalleryFileCache.cachedItem(key: key)
    }
    
    /// This method should not be called in this example.
    /// It's purpose is to handle 304 responses received by download requests so a URL may ultimately be returned
    /// instead of an error.
    ///
    /// For purposes of this sample, we'll just throw an error
    public func cachedItem(key: String) throws -> URL {
        throw GalleryCacheError.cachedItemNotFound
    }
    
    /// Called by OracleContentCore after a download has occurred. This allows us to store the URL in our cache.
    /// Had this cache utilized any header information, those values could be extracted at this point.
    public func store(objectAt file: URL, key: String, headers: [AnyHashable : Any]) throws -> URL {
        
        let newURL = try GalleryFileCache.saveDownloadedFile(key: key, downloadedFileURL: file)
        return newURL
    }
}
