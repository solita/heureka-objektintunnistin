import UIKit
import Vision

/// LaunchViewController is shown when application launches and shows a spinner while model is getting loaded.
class LaunchViewController: UIViewController {

  private lazy var infoLabel: UILabel = UILabel()
  private lazy var spinner: UIActivityIndicatorView = UIActivityIndicatorView.init(style: .large)

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.isHidden = true
    createUI()
    DispatchQueue.main.async {
      self.loadModel()
    }
    view.backgroundColor = .Heureka
  }

  private func createUI() {
    view.backgroundColor = UIColor.white
    view.addSubview(infoLabel)
    infoLabel.translatesAutoresizingMaskIntoConstraints = false
    infoLabel.font = UIFont.tunnistinFont(size: 40.0)
    infoLabel.numberOfLines = 0
    infoLabel.textAlignment = .center
    infoLabel.textColor = AppConfig.shared.objectTextUIColor
    infoLabel.text = "text_init".localized()
    NSLayoutConstraint.activate([infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                 infoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                 infoLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40.0)])

    view.addSubview(spinner)
    spinner.color = AppConfig.shared.objectTextUIColor
    spinner.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                 spinner.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 40)])
    spinner.startAnimating()
  }

  func loadModel() {
#if targetEnvironment(simulator)
    navigateToMain(visionModel: nil)
    return
#else
    let config = MLModelConfiguration()
    config.computeUnits = .all
    config.allowLowPrecisionAccumulationOnGPU = true

    let modelName = AppConfig.shared.modelName
    print("Loading model \(modelName)")
    if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
      do {
        let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL, configuration: config))
        visionModel.inputImageFeatureName = "image"
        visionModel.featureProvider = try MLDictionaryFeatureProvider(dictionary: [
          "confidenceThreshold": AppConfig.shared.confidenceThreshold ])
        DispatchQueue.main.async { self.navigateToMain(visionModel: visionModel) }
      } catch let error as NSError {
        showError(error.description)
      }
    } else {
      // just notify about not being able to start
      showError("Failed to load model \(modelName)")
    }
#endif
  }

  func showError(_ message: String) {
    spinner.stopAnimating()
    let alertvc = UIAlertController.init(title: "Error", message: message, preferredStyle: .alert)
    alertvc.addAction(UIAlertAction.init(title: "Close App", style: .default, handler: { _ in
      exit(0)
    }))
    present(alertvc, animated: true)
  }

  func navigateToMain(visionModel: VNCoreMLModel?) {
    let nvc = NavigationController.init()
    nvc.setViewControllers([RecognitionViewController(visionModel: visionModel), IdleViewController()], animated: false)
    view.window?.rootViewController = nvc
  }
}
