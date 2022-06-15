import UIKit

class AwardView: UIView {
  private var dismissTimer: Timer?
  private lazy var imageView: UIImageView = {
    let imageV = UIImageView()
    imageV.translatesAutoresizingMaskIntoConstraints = false
    imageV.contentMode = .scaleAspectFit
    imageV.animationImages = UIImage.gifFramesFrom(named: "award")
    imageV.animationDuration = AppConfig.shared.awardGifDuration
    imageV.startAnimating()
    return imageV
  }()

  private lazy var title: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.tunnistinFont(size: 60)
    label.textColor = AppConfig.shared.objectTextUIColor
    label.numberOfLines = 0
    label.text = "text_success".localized()
    label.minimumScaleFactor = 0.5
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  private lazy var subTitle: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.tunnistinFont(size: 48)
    label.text = "text_found_items".localized()
    label.textColor = AppConfig.shared.objectTextUIColor
    label.minimumScaleFactor = 0.5
    label.adjustsFontSizeToFitWidth = true
    return label
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .Heureka

    addSubview(imageView)
    addSubview(title)
    addSubview(subTitle)

    createLayout()
  }

  convenience init() {
    self.init(frame: CGRect.zero)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  private func createLayout() {
    NSLayoutConstraint.activate([imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                                 imageView.topAnchor.constraint(equalTo: topAnchor, constant: 30),
                                 imageView.widthAnchor.constraint(equalTo: widthAnchor, constant: -30),
                                 imageView.heightAnchor.constraint(equalToConstant: AppConfig.shared.awardGifHeight),
                                 title.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30),
                                 title.centerXAnchor.constraint(equalTo: centerXAnchor),
                                 title.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -30),
                                 subTitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 30),
                                 subTitle.centerXAnchor.constraint(equalTo: centerXAnchor),
                                 subTitle.widthAnchor.constraint(equalTo: title.widthAnchor),
                                 subTitle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30)])
  }

}
