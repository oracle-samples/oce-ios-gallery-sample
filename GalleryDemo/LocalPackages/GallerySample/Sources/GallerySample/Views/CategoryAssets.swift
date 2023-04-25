// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import SwiftUI
import Combine
import OracleContentCore
import OracleContentDelivery

/// Gallery grid of assets in the taxonomy category
public struct CategoryAssets: View {

    @StateObject var model: CategoryAssetsModel
    @Binding var gallery: GalleryCategory
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    /// Controls the grid layout
    var vGridLayout: [GridItem] {
       [ GridItem(.adaptive(minimum: adaptiveSize)) ]
    }
    
    /// Provides different sizes based on the horizontalSizeClass environment value
    var adaptiveSize: CGFloat {
        if horizontalSizeClass == .regular && verticalSizeClass == .regular {
            return 250
        } else {
            return 90
        }
    }

    init(_ gallery: Binding<GalleryCategory>) {
        _model = StateObject(wrappedValue: CategoryAssetsModel(gallery: gallery))
        _gallery = gallery
    }
    
    public var body: some View {
        
        VStack {
            ScrollView {
                Text(model.ImageCountText)
                    .font(.title)
                    .foregroundColor(.gray)
                
                
                LazyVGrid(columns: vGridLayout, spacing: 5) {
                    ForEach(self.gallery.assets.indices, id: \.self) { index in
                        
                        NavigationLink(destination: GalleryPreview(gallery: self.$gallery, index: index)) {
                            
                            Rectangle()
                                .frame(minWidth: adaptiveSize, minHeight: adaptiveSize)
                                .foregroundColor(.clear)
                                .background(CategoryAssetGridItem(for: self.gallery.assets[index]))
                                .gridColumnAlignment(.leading)
                                .onAppear {
                                    self.model.send(.fetch(index))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(self.model.gallery.categoryName)
                        .font(.largeTitle)
                        .bold()
                }
            }
        }
    }
    
    @ViewBuilder
    func CategoryAssetGridItem(for asset: Asset) -> some View {
        switch self.model.mediumImages[asset.identifier] {
        case .some(let value):
            switch value {
            case .none:
               GridItemPlaceholder()
                
            case .image(let image):
                GridItemPreview(image)
                
            case .error:
                Color.red.opacity(0.3)
                    .clipped()
            }
            
        default:
            EmptyView()
        }
    }
}

/// Placeholder View used before the thumbnail has been downloaded
struct GridItemPlaceholder: View {
    
    @State var opacity: CGFloat = 0.3
    
    var body: some View {
        Color.blue.opacity(self.opacity)
            .clipped()
            .animation(.linear(duration: 0.1), value: self.opacity)
            .onDisappear {
                withAnimation {
                    self.opacity = 0.0
                }
            }
    }
}

/// Preview image used after the asset's rendition has been downloaded
struct GridItemPreview: View {
    
    @State var image: UIImage
    @State var opacity: CGFloat = 0.5
    
    init(_ image: UIImage) {
        _image = State(wrappedValue: image)
    }
    
    var body: some View {

        ZStack {
            Rectangle().aspectRatio(1.0, contentMode: .fit)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .layoutPriority(-1)
                .clipped()
                .opacity(self.opacity)
                .animation(.easeInOut, value: self.opacity)
                .onAppear {
                    withAnimation {
                        self.opacity = 1.0
                    }
                }
        }.clipped()
    
    }
}

