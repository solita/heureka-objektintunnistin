import UIKit
import CoreMotion

/// IdleViewController is shown whenever the device is static (not moving) for long enough.
/// The parameters for determining long enough are specified in config.json (`motionDetectionThreshold` and `idleDetectionCycles`)
class IdleViewController: UIViewController {

  private lazy var containerView: UIView = {
    let containerV = UIView()
    containerV.translatesAutoresizingMaskIntoConstraints = false
    return containerV
  }()

  private lazy var infoLabel: UILabel = {
    let label = UILabel.init()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.tunnistinFont(size: 40.0)
    label.textAlignment = .center
    label.numberOfLines = 0
    label.textColor = AppConfig.shared.objectTextUIColor
    label.text = "text_idle".localized()
    return label
  }()

private lazy var imgView: UIImageView = {
    let imageV = UIImageView.init()
    imageV.translatesAutoresizingMaskIntoConstraints = false
    imageV.contentMode = .scaleAspectFit
    imageV.image = UIImage.imageFromResource(named: "pause")
    return imageV
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.isHidden = true
    createUI()
  }

  private func createUI() {
    view.backgroundColor = .Heureka
    view.addSubview(containerView)
    containerView.addSubview(imgView)
    containerView.addSubview(infoLabel)

    let imageH = AppConfig.shared.pauseImageHeight

    NSLayoutConstraint.activate([containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                 containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                 containerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -80),
                                 containerView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, constant: -80)])

    NSLayoutConstraint.activate([imgView.heightAnchor.constraint(equalToConstant: imageH),
                                 imgView.widthAnchor.constraint(equalTo: containerView.widthAnchor),
                                 imgView.topAnchor.constraint(equalTo: containerView.topAnchor),
                                 imgView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                                 infoLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                                 infoLabel.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 30),
                                 infoLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor),
                                 infoLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)])
  }
}
