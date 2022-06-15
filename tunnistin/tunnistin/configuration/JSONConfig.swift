import Foundation

/// Target object timer type
enum TimerType: String, Codable {
    case bar
    case pie
    case text
}

/// JSONConfigurable declares the protocol for accessing raw configuration properties and hides the optionality allowed in parsing.
/// For documentation of the JSON configuration fields and possible values, see `README.md` in the project root.
protocol JSONConfigurable {
  var languages: [String] { get }
  var displayLanguages: [String] { get }
  var modelId: Int { get }
  var confidenceThreshold: Double { get }
  var requiredIntersection: Double { get }
  var borderWidth: Double { get }
  var cornerRadius: Double { get }
  var objectTimerLength: Double { get }
  var objectTimerType: TimerType { get }
  var resultsViewWidth: Double { get }
  var motionSensorPause: Double { get }
  var zoomFactor: Double { get }
  var objects: [Object] { get }
  var uiTexts: [UIText] { get }
  var objectColor: String? { get }
  var objectTextColor: String { get }
  var targetObjects: [String] { get }
  var fontName: String { get }
  var awardGifHeight: Double { get }
  var idleDetectionCycles: Int { get }
  var awardDisplayTime: Double { get }
  var pauseImageHeight: Double { get }
  var showMotionValues: Bool { get }
  var motionDetectionThreshold: Double { get }
  var screenColor: String { get }
}

// MARK: - Config implementation
struct JSONConfig: Codable, JSONConfigurable {
  var languages, displayLanguages: [String]
  var objects: [Object]
  var uiTexts: [UIText]
  var modelId: Int { return _modelId ?? 1 }
  var confidenceThreshold: Double { return _confidenceThreshold ?? 0.5}
  var requiredIntersection: Double { return _requiredIntersection ?? 0.9}
  var borderWidth: Double { return _borderWidth ?? 4.0 }
  var cornerRadius: Double { return _cornerRadius ?? 0.0 }
  var objectTimerLength: Double { return _objectTimerLength ?? 2.0 }
  var objectTimerType: TimerType { return _objectTimerType ?? .pie }
  var resultsViewWidth: Double { return _resultsViewWidth ?? 0.14 }
  var motionSensorPause: Double { return _motionSensorPause ?? 3.0 }
  var zoomFactor: Double { return _zoomFactor ?? 1.0 }
  var objectColor: String? { return _objectColor }
  var objectTextColor: String { return _objectTextColor ?? "#FFFFFF" }
  var targetObjects: [String] { return _targetObjects ?? ["cell phone", "bag", "toothbrush", "cup", "book"]}
  var fontName: String { return _fontName ?? "SF Pro" }
  var awardGifHeight: Double { return _awardGifHeight ?? 150 }
  var awardGifDuration: Double { return _awardGifDuration ?? 3.0 }
  var idleDetectionCycles: Int { return _idleDetectionCycles ?? 100 }
  var awardDisplayTime: Double { return _awardDisplayTime ?? 8.0 }
  var pauseImageHeight: Double { return _pauseImageHeight ?? 0.0 }
  var showMotionValues: Bool { return _showMotionValues ?? false }
  var motionDetectionThreshold: Double { return _motionDetectionThreshold ?? 0.015 }
  var screenColor: String { return _screenColor ?? "#D20F41" }

  // declare private vars for potentially missing bits
  private var _modelId: Int?
  private var _confidenceThreshold: Double?
  private var _requiredIntersection: Double?
  private var _borderWidth: Double?
  private var _cornerRadius: Double?
  private var _objectTimerLength: Double?
  private var _objectTimerType: TimerType?
  private var _resultsViewWidth: Double?
  private var _motionSensorPause: Double?
  private var _zoomFactor: Double?
  private var _objectColor: String?
  private var _objectTextColor: String?
  private var _targetObjects: [String]?
  private var _fontName: String?
  private var _awardGifHeight: Double?
  private var _awardGifDuration: Double?
  private var _idleDetectionCycles: Int?
  private var _awardDisplayTime: Double?
  private var _pauseImageHeight: Double?
  private var _motionDetectionThreshold: Double?
  private var _showMotionValues: Bool?
  private var _screenColor: String?

  // Declare codingkeys and override the key names to allow providing default values for the `JSONConfigurable` properties
  // swiftlint:disable identifier_name
  enum CodingKeys: String, CodingKey {
    case languages
    case displayLanguages
    case objects
    case uiTexts
    case _modelId = "modelId"
    case _confidenceThreshold = "confidenceThreshold"
    case _requiredIntersection = "requiredIntersection"
    case _borderWidth = "borderWidth"
    case _cornerRadius = "cornerRadius"
    case _objectTimerLength = "objectTimerLength"
    case _objectTimerType = "objectTimerType"
    case _resultsViewWidth = "resultsViewWidth"
    case _motionSensorPause = "motionSensorPause"
    case _zoomFactor = "zoomFactor"
    case _objectColor = "objectColor"
    case _objectTextColor = "objectTextColor"
    case _targetObjects = "targetObjects"
    case _fontName = "fontName"
    case _awardGifHeight = "awardGifHeight"
    case _awardGifDuration = "awardGifDuration"
    case _idleDetectionCycles = "idleDetectionCycles"
    case _awardDisplayTime = "awardDisplayTime"
    case _pauseImageHeight = "pauseImageHeight"
    case _showMotionValues = "showMotionValues"
    case _motionDetectionThreshold = "motionDetectionThreshold"
    case _screenColor = "screenColor"
  }

  static func emptyConfig() -> JSONConfig {
    return JSONConfig.init(languages: [], displayLanguages: [], objects: [], uiTexts: [])
  }
}

// MARK: - Object
struct Object: Codable {
  let classification: String
  let localisations: [String]?
  let color: String?
  let confidenceThreshold: Double?
}

struct UIText: Codable {
  let textId: String
  let localisations: [String]?
}
