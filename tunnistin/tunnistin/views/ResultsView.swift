import UIKit
import Combine

class ResultsView: UIView {
  private weak var resultModel: ResultModel?
  private var foundSubscriber: AnyCancellable?
  private var progressSubscriber: AnyCancellable?

  private lazy var backgroundBlurView: UIVisualEffectView = {
    let blurEffect = UIBlurEffect(style: .light)
    let effectView = UIVisualEffectView(effect: blurEffect)
    effectView.translatesAutoresizingMaskIntoConstraints = false
    return effectView
  }()

  private lazy var spyGlassView: UIImageView = {
    let imageV = UIImageView.init(image: UIImage.init(named: "spyglass")?.withTintColor(AppConfig.shared.screenUIColor))
    imageV.translatesAutoresizingMaskIntoConstraints = false
    imageV.contentMode = .scaleAspectFit
    return imageV
  }()

  private lazy var soughtView: UIStackView = {
    let stackV = UIStackView()
    stackV.translatesAutoresizingMaskIntoConstraints = false
    stackV.distribution = .fillEqually
    stackV.axis = .vertical
    stackV.backgroundColor = .clear
    return stackV
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(backgroundBlurView)
    addSubview(spyGlassView)
    addSubview(soughtView)
    layoutElements()
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  convenience init(model: ResultModel) {
    self.init(frame: CGRect.zero)
    resultModel = model

    foundSubscriber = model.$foundClasses.sink(receiveValue: { classes in
      self.showFoundObjects(classes)
    })

    progressSubscriber = model.$detectionProgress.sink(receiveValue: { progresses in
      for index in 0...progresses.count-1 {
        if var opv = self.objectViewForClass(model.soughtClasses[index]) {
          opv.progress = progresses[index]
        }
      }
    })

    model.soughtClasses.forEach { cls in
      let objectV = ObjectView.init(frame: CGRect.zero)
      objectV.iconClass = cls
      soughtView.addArrangedSubview(objectV)
    }
  }

  private func showFoundObjects(_ classes: [String]) {
    print(classes)
    classes.forEach {
      if var ovp = objectViewForClass($0) {
        print("found")
        ovp.progress = 1
      }
    }
  }

  private func objectViewForClass(_ classId: String) -> ObjectViewProtocol? {
    let views: [ObjectViewProtocol] = soughtView.arrangedSubviews.compactMap { $0 as? ObjectViewProtocol }
    let match = views.first(where: {$0.iconClass == classId})
    return match
  }

  func layoutElements() {
    NSLayoutConstraint.activate([backgroundBlurView.centerXAnchor.constraint(equalTo: centerXAnchor),
                                 backgroundBlurView.centerYAnchor.constraint(equalTo: centerYAnchor),
                                 backgroundBlurView.widthAnchor.constraint(equalTo: widthAnchor),
                                 backgroundBlurView.heightAnchor.constraint(equalTo: heightAnchor),
                                 spyGlassView.widthAnchor.constraint(equalToConstant: 40),
                                 spyGlassView.heightAnchor.constraint(equalToConstant: 40),
                                 spyGlassView.centerXAnchor.constraint(equalTo: centerXAnchor),
                                 spyGlassView.topAnchor.constraint(equalTo: topAnchor, constant: 30),
                                 soughtView.widthAnchor.constraint(equalTo: widthAnchor),
                                 soughtView.centerXAnchor.constraint(equalTo: centerXAnchor),
                                 soughtView.topAnchor.constraint(equalTo: spyGlassView.bottomAnchor, constant: 20),
                                 soughtView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)])
  }
}
