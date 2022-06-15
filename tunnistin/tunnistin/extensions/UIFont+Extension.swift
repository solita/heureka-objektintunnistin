import Foundation
import UIKit

extension UIFont {
  /// Create font of given size using font specified in configuration.
  /// - Parameter size: Size of the font
  /// - Returns: Configured font with given size. If the font in configuration cannot be initialised
  ///            (font file not available / incorrect spelling), system font will be used.
  class func tunnistinFont(size: CGFloat) -> UIFont {
    if let typeface = UIFont(name: AppConfig.shared.fontName, size: size) {
      return typeface
    }
    return UIFont.systemFont(ofSize: size)
  }
}
