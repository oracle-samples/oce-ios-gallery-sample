// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import OracleContentCore

/// Implementation of OracleContentCore.LoggingProvider
/// For this sample, we're simply printing to the console
class MyLogger: LoggingProvider {
    func logError(_ message: String, file: String, line: UInt, function: String) {
        print(message)
    }
    
    func logNetworkResponseWithData(_ response: HTTPURLResponse?, data: Data?, file: String, line: UInt, function: String) {
        if let response = response {
            print(response)
        }
    }
    
    func logNetworkRequest(_ request: URLRequest?, session: URLSession?, file: String, line: UInt, function: String) {
        if let request = request,
           let url = request.url {
            print("Requesing: \(url)")
            
            if let headers = request.allHTTPHeaderFields {
                print("Headers: \(headers)")
            }
        }
    }
    
    func logDebug(_ message: String, file: String, line: UInt, function: String) {
        print(message)
    }
}

