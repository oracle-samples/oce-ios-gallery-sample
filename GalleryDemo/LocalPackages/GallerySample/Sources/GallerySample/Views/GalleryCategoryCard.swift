// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import SwiftUI
import OracleContentCore
import OracleContentDelivery

/// The overview card representing a taxonomy category
public struct GalleryCategoryCard: View {
    
    @StateObject var model: GalleryCategoryCardModel
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var gridItemThumbnailSquareSize: CGSize {
        if self.horizontalSizeClass == .regular &&
            self.verticalSizeClass == .regular {
            return CGSize(width: 95, height: 95)
        } else {
            return CGSize(width: 60, height: 60)
        }
    }
    
    var cardSize: CGSize {
        if self.horizontalSizeClass == .regular &&
            self.verticalSizeClass == .regular {
            return CGSize(width: 300, height: 300)
        } else {
            return CGSize(width: 200, height: 200)
        }
    }
    
    public init(_ gallery: Binding<GalleryCategory>) {
        _model = StateObject(wrappedValue: GalleryCategoryCardModel(gallery))
    }
    
    public var body: some View {
        
        // Show all of the thumbnails for the assets in a category
        NavigationLink(destination: CategoryAssets(self.$model.gallery)) {
            VStack {
                
                GalleryCardGrid
                
                Text(self.model.CategoryName)
                    .font(.largeTitle)
                
                Text(model.ImageCountText)
                    .font(.headline).foregroundColor(.gray)
            }
            .task {
                self.model.send(.fetch)
            }
        }.buttonStyle(.plain)
    }
}

// MARK: ViewBuilders
extension GalleryCategoryCard {
    @ViewBuilder
    var GalleryCardGrid: some View {
        
        Grid(verticalSpacing: 4) {
            
            GridRow {

                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.clear)
                    .overlay(HeroImage())

            }.gridCellColumns(3)
            
            GridRow {
                if self.model.gallery.assets.count >= 3 {
                    RoundedRectangle(cornerRadius: 8.0)
                        .overlay(ThumbnailImage(index: 0))
                        
                    RoundedRectangle(cornerRadius: 8.0)
                        .overlay(ThumbnailImage(index: 1))
                        
                    RoundedRectangle(cornerRadius: 8.0)
                        .overlay(ThumbnailImage(index: 2))
                }
            }
            .foregroundColor(.clear)
            .background(.gray.opacity(0.1))
            .gridColumnAlignment(.leading)
            .frame(width: self.gridItemThumbnailSquareSize.width, height: self.gridItemThumbnailSquareSize.height)
        }
        .frame(width: self.cardSize.width, height: self.cardSize.height)
        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
        .environmentObject(self.model)
    }
}

/// Main image for a CategoryCard
struct HeroImage: View {
    
    @EnvironmentObject var model: GalleryCategoryCardModel
    @State var imageOpacity = 0.4
    
    var body: some View {
        switch self.model.heroImage {
            
        case .placeholder:
            Color.blue.opacity(0.3)
                .clipped()
            
        case .image(let image):
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(self.imageOpacity)
                .animation(.easeIn, value: self.imageOpacity)
                .onAppear {
                    withAnimation {
                        self.imageOpacity = 1.0
                    }
                }
            
        case .error:
            Image(systemName: "questionmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .padding()
                .frame(width: 65, height: 65)
        }
    }
}

/// Smaller image for the 3 lower thumbnails in a CategoryCard
struct ThumbnailImage: View {
    @EnvironmentObject var model: GalleryCategoryCardModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var imageSize: CGSize {
        if self.horizontalSizeClass == .regular &&
            self.verticalSizeClass == .regular {
            return CGSize(width: 95, height: 95)
        } else {
            return CGSize(width: 65, height: 65)
        }
    }
    
    var index: Int
    
    var body: some View {
            ZStack {
                switch self.model.showThumbnailImage(index) {
                case .placeholder:

                    Color.blue.opacity(0.3)
                        .clipped()

                case .image(let image):

                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imageSize.width, height: imageSize.height)
                    
                case .error:
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding()
                        .frame(width: imageSize.width, height: imageSize.height)
                }
            }
            .clipped()
            .aspectRatio(1, contentMode: .fit)
        
    }
}
