// Copyright © 2023 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import Foundation
import UIKit
import SwiftUI

public enum ColorFunctions {
    
    /** Obtain a UIColor from a hex value
     
     Example: hexColor(0xe85d88)
    
     - returns: UIColor with alpha of 1.0
     */
    public static func hexColor(_ rgbValue: Int) -> UIColor {
        UIColor(red:   ((CGFloat)((rgbValue & 0xFF0000) >> 16))/255.0,
                green: ((CGFloat)((rgbValue & 0xFF00) >> 8))/255.0,
                blue:  ((CGFloat)(rgbValue & 0xFF))/255.0,
                alpha: 1.0)
    }
    
    /// Obtain a UIColor from the specified red, green, blue and alpha values
    /// Example: rgbaColor(25, 25, 25, 1.0)
    ///
    /// - parameter red: Int
    /// - parameter green: Int
    /// - parameter blue: Int
    /// - parameter alpha: CGFloat
    /// - returns: UIColor
    public static func rgbaColor(_ red: Int, _ green: Int, _ blue: Int, _ alpha: CGFloat) -> UIColor {
        
        return UIColor(red: CGFloat(red)/255.0,
                       green: CGFloat(green)/255.0,
                       blue: CGFloat(blue)/255.0,
                       alpha: alpha)
    
    }
}

public extension UIColor {

    /// Allow for manually creation of a UIColor that supports both light and dark modes
    class func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        
        return UIColor {
            switch $0.userInterfaceStyle {
            case .dark:
                return dark
                
            default:
                return light
            }
        }
    }
}


