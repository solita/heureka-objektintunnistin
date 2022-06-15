import Foundation

extension String {

  /// Provide localized string ready to be displayed on screen for a logical name (self)
  /// - Returns: localisations in configured languages separated by newline.
  func localized() -> String {
    return AppConfig.shared.localisations(self).filter { $0 != "" }.joined(separator: "\n")
  }
}
