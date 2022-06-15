import UIKit
import AVFoundation
import Vision
import Combine
import SPConfetti

/// Class used to store `VNRecgonizedObjectObservation` received from the model
/// with some timing information for displaying timer elements on UI.
class PastObservation {
  var observation: VNRecognizedObjectObservation
  var firstDetected: TimeInterval = Date().timeIntervalSince1970
  init(observation: VNRecognizedObjectObservation) {
    self.observation = observation
  }

  func age() -> TimeInterval {
    return Date().timeIntervalSince1970 - firstDetected
  }
}

/// Derives CaptureViewController and adds functionality for running inference with camera images and annotating the view.
class RecognitionViewController: CaptureViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

  private var detectionOverlay: CALayer?
  private var visionModel: VNCoreMLModel?
  private var resultsView: ResultsView?
  private var knownClasses: [String] = []
  private var awardViewAnimatedConstraint: NSLayoutConstraint?
  private lazy var awardView: AwardView = {
    let view = AwardView(frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isHidden = true
    return view
  }()

  private var resultsModel = ResultModel(classes: AppConfig.shared.targetObjects)
  private var annotationBuilder = AnnotationBuilder(timerLength: AppConfig.shared.objectTimerLength)
  var rootLayer: CALayer?

  private var observationHistory: [String: [PastObservation]] = [:]
  private var completionSubscriber: AnyCancellable?

  // Vision parts
  private var requests = [VNRequest]()

  convenience init(visionModel: VNCoreMLModel?) {
    self.init()
    self.visionModel = visionModel
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.isHidden = true
    rootLayer = cameraPreview.layer
    knownClasses = AppConfig.shared.objects.map { $0.classification }
    completionSubscriber = resultsModel.$missionComplete.sink(receiveValue: { value in
      if value {
        self.detectionOverlay?.removeFromSuperlayer()
        self.detectionOverlay = nil
        self.animateAwardViewIn()
        SPConfetti.stopAnimating()
        SPConfetti.startAnimating(.fullWidthToDown, particles: [.triangle, .arc], duration: AppConfig.shared.awardDisplayTime / 2.0)
      } else {
        self.setupLayers()
        self.animateAwardViewOut()
        SPConfetti.stopAnimating()
      }
    })
    createElements()
    layoutElements()
    setupVision()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateLayerGeometry()
    self.setupLayers()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super .viewDidDisappear(animated)
    resultsModel.reset()
  }

  func createElements() {
    let resultsV = ResultsView.init(model: resultsModel)
    resultsV.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(resultsV)
    view.addSubview(awardView)
    resultsView = resultsV
  }

  func layoutElements() {
    guard let resultsView = resultsView else { return }
    let constraint = awardView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0)
    NSLayoutConstraint.activate([resultsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                                 resultsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                 resultsView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                                 resultsView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor,
                                                                    multiplier: AppConfig.shared.resultsViewWidth),
                                 constraint,
                                 awardView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 1, constant: -60),
                                 awardView.leftAnchor.constraint(equalTo: resultsView.rightAnchor, constant: 100),
                                 awardView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -100)
                                ])
    awardViewAnimatedConstraint = constraint
  }

  private func animateAwardViewIn() {
    guard awardView.isHidden else { return }
    awardView.alpha = 0
    awardView.isHidden = false
    awardView.setNeedsDisplay()
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
      self.awardView.alpha = 1.0
      self.awardView.layoutIfNeeded()
    } completion: { _ in
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + AppConfig.shared.awardDisplayTime) {
        self.resultsModel.reset()
      }
    }
  }

  private func animateAwardViewOut() {
    guard !awardView.isHidden else { return }
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
      self.awardView.alpha = 0.0
      self.awardView.layoutIfNeeded()
    } completion: { _ in
      self.awardView.isHidden = true
    }

  }

  @discardableResult
  func setupVision() -> NSError? {
    // Setup Vision parts
    let error: NSError! = nil
    guard let model = visionModel else {
      print("no model available")
      return nil
    }
    let objectRecognition = VNCoreMLRequest(model: model, completionHandler: { (request, _) in
      DispatchQueue.main.async(execute: {
        // perform all the UI updates on the main queue
        if let results = request.results {
          self.drawVisionRequestResults(results)
        }
      })
    })
    objectRecognition.imageCropAndScaleOption = .scaleFit
    self.requests = [objectRecognition]

    return error
  }

  func drawVisionRequestResults(_ results: [Any]) {
    updateDetectionLayerBounds()
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    detectionOverlay?.sublayers = nil // remove all the old recognized objects

    _ = exifOrientationFromDeviceOrientation() // to update previousOrientation

    if previousOrientation != nil && previousOrientation != .landscapeLeft {
      // only detect in landscapeLeft orientation
      CATransaction.commit()
      return
    }

    var currentObservations: [String: [PastObservation]] = [:]
    for observation in results where observation is VNRecognizedObjectObservation {
      guard let objectObservation = observation as? VNRecognizedObjectObservation else {
        print("Observation was not vnregoniz")
        continue
      }

      // Select only the label with the highest confidence.
      let topLabelObservation = objectObservation.labels[0]

      // Do not show classes that are not in config
      guard knownClasses.contains(topLabelObservation.identifier) else {
        continue
      }

      let objectBounds: CGRect
      var oobb = objectObservation.boundingBox

      // Adjust the bounding box to fit in the available window
      // and skip the observations where more than 80% land under the results UI

      let resultPortion = AppConfig.shared.resultsViewWidth
      let uiOverlap = CGRect.init(x: 0, y: 0, width: resultPortion, height: 1.0).overlapFractionWith(oobb)
      if oobb.minX < resultPortion {
        if oobb.maxX > resultPortion && uiOverlap < 0.75 {
          let adjustX = resultPortion - oobb.origin.x
          oobb.size.width -= adjustX
          oobb.origin.x = resultPortion
        } else {
          continue // not in bounds
        }
      }
      let currentObs = PastObservation(observation: objectObservation)

      // Find past observations, if any, and check if the current bounding box is close enough
      if let priorObservations = observationHistory[topLabelObservation.identifier], !priorObservations.isEmpty {
        let match = priorObservations.filter { $0.observation.boundingBox.intersectionFractionWith(
          objectObservation.boundingBox) > AppConfig.shared.requiredIntersection }

        if let closeEnough = match.first {
          currentObs.firstDetected = closeEnough.firstDetected
        }
      }
      if currentObservations[topLabelObservation.identifier] == nil {
        currentObservations[topLabelObservation.identifier] = [currentObs]
      } else {
        currentObservations[topLabelObservation.identifier]?.append(currentObs)
      }

      // transform the resulting boxes 90 degrees clockwise around the center of the box to get the result mapped on
      // what we are seeing on screen
      let xfrm = CGAffineTransform(translationX: 0.5, y: 0.5).rotated(by: 90 * .pi/180).translatedBy(x: -0.5, y: -0.5)
      oobb = oobb.applying(xfrm)

      objectBounds = VNImageRectForNormalizedRect(oobb, Int(bufferSize.height), Int(bufferSize.width))

      let objectTimerPassed = currentObs.age() > AppConfig.shared.objectTimerLength
      let classid = currentObs.observation.labels[0].identifier
      let objectIsTarget = resultsModel.soughtClasses.contains(classid)
      if objectIsTarget {
        if objectTimerPassed {
          if !resultsModel.foundClasses.contains(classid) {
            resultsModel.foundClasses.append(classid)
          }
          resultsModel.setProgress(classId: classid, progress: 1)
        } else {
          let fraction = currentObs.age() < AppConfig.shared.objectTimerLength ? currentObs.age() / AppConfig.shared.objectTimerLength : 1
          resultsModel.setProgress(classId: classid, progress: fraction)
        }
      }

      let flashed = resultsModel.flashedClasses.contains(classid)
      let oColor: UIColor = AppConfig.shared.color(topLabelObservation.identifier)
      let tColor: UIColor = AppConfig.shared.objectTextUIColor
      let opacity = objectIsTarget && objectTimerPassed && !flashed ? 1 - (currentObs.age() - AppConfig.shared.objectTimerLength) : 0
      if opacity <= 0 && objectTimerPassed {
        if !resultsModel.flashedClasses.contains(classid) {
            resultsModel.flashedClasses.append(classid)
        }
      }
      let borderW = AppConfig.shared.borderWidth
      let cornerR = AppConfig.shared.cornerRadius
      let shapeLayer = self.annotationBuilder.createObjectLayer(objectBounds, color: oColor,
                                                                borderWidth: borderW, cornerRadius: cornerR,
                                                                fillOpacity: opacity)
      let labelString = topLabelObservation.identifier.localized()

      let textLayer = self.annotationBuilder.createObjectTextLayer(objectBounds,
                                                      identifier: labelString,
                                                      confidence: topLabelObservation.confidence,
                                                      color: oColor,
                                                      textColor: tColor)

      shapeLayer.addSublayer(textLayer)

      if resultsModel.soughtClasses.contains(classid) {
        let timeLayer = self.annotationBuilder.createObjectTimerLayer(objectBounds, type: AppConfig.shared.objectTimerType,
                                                                    elapsed: resultsModel.foundClasses.contains(classid) ? 100 : currentObs.age(),
                                                                      color: AppConfig.shared.objectTextUIColor.withAlphaComponent(1).cgColor)
        shapeLayer.addSublayer(timeLayer)
      }
      detectionOverlay?.addSublayer(shapeLayer)
    }
    observationHistory = currentObservations
    self.updateLayerGeometry()
    CATransaction.commit()
  }

  override func startCapturing() {
    super.startCapturing()
    videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard !resultsModel.missionComplete else {
      return
    }
#if !targetEnvironment(simulator)
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    let exifOrientation = exifOrientationFromDeviceOrientation()

    let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
    do {
      try imageRequestHandler.perform(self.requests)
    } catch {
      print(error)
    }

#else
    print("I am simulator")
#endif
  }

  func updateLayerGeometry() {
    let bounds = rootLayer?.bounds ?? CGRect.init(x: 0, y: 0, width: 0, height: 0)
    var scale: CGFloat

    let xScale: CGFloat
    let yScale: CGFloat

        xScale = bounds.size.width / bufferSize.width
        yScale = bounds.size.height / bufferSize.height
    scale = fmax(xScale, yScale)

    if scale.isInfinite {
      scale = 1.0
    }
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)

    // rotate the layer into screen orientation and scale and mirror
    detectionOverlay?.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))

    // center the layer
    detectionOverlay?.position = CGPoint(x: bounds.midX, y: bounds.midY)

    CATransaction.commit()

  }

  func setupLayers() {
    guard detectionOverlay == nil else {
      updateDetectionLayerBounds()
      return
    }
    detectionOverlay?.sublayers = nil
    detectionOverlay = CALayer() // container layer that has all the renderings of the observations
    detectionOverlay?.name = "DetectionOverlay"

    rootLayer?.addSublayer(detectionOverlay!)
    updateDetectionLayerBounds()
  }

  func updateDetectionLayerBounds() {
    detectionOverlay?.bounds = CGRect(x: 0.0,
                                      y: 0.0,
                                      width: bufferSize.height,
                                      height: bufferSize.width)
    detectionOverlay?.position = CGPoint(x: rootLayer?.bounds.midX ?? 0, y: rootLayer?.bounds.midY ?? 0)
  }
}
