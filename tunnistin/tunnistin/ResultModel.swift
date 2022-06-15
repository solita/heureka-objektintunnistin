import Foundation
import Combine

struct DetectionProgress {
  var objectClass: String
  var progress: Double
}

/// Model and event publisher for target object recognition results.
final class ResultModel {
  private var targetResetTimers: [String: Timer] = [:]
  @Published var foundClasses: [String] = []
  @Published var detectionProgress: [Double] = []
  @Published var missionComplete: Bool = false
  var flashedClasses: [String] = []
  var soughtClasses: [String] = [] {
    didSet {
      detectionProgress = [Double](repeating: 0.0, count: soughtClasses.count)
    }
  }

  init(classes: [String]) {
    self.soughtClasses = classes
    reset()
  }

  func setProgress(classId: String, progress: Double) {
    if let index = soughtClasses.firstIndex(of: classId) {
      if detectionProgress[index] != 1.0 {
        detectionProgress[index] = progress
        targetResetTimers[classId]?.invalidate()
        targetResetTimers[classId] = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in
          self.setProgress(classId: classId, progress: 0)
        })
      } else {
        // detection complete => invalidate the timer
        targetResetTimers[classId]?.invalidate()
      }
    }
    if detectionProgress.reduce(0.0, +) == Double(soughtClasses.count) {
        // All items found
      missionComplete = true
    }
  }

  func reset() {
    detectionProgress = [Double](repeating: 0.0, count: soughtClasses.count)
    flashedClasses.removeAll()
    foundClasses.removeAll()
    targetResetTimers.removeAll()
    missionComplete = false
  }
}
