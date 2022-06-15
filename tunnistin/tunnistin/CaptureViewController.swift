import UIKit
import AVFoundation
import Vision

/// CaptureViewController is responsible for the camera image stream setup and pre-processing for inference
class CaptureViewController: UIViewController {

  var bufferSize: CGSize = .zero

  lazy var cameraPreview = UIView()
  lazy var simulatorPreview = UIImageView()

  var previousOrientation: UIDeviceOrientation?

  private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  private let captureSession = AVCaptureSession()
  internal let videoDataOutput = AVCaptureVideoDataOutput()
  internal let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

  override func viewDidLoad() {
    super.viewDidLoad()
    addElements()
    layoutElements()

    // Prepare video capture
    setupCaptureSession()
    setupPreviewLayer()
    startCapturing()

    // start listening to orientation changes
    NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange),
                                           name: UIDevice.orientationDidChangeNotification, object: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startCapturing()
    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
      self.configureVideoOrientation()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }

  override func viewDidDisappear(_ animated: Bool) {
    stopCapturing()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super .traitCollectionDidChange(previousTraitCollection)
  }

  @objc private func handleOrientationChange(notification: Notification) {
    DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
      self.configureVideoOrientation()
    }
  }

  private func addElements() {
    view.addSubview(cameraPreview)
    cameraPreview.translatesAutoresizingMaskIntoConstraints = false
    cameraPreview.backgroundColor = .black

#if targetEnvironment(simulator)
    view.addSubview(simulatorPreview)
    simulatorPreview.image = UIImage.init(named: "simulatorbg")
    simulatorPreview.translatesAutoresizingMaskIntoConstraints = false
    simulatorPreview.contentMode = .scaleAspectFit
#endif
  }

  private func layoutElements() {
    NSLayoutConstraint.activate([cameraPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                                 cameraPreview.topAnchor.constraint(equalTo: view.topAnchor),
                                 cameraPreview.leftAnchor.constraint(equalTo: view.leftAnchor),
                                 cameraPreview.rightAnchor.constraint(equalTo: view.rightAnchor)])

#if targetEnvironment(simulator)
    NSLayoutConstraint.activate([simulatorPreview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                 simulatorPreview.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                 simulatorPreview.heightAnchor.constraint(equalTo: view.heightAnchor),
                                 simulatorPreview.widthAnchor.constraint(equalTo: view.widthAnchor)])
#endif
  }

  func setupCaptureSession() {
    // Set up input (only back camera alllowed)
    guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                        mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back).devices.first else {
      print("Could not get access to back camera")
      return
    }

    // Get feed from the input device
    let deviceFeed: AVCaptureDeviceInput
    do {
      deviceFeed = try AVCaptureDeviceInput(device: device)
    } catch {
      print("Could not create device input")
      return
    }

    captureSession.beginConfiguration()

    // Set preset to vga (less downscaling needed for the model)
    captureSession.sessionPreset = AVCaptureSession.Preset.vga640x480

    // Add device feed to session as input
    if captureSession.canAddInput(deviceFeed) {
      captureSession.addInput(deviceFeed)
    } else {
      captureSession.commitConfiguration()
      return
    }

    // Add output
#if !targetEnvironment(simulator)
    if captureSession.canAddOutput(videoDataOutput) {
      captureSession.addOutput(videoDataOutput)
    } else {
      captureSession.commitConfiguration()
      return
    }
#else
    captureSession.addOutput(videoDataOutput)
#endif

    // Add buffer delegate
    videoDataOutput.alwaysDiscardsLateVideoFrames = true
    videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]

    let captureConnection = videoDataOutput.connection(with: .video)
    captureConnection?.isEnabled = true
    do {
#if !targetEnvironment(simulator)
      try device.lockForConfiguration()
      let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
      let preferredZoom = AppConfig.shared.zoomFactor
      let zoomFactor = (preferredZoom > 1.0 && preferredZoom < device.activeFormat.videoMaxZoomFactor) ? preferredZoom : 1
      device.videoZoomFactor = zoomFactor
      bufferSize.width = CGFloat(dimensions.width)
      bufferSize.height = CGFloat(dimensions.height)
      print(dimensions)
      device.unlockForConfiguration()
#else
      bufferSize.width = 640
      bufferSize.height = 480
#endif
    } catch {
      print(error)
    }
    captureSession.commitConfiguration()
  }

  func startCapturing() {
    captureSession.startRunning()
  }

  func stopCapturing() {
    captureSession.stopRunning()
  }

  private func setupPreviewLayer() {
    self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
    self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait

    self.cameraPreviewLayer?.frame = cameraPreview.frame
    self.cameraPreview.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
  }

  private func configureVideoOrientation() {
    let deviceOrientation = UIDevice.current.orientation

    // For flat orientations, use what was previously used
    let orientation: UIDeviceOrientation = deviceOrientation.isPortrait || deviceOrientation.isLandscape ?
      deviceOrientation : previousOrientation ?? .landscapeLeft
    if let cameraPreviewLayer = self.cameraPreviewLayer,
       let connection = cameraPreviewLayer.connection {
      print("Configuring video orientation, device = \(orientation.rawValue)")

      if connection.isVideoOrientationSupported {
        cameraPreviewLayer.frame = self.cameraPreview.bounds
        connection.videoOrientation = .landscapeRight
      }
    } else {
      // case simulator, no connection
      cameraPreviewLayer?.frame = self.cameraPreview.bounds
    }
  }

  public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
    let curDeviceOrientation = (UIDevice.current.orientation.isFlat || !UIDevice.current.orientation.isValidInterfaceOrientation) ?
      previousOrientation ?? .landscapeLeft : UIDevice.current.orientation
    let exifOrientation: CGImagePropertyOrientation

    switch curDeviceOrientation {
    case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
      exifOrientation = .left
    case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
      exifOrientation = .up
    case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
      exifOrientation = .down
    case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
      exifOrientation = .right
    default:
      exifOrientation = .up
    }
    previousOrientation = curDeviceOrientation
    return exifOrientation
  }
}
