import Foundation
import UIKit

let modelsDict: [Int: String] = [1: "YOLOv3Int8LUT", 2: "yolov5x"]

/// Protocol for accessing swift-native properties with values derivated from raw JSON configuration.
protocol JSONDerivable {
  /// name of model to load
  var modelName: String { get }

  /// return default UIColor for object annotation borders, if specified in configuration
  var objectUIColor: UIColor? { get }

  /// return text color to be used in object annotations
  var objectTextUIColor: UIColor { get }

  /// return color to be used on pause/award screens
  var screenUIColor: UIColor { get }

  /// returns UIColor for given object class. If the class configuration has specific color, it will be used. If no class-specific color exists,
  /// returns default object color if specified, otherwise will randomly generate a color and return the same color for same class during the session.
  func color(_ objectClass: String) -> UIColor

  /// returns available localisations for given text id in the order of displayLanguages array in configuration.
  func localisations(_ textId: String) -> [String]
}

/// Singleton AppConfig class wrapping the configuration for the whole app
class AppConfig {
  static let shared = AppConfig()
  private var _config: JSONConfig
  private var displayLanguageIndices: [Int] = []
  private var sessionColors: [String: UIColor] = [:]

  init() {

   let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
   let userConfigUrl = URL(fileURLWithPath: "config", relativeTo: documentsDir).appendingPathExtension("json")

    var parsedConfig = AppConfig.parseConfiguration(url: userConfigUrl)
    if parsedConfig == nil {
      if let bundleUrl = Bundle.main.url(forResource: "config", withExtension: "json") {
        parsedConfig = AppConfig.parseConfiguration(url: bundleUrl)
      }
    }
    _config = parsedConfig ?? JSONConfig.emptyConfig()

    // Parse preconfigured colors to sessionColors dict
      _config.objects.filter({ obj in
        obj.color != nil
      }).forEach { sessionColors[$0.classification] =  UIColor.init(rgb: $0.color!)}

      // Set up the language indices
      let displayLanguages: [String] = _config.displayLanguages
      let supportedLanguages: [String] = _config.languages

      displayLanguages.forEach {
        if let languageIndex = supportedLanguages.firstIndex(of: $0) {
          displayLanguageIndices.append(languageIndex)
        }
      }
  }

  private static func parseConfiguration(url: URL) -> JSONConfig? {
    let parsedConfig: JSONConfig?
    do {
      let userConfigData = try Data(contentsOf: url)
      parsedConfig = try JSONDecoder().decode(JSONConfig.self, from: userConfigData)
     } catch {
       print("Unable to read the file", error)
       parsedConfig = nil
     }
    return parsedConfig
  }

}

extension AppConfig: JSONConfigurable {
  // JSONConfigurable properties
  var requiredIntersection: Double { return _config.requiredIntersection }
  var zoomFactor: Double { return _config.zoomFactor }
  var confidenceThreshold: Double { return _config.confidenceThreshold }
  var objectTimerLength: Double { return _config.objectTimerLength }
  var objectTimerType: TimerType { return _config.objectTimerType }
  var resultsViewWidth: Double { return _config.resultsViewWidth }
  var motionSensorPause: Double { return _config.motionSensorPause }
  var borderWidth: Double { return _config.borderWidth }
  var cornerRadius: Double { return _config.cornerRadius }
  var targetObjects: [String] { return _config.targetObjects }
  var languages: [String] { return _config.languages }
  var displayLanguages: [String] { return _config.displayLanguages }
  var modelId: Int { return _config.modelId }
  var objects: [Object] { return _config.objects }
  var uiTexts: [UIText] { return _config.uiTexts }
  var objectColor: String? { return _config.objectColor }
  var objectTextColor: String { return _config.objectTextColor }
  var fontName: String { return _config.fontName }
  var awardGifHeight: Double { return _config.awardGifHeight }
  var awardGifDuration: Double { return _config.awardGifDuration }
  var idleDetectionCycles: Int { return _config.idleDetectionCycles }
  var awardDisplayTime: Double { return _config.awardDisplayTime }
  var pauseImageHeight: Double { return _config.pauseImageHeight }
  var motionDetectionThreshold: Double { return _config.motionDetectionThreshold }
  var showMotionValues: Bool { return _config.showMotionValues }
  var screenColor: String { return _config.screenColor }
}

extension AppConfig: JSONDerivable {
  // JSONDerivable properties
  var modelName: String { return modelsDict[_config.modelId] ?? "YOLOv3Int8LUT" }
  var objectUIColor: UIColor? { return _config.objectColor != nil ? UIColor.init(rgb: _config.objectColor!) : nil }
  var objectTextUIColor: UIColor { return UIColor.init(rgb: _config.objectTextColor) }
  var screenUIColor: UIColor { return UIColor.init(rgb: _config.screenColor ) }
  func color(_ objectClass: String) -> UIColor {
    if let existing = sessionColors[objectClass] {
      return existing
    }
    let clr: UIColor
    if let colorString = _config.objectColor {
      clr = UIColor.init(rgb: colorString)
    } else {
      clr = .random()
    }
    sessionColors[objectClass] = clr
    return clr
  }

  func localisations(_ textId: String) -> [String] {
    var locStrings: [String] = []

    // get localisation from uiTexts array
    if let obj = _config.uiTexts.first(where: {$0.textId == textId}), let locs = obj.localisations {
      displayLanguageIndices.forEach {
        if locs.count > $0 {
          locStrings.append(locs[$0])
        }
      }
    }

    // if not found, get localisation from objects array
    if locStrings.isEmpty {
      if let obj = _config.objects.first(where: {$0.classification == textId}), let locs = obj.localisations {
        displayLanguageIndices.forEach {
          if locs.count > $0 {
            locStrings.append(locs[$0])
          }
        }
      }
    }

    if locStrings.isEmpty {
      locStrings = [textId]
    }
    return locStrings
  }

}
