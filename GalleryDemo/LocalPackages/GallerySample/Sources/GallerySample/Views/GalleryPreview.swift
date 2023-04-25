// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import SwiftUI
import OracleContentCore
import OracleContentDelivery
import Combine

/// The large preview of an asset with navigation buttons to go forward and backward in the taxonomy category's assets
public struct GalleryPreview: View {
    
    @StateObject public var model: GalleryPreviewModel
    @State var imageOpacity: Double
    private var assetIndex: Int
    
    init(gallery: Binding<GalleryCategory>, index: Int) {
        _model = StateObject(wrappedValue: GalleryPreviewModel(gallery))
        _imageOpacity = State(initialValue: 0.3)
        assetIndex = index
    }
    
    public var body: some View {
        ZStack {
           
            VStack {
                Spacer()

                switch self.model.state {
                case .loading:
                    CustomSpinner()

                case .error(let error):
                    Text(error.localizedDescription)

                case .done(let image):
        
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .edgesIgnoringSafeArea(.all)
                        .opacity(self.imageOpacity)
                        .animation(.easeIn, value: image)
                        .onAppear {
                            self.imageOpacity = 0.3
                            withAnimation {
                                self.imageOpacity = 1.0
                            }
                        }
                }

                Spacer()

                Text(self.model.previewCounterText)
            }
            
            NavigationButton(systemName: "chevron.left", location: .left, showButton: self.$model.showPreviousButton) {
                self.model.send(.previous)
            }
            
            NavigationButton(systemName: "chevron.right", location: .right, showButton: self.$model.showNextButton) {
                self.model.send(.next)
            }
        }
        .onAppear {
            self.model.send(.fetch(self.assetIndex))
        }
        .environmentObject(self.model)
    }
}

/// Buttons used for navigation to the previous or next preview
struct NavigationButton: View {
    
    @Binding var showButton: Bool
    private var systemName: String
    private var action: () -> Void
    private var buttonLocation: Location
    
    enum Location {
        case left
        case right
    }
    
    /// Initiailzer
    /// - parameter systemName: The name of the SF Symbol used for the image
    /// - parameter location: Supported values are .left and .right
    /// - parameter showButton: The binding that determines whether this button is shown
    /// - parameter action: The closure to run when the button is clicked
    init(systemName: String, location: Location, showButton: Binding<Bool>, action: @escaping () -> Void) {
        _showButton = showButton
        self.systemName = systemName
        self.action = action
        self.buttonLocation = location
    }
    
    var body: some View {
        if self.showButton {
            HStack {
                
                if self.buttonLocation == .right {
                    Spacer()
                }
                
                ZStack {
                    Color.black.opacity(0.1).cornerRadius(5)
                    
                    Button {
                        withAnimation {
                            self.action()
                        }
                    } label: {
                        Image(systemName: self.systemName)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 44, height: 44)
                
                if self.buttonLocation == .left {
                    Spacer()
                }
                
            }.padding(.trailing, 10)
            
        }
    }
}
