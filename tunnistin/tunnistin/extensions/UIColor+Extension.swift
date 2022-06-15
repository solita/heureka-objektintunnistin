import Foundation
import UIKit

extension CGFloat {
  /// Helper function to produce random colours
  /// - Returns: random `CGFloat` value between 0 and 1.
  static func random() -> CGFloat {
    return CGFloat(arc4random()) / CGFloat(UInt32.max)
  }
}

extension UIColor {
  /// UIColor with Int r-g-b values
  /// - Parameters:
  ///   - red: value of red component (0-255)
  ///   - green: value of green component (0-255)
  ///   - blue: value of blue component (0-255)
  convenience init(red: Int, green: Int, blue: Int) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }

  /// UIColor Initializer with single Int rgb value
  /// - Parameter rgb: integer value with first 8 bits for blue, next 8 for green, last 8 for red.
  convenience init(rgb: Int) {
    self.init(
      red: (rgb >> 16) & 0xFF,
      green: (rgb >> 8) & 0xFF,
      blue: rgb & 0xFF
    )
  }

  /// UIColor initializer with rgb hex string value
  /// - Parameter rgb: string representing the color in (#)rrggbb format.
  convenience init(rgb: String) {
    var cString: String = rgb.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    if cString.hasPrefix("#") {
      cString.remove(at: cString.startIndex)
    }

    if (cString.count) != 6 {
      self.init(rgb: 0x888888)
    }

    var rgbValue: UInt64 = 0
    Scanner(string: cString).scanHexInt64(&rgbValue)
    let rgbInt = Int(truncatingIfNeeded: rgbValue)

    self.init(
      red: (rgbInt >> 16) & 0xFF,
      green: (rgbInt >> 8) & 0xFF,
      blue: rgbInt & 0xFF
    )
  }

  /// Create random color
  /// - Returns: random UIColor with alpha 1.0
  static func random() -> UIColor {
    return UIColor(
      red: .random(),
      green: .random(),
      blue: .random(),
      alpha: 1.0
    )
  }

  /// Default brand color. Can be overridden in configuration with "defaultUIColor"
  static let Heureka = AppConfig.shared.screenUIColor
}
