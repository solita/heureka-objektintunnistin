import Foundation
import UIKit

/// Factory API for building annotation layers for recognition UI.
protocol AnnotationFactory {
  func createObjectLayer(_ bounds: CGRect, color: UIColor, borderWidth: Double, cornerRadius: Double, fillOpacity: Double?) -> CALayer
  func createObjectTimerLayer(_ bounds: CGRect, type: TimerType, elapsed: TimeInterval, color: CGColor?) -> CALayer
  func createObjectTextLayer(_ bounds: CGRect, identifier: String, confidence: Float, color: UIColor, textColor: UIColor) -> CALayer
  func createTimerPie(_ bounds: CGRect, elapsed: TimeInterval, radius: Double, color: CGColor?) -> CAShapeLayer
}

/// Implementation for the `AnnotationFactory` API.
struct AnnotationBuilder: AnnotationFactory {
  let timerLength: Double

  func createObjectLayer(_ bounds: CGRect,
                         color: UIColor = .white,
                         borderWidth: Double,
                         cornerRadius: Double,
                         fillOpacity: Double?) -> CALayer {
    let shapeLayer = CALayer()
    shapeLayer.bounds = bounds
    shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    shapeLayer.name = "Found Object"
    shapeLayer.borderColor = color.withAlphaComponent(1).cgColor
    shapeLayer.borderWidth = borderWidth
    if let opacity = fillOpacity, opacity > 0.0 && opacity <= 1.0 {
      shapeLayer.backgroundColor = color.withAlphaComponent(opacity).cgColor
    }
    shapeLayer.cornerRadius = cornerRadius
    return shapeLayer
  }

  func createObjectTextLayer(_ bounds: CGRect,
                             identifier: String,
                             confidence: Float,
                             color: UIColor,
                             textColor: UIColor) -> CALayer {
    let textLayer = CATextLayer()
    textLayer.name = "Object Label"
    let text = identifier
    textLayer.string = text
    textLayer.font = UIFont.tunnistinFont(size: 15.0)
    textLayer.fontSize = 14.0
    let textSize = text.size(withAttributes: [.font: UIFont.tunnistinFont(size: 14.0)])

    textLayer.bounds = CGRect(x: 0, y: 0, width: textSize.width + 3, height: textSize.height + 3)
    textLayer.anchorPoint = CGPoint.init(x: 0, y: 0)
    if bounds.minX > textSize.height {
      textLayer.position = CGPoint(x: bounds.minX-textLayer.frame.height, y: bounds.minY)
    } else {
      textLayer.position = CGPoint(x: bounds.maxX-textLayer.frame.height - 4.0, y: bounds.minY + 4.0)
    }
    textLayer.shadowOpacity = 0.7
    textLayer.shadowOffset = CGSize(width: 2, height: 2)
    textLayer.foregroundColor = textColor.cgColor
    textLayer.backgroundColor = color.cgColor
    textLayer.contentsScale = 2.0 // retina rendering
    // rotate the layer into screen orientation and scale and mirror
    textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
    return textLayer
  }

  func createObjectTimerLayer(_ bounds: CGRect, type: TimerType, elapsed: TimeInterval, color: CGColor?) -> CALayer {
    switch type {
    case .pie:
      return createTimerPie(bounds, elapsed: elapsed, radius: 10.0, color: color)
    case .bar:
      return createTimerBar(bounds, elapsed: elapsed, color: color)
    default:
      return createTimerText(bounds, elapsed: elapsed, color: color)
    }

  }

  func createTimerText(_ bounds: CGRect,
                       elapsed: TimeInterval,
                       color: CGColor? = UIColor.white.cgColor) -> CATextLayer {
    let textLayer = CATextLayer()
    textLayer.name = "elapsed time"
    let text = elapsed <= timerLength ? String(format: "  %.1f  ", elapsed) : String(format: "  %.1f  ", timerLength)
    let timerFont = UIFont.tunnistinFont(size: 12.0)
    let formattedString = NSMutableAttributedString(string: "\(text)")
    formattedString.addAttributes([NSAttributedString.Key.font: timerFont],
                                  range: NSRange(location: 0, length: text.count))
    textLayer.string = formattedString

    let textSize = formattedString.size()
    textLayer.bounds = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
    textLayer.anchorPoint = CGPoint.init(x: 0, y: 1)
    textLayer.position = CGPoint(x: bounds.minX+textSize.height+5, y: bounds.maxY-textSize.width-5)
    textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
    textLayer.backgroundColor = UIColor.white.cgColor
    textLayer.opacity = 0.3
    textLayer.contentsScale = 2.0 // retina rendering
    // rotate the layer into screen orientation and scale and mirror
    textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
    return textLayer
  }

  func createTimerPie(_ bounds: CGRect,
                      elapsed: TimeInterval,
                      radius: Double = 10.0,
                      color: CGColor? = UIColor.white.cgColor) -> CAShapeLayer {
    let fraction = elapsed < timerLength ? elapsed / timerLength : 1
    let layer = CAShapeLayer()
    let centerPoint = CGPoint.init(x: bounds.minX + radius * 2, y: bounds.maxY - radius * 2)
    let pieRect = CGRect.init(origin: CGPoint.init(x: centerPoint.x - radius,
                                                  y: centerPoint.y-radius),
                             size: CGSize.init(width: radius * 2,
                                               height: radius * 2))
    let curve = CGMutablePath()
    curve.move(to: centerPoint)
    if fraction == 1.0 {
      curve.addPath(CGPath.init(ellipseIn: pieRect, transform: nil))
      addTick(to: layer, bounds: pieRect)
   } else {
      curve.addArc(center: centerPoint, radius: radius,
                   startAngle: 0,
                   endAngle: (1-fraction) * 2 * .pi, clockwise: true)
      curve.closeSubpath()
    }
    layer.path = curve
    layer.borderWidth = 2
    layer.borderColor = UIColor.blue.cgColor
    layer.fillColor = color
    layer.strokeColor = color
    return layer
  }

  func addTick(to layer: CALayer, bounds: CGRect) {
    let tickLayer = CALayer.init()
    tickLayer.frame = CGRect.init(x: bounds.minX+2, y: bounds.minY+2, width: bounds.width-4, height: bounds.height-4)
    tickLayer.contents = UIImage.init(systemName: "checkmark.circle")?.cgImage
    tickLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
    layer.addSublayer(tickLayer)
  }

  func createTimerBar(_ bounds: CGRect,
                      elapsed: TimeInterval,
                      color: CGColor? = UIColor.white.cgColor) -> CAShapeLayer {
    let barWidth = bounds.height-4
    let fraction = elapsed < timerLength ? elapsed / timerLength : 1
    let layer = CAShapeLayer()
    layer.frame = CGRect.init(x: 2, y: 2, width: barWidth, height: 10 )
    layer.backgroundColor = UIColor.white.withAlphaComponent(0.3).cgColor

    let timerBox = CGMutablePath()
    timerBox.addRect(CGRect.init(x: bounds.minX + 2, y: bounds.minY+2, width: 10.0, height: barWidth * fraction))
    timerBox.closeSubpath()
    layer.path = timerBox
    layer.fillColor = color
    return layer
  }
}
