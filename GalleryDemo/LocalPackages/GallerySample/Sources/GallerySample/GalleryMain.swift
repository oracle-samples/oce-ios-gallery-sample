// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import SwiftUI
import OracleContentCore
import Combine 

/// Main container view for the Gallery Demo
/// This view will utilize it's model object to retrieve information about taxonomies, taxonomy categories and associated assets
/// Cache may be cleared either by clicking the "gear" icon or by performing a pull-to-refresh action on the grid
///
/// Data is requested when the View appears by sending a `.fetchGalleryListing` action to the model
public struct GalleryMain: View {
    
    @StateObject var model: GalleryMainModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    public init() {
        _model = StateObject(wrappedValue: GalleryMainModel())
    }
    
    /// Provides grid layout information based on the \.horizontalSizeClass Environment value
    private var vGridLayout: [GridItem] {
       
        if horizontalSizeClass == .compact {
           return [ GridItem(.adaptive(minimum: 200))]
        } else {
            // Use flexible layouts so that the grid remains centered in the view
            return [
                GridItem(.flexible(minimum: 200)),
                GridItem(.flexible(minimum: 200)),
                GridItem(.flexible(minimum: 200))
            ]
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack {
                
                switch self.model.state {
                case .loading:
                    CustomSpinner(labelText: "Loading")
                    
                case .error(let errorText):
                    Text(errorText)
                    
                case .done:
                    ScrollView {
                        LazyVGrid(columns: vGridLayout, spacing: 50) {
                            ForEach(self.$model.items, id: \.self) { gallery in
                                GalleryCategoryCard(gallery)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        self.model.send(.refresh)
                    }
                    
                }
            }
            .padding(.top, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Image Gallery")
                        .font(.title)
                        .bold()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            self.model.send(.clearCache)
                        }
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(Color(uiColor: ColorFunctions.hexColor(0xBB0000)))
                    }
                    .buttonStyle(.plain)
                }
            }
       
        }
        .alert("Cache has been cleared", isPresented: self.$model.cacheIsCleared) {
            Button("OK", role: .none) {  }
        }
        .navigationViewStyle(.stack)
        .task {
            self.model.send(.fetchInitialData)
        }
    }
    
}

struct GalleryMain_Previews: PreviewProvider {
    
    public class MyURLProvider: URLProvider {
        
        public var url: () -> URL? = {
            return URL(string: "https://headless.mycontentdemo.com")!
        }
        
        public var headers: () -> [String : String] = {
            [:]
        }
        
        public var deliveryChannelToken: () -> String? = {
            "e0b6421e73454818948de7b1eaddb091"
        }
    }
    
    static var previews: some View {
        MyView()
    }
    
    struct MyView: View {
        init() {
            Onboarding.urlProvider = MyURLProvider()
        }
        
        var body: some View {
            GalleryMain()
        }
    }
}

