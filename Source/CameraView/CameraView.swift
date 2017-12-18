import UIKit
import AVFoundation
import PhotosUI

protocol CameraViewDelegate: class {

  func setFlashButtonHidden(_ hidden: Bool)
  func imageToLibrary()
  func cameraNotAvailable()
}

public class CameraView: UIViewController, CLLocationManagerDelegate, CameraManDelegate {

	var configuration = Configuration()

	public func startCamera() {
		cameraMan.checkPermission()
	}

	public func stopCamera() {
		cameraMan.stop()
	}

  lazy var blurView: UIVisualEffectView = { [unowned self] in
    let effect = UIBlurEffect(style: .dark)
    let blurView = UIVisualEffectView(effect: effect)

    return blurView
    }()

  lazy var focusImageView: UIImageView = { [unowned self] in
    let imageView = UIImageView()
    imageView.image = AssetManager.getImage("focusIcon")
    imageView.backgroundColor = UIColor.clear
    imageView.frame = CGRect(x: 0, y: 0, width: 110, height: 110)
    imageView.alpha = 0

    return imageView
    }()

  lazy var capturedImageView: UIView = { [unowned self] in
    let view = UIView()
    view.backgroundColor = UIColor.black
    view.alpha = 0

    return view
    }()

  lazy var containerView: UIView = {
    let view = UIView()
    view.alpha = 0

    return view
  }()

	lazy var overlayView: OverlayView = {
		let bundle = Bundle(for: OverlayView.self)
		let nib = UINib(nibName: "OverlayView", bundle: bundle)
		let view = nib.instantiate(withOwner: self, options: nil).first as! OverlayView
		view.backgroundColor = UIColor.clear
		view.viewPortContainerView.backgroundColor = UIColor.clear
		view.topleftImageView.image = self.configuration.overlayTopLeftCornerPiece
		view.topRightImageView.image = self.configuration.overlayTopLeftCornerPiece
		view.bottomleftImageView.image = self.configuration.overlayTopLeftCornerPiece
		view.bottomRightImageView.image = self.configuration.overlayTopLeftCornerPiece
		return view
	}()

	public var overlayTopConstraint: NSLayoutConstraint?
	public var overlayBottomConstraint: NSLayoutConstraint?

  lazy var noCameraLabel: UILabel = { [unowned self] in
    let label = UILabel()
    label.font = self.configuration.noCameraFont
    label.textColor = self.configuration.noCameraTextColor
    label.text = self.configuration.noCameraTitle
    label.sizeToFit()

    return label
    }()

  lazy var noCameraButton: UIButton = { [unowned self] in
    let button = UIButton(type: .system)
    let title = NSAttributedString(string: self.configuration.settingsTitle,
      attributes: [
        NSAttributedStringKey.font: self.configuration.settingsFont,
        NSAttributedStringKey.foregroundColor: self.configuration.settingsColor
      ])

    button.setAttributedTitle(title, for: UIControlState())
    button.contentEdgeInsets = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 5.0, right: 10.0)
    button.sizeToFit()
    button.layer.borderColor = self.configuration.settingsColor.cgColor
    button.layer.borderWidth = 1
    button.layer.cornerRadius = 4
    button.addTarget(self, action: #selector(settingsButtonDidTap), for: .touchUpInside)

    return button
    }()

  lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(tapGestureRecognizerHandler(_:)))

    return gesture
    }()

  lazy var pinchGestureRecognizer: UIPinchGestureRecognizer = { [unowned self] in
    let gesture = UIPinchGestureRecognizer()
    gesture.addTarget(self, action: #selector(pinchGestureRecognizerHandler(_:)))

    return gesture
    }()

  let cameraMan = CameraMan()

  var previewLayer: AVCaptureVideoPreviewLayer?
  weak var delegate: CameraViewDelegate?
  var animationTimer: Timer?
  var locationManager: LocationManager?
  var startOnFrontCamera: Bool = false

  private let minimumZoomFactor: CGFloat = 1.0
  private let maximumZoomFactor: CGFloat = 3.0

  private var currentZoomFactor: CGFloat = 1.0
  private var previousZoomFactor: CGFloat = 1.0

  public init(configuration: Configuration? = nil) {
    if let configuration = configuration {
      self.configuration = configuration
		} else {
			self.configuration = Configuration()
		}
    super.init(nibName: nil, bundle: nil)
  }

	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
  }

	override public func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = configuration.mainColor

    view.addSubview(containerView)
    containerView.addSubview(blurView)
    [focusImageView, capturedImageView].forEach {
      view.addSubview($0)
    }

		if configuration.cameraHasOverlay {

			overlayView.frame = view.bounds
			overlayView.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(overlayView)

			self.overlayTopConstraint = NSLayoutConstraint(item: overlayView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0)
			let leading = NSLayoutConstraint(item: overlayView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0)

			let trailing = NSLayoutConstraint(item: overlayView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0)
			self.overlayBottomConstraint = NSLayoutConstraint(item: overlayView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)

			NSLayoutConstraint.activate([trailing, overlayBottomConstraint!, overlayTopConstraint!, leading])
		}

    view.addGestureRecognizer(tapGestureRecognizer)

    if configuration.allowPinchToZoom {
      view.addGestureRecognizer(pinchGestureRecognizer)
    }

    cameraMan.delegate = self
    cameraMan.setup(self.startOnFrontCamera)
  }

	override public func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    previewLayer?.connection?.videoOrientation = .portrait
  }

	override public func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
  }

  func setupPreviewLayer() {
    let layer = AVCaptureVideoPreviewLayer(session: cameraMan.session)

    layer.backgroundColor = configuration.mainColor.cgColor
    layer.autoreverses = true
    layer.videoGravity = AVLayerVideoGravity.resizeAspectFill

    view.layer.insertSublayer(layer, at: 0)
    layer.frame = view.layer.frame
    view.clipsToBounds = true

    previewLayer = layer
  }

  // MARK: - Layout

	override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let centerX = view.bounds.width / 2

    noCameraLabel.center = CGPoint(x: centerX,
      y: view.bounds.height / 2 - 80)

    noCameraButton.center = CGPoint(x: centerX,
      y: noCameraLabel.frame.maxY + 20)

    blurView.frame = view.bounds
    containerView.frame = view.bounds
    capturedImageView.frame = view.bounds
  }

  // MARK: - Actions

  @objc func settingsButtonDidTap() {
    DispatchQueue.main.async {
      if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
        UIApplication.shared.openURL(settingsURL)
      }
    }
  }

  // MARK: - Camera actions

  func rotateCamera() {
    UIView.animate(withDuration: 0.3, animations: {
      self.containerView.alpha = 1
      }, completion: { _ in
        self.cameraMan.switchCamera {
          UIView.animate(withDuration: 0.7, animations: {
            self.containerView.alpha = 0
          })
        }
    })
  }

  func flashCamera(_ title: String) {
    let mapping: [String: AVCaptureDevice.FlashMode] = [
      self.configuration.flashButtonTitleON: .on,
      self.configuration.flashButtonTitleOFF: .off
    ]

    cameraMan.flash(mapping[title] ?? .auto)
  }

  func takePicture(_ completion: @escaping () -> Void) {
    guard let previewLayer = previewLayer else {
			completion()
			return
		}

    UIView.animate(withDuration: 0.1, animations: {
      self.capturedImageView.alpha = 1
      }, completion: { _ in
        UIView.animate(withDuration: 0.1, animations: {
          self.capturedImageView.alpha = 0
        })
    })

		var cropRect: CGRect?
		if configuration.cameraHasOverlay {
			cropRect = previewLayer.convert(overlayView.viewPortContainerView.frame, from: overlayView.layer)
		}
		cameraMan.takePhoto(previewLayer, location: locationManager?.latestLocation, cropRect: cropRect) {
      completion()
      self.delegate?.imageToLibrary()
    }
  }

  // MARK: - Timer methods

  @objc func timerDidFire() {
    UIView.animate(withDuration: 0.3, animations: { [unowned self] in
      self.focusImageView.alpha = 0
      }, completion: { _ in
        self.focusImageView.transform = CGAffineTransform.identity
    })
  }

  // MARK: - Camera methods

  func focusTo(_ point: CGPoint) {
    let convertedPoint = CGPoint(x: point.x / UIScreen.main.bounds.width,
                                 y: point.y / UIScreen.main.bounds.height)

    cameraMan.focus(convertedPoint)

    focusImageView.center = point
    UIView.animate(withDuration: 0.5, animations: {
      self.focusImageView.alpha = 1
      self.focusImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
      }, completion: { _ in
        self.animationTimer = Timer.scheduledTimer(timeInterval: 1, target: self,
          selector: #selector(CameraView.timerDidFire), userInfo: nil, repeats: false)
    })
  }

  func zoomTo(_ zoomFactor: CGFloat) {
    guard let device = cameraMan.currentInput?.device else { return }

    let maximumDeviceZoomFactor = device.activeFormat.videoMaxZoomFactor
    let newZoomFactor = previousZoomFactor * zoomFactor
    currentZoomFactor = min(maximumZoomFactor, max(minimumZoomFactor, min(newZoomFactor, maximumDeviceZoomFactor)))

    cameraMan.zoom(currentZoomFactor)
  }

  // MARK: - Tap

  @objc func tapGestureRecognizerHandler(_ gesture: UITapGestureRecognizer) {
    let touch = gesture.location(in: view)

    focusImageView.transform = CGAffineTransform.identity
    animationTimer?.invalidate()
    focusTo(touch)
  }

  // MARK: - Pinch

  @objc func pinchGestureRecognizerHandler(_ gesture: UIPinchGestureRecognizer) {
    switch gesture.state {
    case .began:
      fallthrough
    case .changed:
      zoomTo(gesture.scale)
    case .ended:
      zoomTo(gesture.scale)
      previousZoomFactor = currentZoomFactor
    default: break
    }
  }

  // MARK: - Private helpers

  func showNoCamera(_ show: Bool) {
    [noCameraButton, noCameraLabel].forEach {
      show ? view.addSubview($0) : $0.removeFromSuperview()
    }
  }

  // CameraManDelegate
  func cameraManNotAvailable(_ cameraMan: CameraMan) {
    showNoCamera(true)
    focusImageView.isHidden = true
    delegate?.cameraNotAvailable()
  }

  func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput) {
    if !configuration.flashButtonAlwaysHidden {
      delegate?.setFlashButtonHidden(!input.device.hasFlash)
    }
  }

  func cameraManDidStart(_ cameraMan: CameraMan) {
		if configuration.recordLocation {
			locationManager = LocationManager()
		}
		locationManager?.startUpdatingLocation()
    setupPreviewLayer()
		previewLayer?.connection?.videoOrientation = .portrait
  }

	func cameraManDidStop(_ cameraMan: CameraMan) {
		locationManager?.stopUpdatingLocation()
		self.locationManager = nil
		previewLayer?.removeFromSuperlayer()
		self.previewLayer = nil
	}
}
