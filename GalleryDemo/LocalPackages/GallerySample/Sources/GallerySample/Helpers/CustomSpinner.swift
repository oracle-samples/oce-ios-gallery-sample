// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import SwiftUI

/// Custom progress spinner used by the demo UI
public struct CustomSpinner : View {
    @State private var isAnimating = false
    
    @State private var showProgress = false
    var labelText: String
    
    public init(labelText: String = "") {
        self.labelText = labelText
    }
    
    var foreverAnimation: Animation {
        Animation
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
    }

    public var body: some View {
 
        VStack {
            Image(systemName: "arrow.2.circlepath")
                .font(.system(size: 80))
                .foregroundColor(Color(uiColor: ColorFunctions.hexColor(0xBB0000)))
                .frame(width: 100, height: 100)
                .onAppear {
                    withAnimation {
                        self.isAnimating = true
                    }
                }
                .onDisappear { self.isAnimating = false }
                .rotationEffect(Angle(degrees: self.isAnimating ? 360 : 0.0), anchor: .center)
                .animation(foreverAnimation, value: self.isAnimating)
                .onAppear { self.showProgress = true }

            Text(labelText)
        }
        
    }
}

struct ShadowProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .accentColor(.red)
            .shadow(color: Color(red: 0, green: 0.7, blue: 0),
                    radius: 5.0, x: 2.0, y: 2.0)
    }
}

struct CustomCircularProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, dash: [10, 5]))
                .rotationEffect(.degrees(-90))
                .frame(width: 200)
            
            if let fractionCompleted = configuration.fractionCompleted {
                Text(fractionCompleted < 1 ?
                        "Completed \(Int((configuration.fractionCompleted ?? 0) * 100))%"
                        : "Done!"
                )
                .fontWeight(.bold)
                .foregroundColor(fractionCompleted < 1 ? .blue : .green)
                .frame(width: 180)
            }
        }
    }
}
