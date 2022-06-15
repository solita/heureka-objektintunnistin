import UIKit

protocol ObjectViewProtocol {
  var iconClass: String { get set }
  var progress: Double { get set }
}

class ObjectView: UIView, ObjectViewProtocol {

  let annotationBuilder = AnnotationBuilder.init(timerLength: AppConfig.shared.objectTimerLength)
  var iconClass: String = "" {
    didSet {
      if let image = UIImage.imageFromResource(named: iconClass) {
        objectIconView.image = image
        return
      }
      objectIconView.image = UIImage.init(systemName: "questionmark")
    }
  }

  var progress: Double = 0.0 {
    didSet {
      if AppConfig.shared.objectTimerType == .pie {
          let mask = createTimerMask(objectCircle.bounds, progress: progress, radius: 50.0)
          objectCircle.layer.mask = mask
      } else {
        progressMask.frame = CGRect.init(x: 0, y: 0, width: 100 * progress, height: 100)
        objectCircle.mask = progressMask
      }
    }
  }

  private func createTimerMask(_ bounds: CGRect,
                               progress: Double,
                               radius: Double = 10.0,
                               color: CGColor? = UIColor.white.cgColor) -> CAShapeLayer {
    let fraction = progress
    let layer = CAShapeLayer()
    let centerPoint = CGPoint.init(x: bounds.width / 2, y: bounds.height / 2)

    let curve = CGMutablePath()
    curve.move(to: centerPoint)
    if fraction == 1.0 {
      curve.addPath(CGPath.init(ellipseIn: CGRect.init(origin: CGPoint.init(x: centerPoint.x - radius,
                                                                            y: centerPoint.y - radius),
                                                       size: CGSize.init(width: radius * 2,
                                                                         height: radius * 2)), transform: nil))
    } else if fraction == 0 {
      curve.addPath(CGPath.init(rect: CGRect.zero, transform: nil))
    } else {
      curve.addArc(center: centerPoint, radius: radius,
                   startAngle: (1-fraction) * 2 * .pi,
                   endAngle: 0, clockwise: false)
      curve.closeSubpath()
    }
    layer.path = curve
    layer.fillColor = color
    layer.strokeColor = color
    return layer
  }

  lazy var objectBackground: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  lazy var objectCircle: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .white
    view.layer.masksToBounds = true
    view.layer.borderWidth = 2
    view.layer.cornerRadius = 50
    view.layer.borderColor = UIColor.black.cgColor

    if AppConfig.shared.objectTimerType == .pie {
      // rotate the element to same orientation with the overlay pie
      var transform: CGAffineTransform = CGAffineTransform(rotationAngle: Double.pi/2)
      transform = transform.scaledBy(x: 1, y: -1)
      view.transform = transform
    }
    return view
  }()

  lazy var progressMask: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .blue
    return view
  }()

  lazy var objectIconView: UIImageView = {
    let view = UIImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.contentMode = .scaleAspectFit
    view.tintColor = .black
    return view
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(objectBackground)
    addSubview(objectIconView)
    objectBackground.addSubview(objectCircle)
//    objectCircle.mask = progressMask
    layoutElements()
    layoutSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    print("layoutsubviews")
    let mask = createTimerMask(objectCircle.bounds, progress: progress, radius: 50.0)
    objectCircle.layer.mask = mask
  }

  private func layoutElements() {

    NSLayoutConstraint.activate([objectBackground.widthAnchor.constraint(equalToConstant: 100),
                                 objectBackground.heightAnchor.constraint(equalTo: objectBackground.widthAnchor),
                                 objectBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
                                 objectBackground.centerYAnchor.constraint(equalTo: centerYAnchor),
                                 objectCircle.centerXAnchor.constraint(equalTo: objectBackground.centerXAnchor),
                                 objectCircle.centerXAnchor.constraint(equalTo: objectBackground.centerXAnchor),
                                 objectCircle.widthAnchor.constraint(equalTo: objectBackground.widthAnchor),
                                 objectCircle.heightAnchor.constraint(equalTo: objectBackground.heightAnchor),
                                 objectIconView.widthAnchor.constraint(equalToConstant: 70),
                                 objectIconView.heightAnchor.constraint(equalTo: objectIconView.widthAnchor),
                                 objectIconView.centerXAnchor.constraint(equalTo: objectCircle.centerXAnchor),
                                 objectIconView.centerYAnchor.constraint(equalTo: objectCircle.centerYAnchor)
                                ])
  }
}
