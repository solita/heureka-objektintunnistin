import UIKit
import CoreMotion

/// multiplier to use in `CMAcceleration` extension for calculating equality with certain precision
let multiplier: Double = 100.0

/// Extension to compare two `CMAcceleration` values with the chosen precision (`multiplier`)
extension CMAcceleration: Equatable {
  public static func == (lhs: CMAcceleration, rhs: CMAcceleration) -> Bool {
    return round(lhs.x * multiplier) / multiplier == round(rhs.x * multiplier) / multiplier &&
           round(lhs.y * multiplier) / multiplier == round(rhs.y * multiplier) / multiplier &&
          round(lhs.z * multiplier) / multiplier == round(rhs.z * multiplier) / multiplier
  }
}

/// Main NavigationController. Handles the motion sensor data and shows/hides idle view when necessary
class NavigationController: UINavigationController {

  var stationaryCycles: Int = 0
  var previousAxisData: CMAcceleration?
  var chargeLastStarted: TimeInterval = 0

  /// Motion sensing info label. To display on screen for debugging purposes, change `showMotionValues` property in configuration to true
  private lazy var motionInfoLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.backgroundColor = .white.withAlphaComponent(0.7)
    label.textColor = .black
    label.alpha = AppConfig.shared.showMotionValues ? 1.0 : 0.0
    return label
  }()

  let motionManager = CMMotionManager()
  let motionQueue: OperationQueue = {
    let motionQueue = OperationQueue()
    motionQueue.name = "com.solita.Heureka.motionqueue"
    return motionQueue
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    startMonitoring()
    startMonitoringBattery()
    view.addSubview(motionInfoLabel)
    NSLayoutConstraint.activate([motionInfoLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30),
                                 motionInfoLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 30)])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  private func startMonitoringBattery() {
    UIDevice.current.isBatteryMonitoringEnabled = true

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(batteryStatusChanged),
        name: UIDevice.batteryStateDidChangeNotification,
        object: nil
    )
  }

  private func startMonitoring() {
    if #available(iOS 14.0, *) {
      guard !ProcessInfo.processInfo.isiOSAppOnMac else {
        dismissFlatView()
        return
      }
    }

    // If activity updates are supported, start updates on the motionQueue.
    if motionManager.isDeviceMotionAvailable {
      motionManager.deviceMotionUpdateInterval = 0.2
      motionManager.startDeviceMotionUpdates(to: motionQueue) { motionData, _ in
        DispatchQueue.main.async { self.processAxisData(motionData?.userAcceleration)}
      }
    } else {
      dismissFlatView()
    }

  }

  @objc func batteryStatusChanged(notification: Notification?) {
    if UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full {
      chargeLastStarted = Date.timeIntervalSinceReferenceDate
      showFlatView()
    }
  }

  private func processAxisData(_ axisData: CMAcceleration?) {
    guard let data = axisData else {
      return // no data
    }

    let totalMotion = sqrt(data.x * data.x + data.y * data.y + data.z * data.z)
    if totalMotion < AppConfig.shared.motionDetectionThreshold {
      stationaryCycles += 1
    }

    let labelString = String.init(format: "totalMotion: %.3f\n\nstationaryCycles: %d",
                                    totalMotion, stationaryCycles)
    motionInfoLabel.text = labelString

    if stationaryCycles >= AppConfig.shared.idleDetectionCycles {
      stationaryCycles = 0
      showFlatView()
    } else if totalMotion > AppConfig.shared.motionDetectionThreshold {
      stationaryCycles = 0
      dismissFlatView()
    }
  }

  private func dismissFlatView() {
    if Date.timeIntervalSinceReferenceDate - chargeLastStarted < AppConfig.shared.motionSensorPause { return }
    self.setViewControllers([viewControllers[0]], animated: false)
  }

  private func showFlatView() {
    if viewControllers.count == 1 {
      self.setViewControllers([viewControllers[0], IdleViewController()], animated: false)
    }
  }
}
