import Foundation
import UIKit

extension CGRect {
  /// Function returns the intersection fraction of this `CGRect` with given other `CGRect`
  /// - Parameter anotherRect: rectangle to compare with
  /// - Returns: portion of this rect area compared to average area of `self` and `anotherRect` summed
  func intersectionFractionWith(_ anotherRect: CGRect) -> CGFloat {
    if self.intersects(anotherRect) {
      let interRect: CGRect = self.intersection(anotherRect)
      return ((interRect.width * interRect.height) / (((self.width * self.height) + (anotherRect.width * anotherRect.height))/2.0))
    }
    return 0
  }

  /// Function returns the overlap fraction of this `CGRect` with given other `CGRect`
  /// - Parameter anotherRect: rectangle to compare with
  /// - Returns: portion of `anotherRect` that falls under `self`
  func overlapFractionWith(_ anotherRect: CGRect) -> CGFloat {
    if self.intersects(anotherRect) {
      let interRect: CGRect = self.intersection(anotherRect)
      return (interRect.width * interRect.height) / (anotherRect.width * anotherRect.height)
    }
    return 0
  }
}
