// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import OracleContentCore

/// URLProvider implementation
///
/// Modify the file credentials.json to provide a server URL and channel token for your Oracle Content Management instance
/// - important: This class must be assigned to the Onboarding.urlProvider property. In this sample, the assignment is made in the main application code's initializer
public class MyURLProvider: URLProvider {
    
    private static var credentials: Credentials = {
        guard let filePath = Bundle.main.path(forResource: "credentials", ofType: "json"),
              let data = FileManager.default.contents(atPath: filePath) else {
            return Credentials()
        }
        
        guard let credentials = try? JSONDecoder().decode(Credentials.self, from: data) else {
            return Credentials()
        }
        
        return credentials
    }()
    
    /// Used to decode the data contained in credentials.json
    private struct Credentials: Codable {
        var url: String = ""
        var channelToken: String = ""
    }
    
    /// This function provides the URL to be used for each OracleContentCore request
    ///
    /// Services which implement ``OracleContentCore.ImplementsOverrides`` may provide a different URL and
    /// authorization headers (if required) on a call-by-call basis
    public var url: () -> URL? = {
        return URL(string: MyURLProvider.credentials.url)
    }
    
    /// This function will provide additional header values to be used for each OracleContentCore request.
    /// In this sample, no additional headers are required so an empty dictionary is returned
    ///
    /// Services which implement ``OracleContentCore.ImplementsAdditionaHeaders`` may provide additional header values
    /// on a call-by-call basis
    public var headers: () -> [String : String] = {
        [:]
    }
    
    /// This function provides the delivery channel token to be used for each OracleContentCore request
    ///
    /// Services which implement ``OracleContentCore.ImplementsChannelToken`` may override this value
    /// on a call-by-call basis
    public var deliveryChannelToken: () -> String? = {
        
        return MyURLProvider.credentials.channelToken
    }
}



