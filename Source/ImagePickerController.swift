import UIKit
import MediaPlayer
import Photos

@objc public protocol ImagePickerDelegate: class {

  func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage])
  func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage])
  func cancelButtonDidPress(_ imagePicker: ImagePickerController)
}

open class ImagePickerController: UIViewController {

  let configuration: Configuration

  struct GestureConstants {
    static let maximumHeight: CGFloat = 200
    static let minimumHeight: CGFloat = 125
  }

	@IBOutlet open var galleryView: ImageGalleryView!
  @IBOutlet open var bottomContainer: BottomContainerView!
  @IBOutlet open var topView: TopView!
	@IBOutlet open var cameraBaseView: UIView!
	
	@IBOutlet var constraintGalleryHeight: NSLayoutConstraint!
	@IBOutlet var constraintTopGalleryToTopOfBottomContainer: NSLayoutConstraint!

  lazy var cameraController: CameraView = { [unowned self] in
    let controller = CameraView(configuration: self.configuration)
    controller.delegate = self
    controller.startOnFrontCamera = self.startOnFrontCamera

    return controller
    }()

  lazy var volumeView: MPVolumeView = { [unowned self] in
    let view = MPVolumeView()
    view.frame = CGRect(x: 0, y: 0, width: 1, height: 1)

    return view
    }()

  var volume = AVAudioSession.sharedInstance().outputVolume

  open weak var delegate: ImagePickerDelegate?
  open var stack = ImageStack()
  open var imageLimit = 0
  open var preferredImageSize: CGSize?
	open var resizeModeIfPreferredImageSize: PHImageRequestOptionsResizeMode = .fast
  open var startOnFrontCamera = false

  var totalSize: CGSize { return UIScreen.main.bounds.size }
  var numberOfCells: Int?

  fileprivate var isTakingPicture = false

  // MARK: - Initialization

  public required init(configuration: Configuration = Configuration()) {
    self.configuration = configuration
		let bundle = Bundle(for: ImagePickerController.self)
    super.init(nibName: "ImagePickerView", bundle: bundle)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  // MARK: - View lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()

		galleryView.configuration = self.configuration
		galleryView.configure()
		galleryView.selectedStack = self.stack
		galleryView.collectionView.layer.anchorPoint = CGPoint(x: 0, y: 0)
		galleryView.imageLimit = self.imageLimit

		bottomContainer.configuration = self.configuration
		bottomContainer.configure()
		bottomContainer.backgroundColor = self.configuration.bottomContainerColor
		bottomContainer.delegate = self

		topView.configuration = self.configuration
		topView.configure()
		topView.backgroundColor = UIColor.clear
		topView.delegate = self
		
		cameraController.configuration = self.configuration
		cameraController.view.frame = cameraBaseView.bounds
		cameraController.view.translatesAutoresizingMaskIntoConstraints = false
		cameraBaseView.addSubview(cameraController.view)

		let top = NSLayoutConstraint(item: cameraController.view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: cameraBaseView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0)
		let leading = NSLayoutConstraint(item: cameraController.view, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: cameraBaseView, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0)
		let trailing = NSLayoutConstraint(item: cameraController.view, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: cameraBaseView, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0)
		let bottom = NSLayoutConstraint(item: cameraController.view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: cameraBaseView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)
		
		NSLayoutConstraint.activate([trailing, bottom, top, leading])
		
    view.addSubview(volumeView)
    view.sendSubview(toBack: volumeView)

    view.backgroundColor = UIColor.white
    view.backgroundColor = configuration.mainColor

    subscribe()
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if configuration.managesAudioSession {
      _ = try? AVAudioSession.sharedInstance().setActive(true)
    }

		self.setNeedsStatusBarAppearanceUpdate()
		
		applyOrientationTransforms()
		
		self.galleryView.displayNoImagesMessage(false)
		
		self.view.layoutIfNeeded()
		
		let galleryHeight: CGFloat = min(GestureConstants.maximumHeight, max(GestureConstants.minimumHeight, configuration.galleryHeight))
		constraintGalleryHeight.constant = galleryHeight

		galleryView.updateFrames()
		galleryView.collectionViewLayout.invalidateLayout()
		self.updateGalleryViewFrames(galleryHeight)
		self.galleryView.collectionView.transform = CGAffineTransform.identity
		self.galleryView.collectionView.contentInset = UIEdgeInsets.zero
		self.view.layoutIfNeeded()		
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

		checkStatus()

    applyOrientationTransforms()
  }

  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }

  open func resetAssets() {
    self.stack.resetAssets([])
  }

  func checkStatus() {
    let currentStatus = PHPhotoLibrary.authorizationStatus()
    guard currentStatus != .authorized else { return }

    if currentStatus == .notDetermined { hideViews() }

    PHPhotoLibrary.requestAuthorization { (authorizationStatus) -> Void in
      DispatchQueue.main.async {
        if authorizationStatus == .denied {
					self.galleryView.displayNoImagesMessage(true)
          self.presentAskPermissionAlert()
        } else if authorizationStatus == .authorized {
          self.permissionGranted()
        }
      }
    }
  }

  func presentAskPermissionAlert() {
    let alertController = UIAlertController(title: configuration.requestPermissionTitle, message: configuration.requestPermissionMessage, preferredStyle: .alert)

    let alertAction = UIAlertAction(title: configuration.OKButtonTitle, style: .default) { _ in
      if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
        UIApplication.shared.openURL(settingsURL)
      }
    }

    let cancelAction = UIAlertAction(title: configuration.cancelButtonTitle, style: .cancel) { _ in
      self.dismiss(animated: true, completion: nil)
    }

    alertController.addAction(alertAction)
    alertController.addAction(cancelAction)

    present(alertController, animated: true, completion: nil)
  }

  func hideViews() {
    enableGestures(false)
  }

  func permissionGranted() {
    galleryView.fetchPhotos()
    enableGestures(true)
  }

  // MARK: - Notifications

  deinit {
    if configuration.managesAudioSession {
      _ = try? AVAudioSession.sharedInstance().setActive(false)
    }

    NotificationCenter.default.removeObserver(self)
  }

  func subscribe() {
    NotificationCenter.default.addObserver(self,
      selector: #selector(adjustButtonTitle(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.imageDidPush),
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(adjustButtonTitle(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.imageDidDrop),
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(didReloadAssets(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.stackDidReload),
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(volumeChanged(_:)),
      name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(handleRotation(_:)),
      name: NSNotification.Name.UIDeviceOrientationDidChange,
      object: nil)
  }

  @objc func didReloadAssets(_ notification: Notification) {
    adjustButtonTitle(notification)
    galleryView.collectionView.reloadData()
    galleryView.collectionView.setContentOffset(CGPoint.zero, animated: false)
  }

  @objc func volumeChanged(_ notification: Notification) {
    guard let slider = volumeView.subviews.filter({ $0 is UISlider }).first as? UISlider,
      let userInfo = (notification as NSNotification).userInfo,
      let changeReason = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String, changeReason == "ExplicitVolumeChange" else { return }

    slider.setValue(volume, animated: false)
    takePicture()
  }

  @objc func adjustButtonTitle(_ notification: Notification) {
    guard let sender = notification.object as? ImageStack else { return }

		bottomContainer.configureActionButton(!sender.assets.isEmpty)
  }

  // MARK: - Helpers

  open override var prefersStatusBarHidden: Bool {
    return true
  }
	
	open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
		return .fade
	}
	
  func updateGalleryViewFrames(_ constant: CGFloat) {
    constraintTopGalleryToTopOfBottomContainer.constant = constant
    constraintGalleryHeight.constant = constant

		cameraController.overlayTopConstraint?.constant = topView.frame.maxY
		cameraController.overlayBottomConstraint?.constant = -constant
  }

  func enableGestures(_ enabled: Bool) {
    galleryView.alpha = enabled ? 1 : 0
    bottomContainer.pickerButton.isEnabled = enabled
    bottomContainer.tapGestureRecognizer.isEnabled = enabled
    topView.flashButton.isEnabled = enabled
    topView.rotateCamera.isEnabled = configuration.canRotateCamera
  }

  fileprivate func isBelowImageLimit() -> Bool {
    return (imageLimit == 0 || imageLimit > galleryView.selectedStack.assets.count)
    }

  fileprivate func takePicture() {
    guard isBelowImageLimit() && !isTakingPicture else { return }
    isTakingPicture = true
    bottomContainer.pickerButton.isEnabled = false
    bottomContainer.stackView.startLoader()
    let action: () -> Void = { [unowned self] in
      self.cameraController.takePicture { self.isTakingPicture = false }
    }

		action()
  }
}

// MARK: - Action methods

extension ImagePickerController: BottomContainerViewDelegate {

  func pickerButtonDidPress() {
    takePicture()
  }

  func doneButtonDidPress() {
    var images: [UIImage]
    if let preferredImageSize = preferredImageSize {
      images = AssetManager.resolveAssets(stack.assets, size: preferredImageSize, resizeMode: resizeModeIfPreferredImageSize)
    } else {
      images = AssetManager.resolveAssets(stack.assets)
    }

		self.configuration.doneButtonHandler?()
    delegate?.doneButtonDidPress(self, images: images)
  }

  func cancelButtonDidPress() {
		self.configuration.cancelButtonHandler?()
    delegate?.cancelButtonDidPress(self)
  }

  func imageStackViewDidPress() {
    var images: [UIImage]
    if let preferredImageSize = preferredImageSize {
			images = AssetManager.resolveAssets(stack.assets, size: preferredImageSize, resizeMode: resizeModeIfPreferredImageSize)
    } else {
        images = AssetManager.resolveAssets(stack.assets)
    }

    delegate?.wrapperDidPress(self, images: images)
  }
}

extension ImagePickerController: CameraViewDelegate {

  func setFlashButtonHidden(_ hidden: Bool) {
    if configuration.flashButtonAlwaysHidden {
      topView.flashButton.isHidden = hidden
    }
  }

  func imageToLibrary() {
    guard let collectionSize = galleryView.collectionSize else { return }

    galleryView.fetchPhotos {
      guard let asset = self.galleryView.assets.first else { return }
      if self.configuration.allowMultiplePhotoSelection == false {
        self.stack.assets.removeAll()
      }
      self.stack.pushAsset(asset)
    }

    galleryView.shouldTransform = true
    bottomContainer.pickerButton.isEnabled = true

    UIView.animate(withDuration: 0.3, animations: {
      self.galleryView.collectionView.transform = CGAffineTransform(translationX: collectionSize.width, y: 0)
      }, completion: { _ in
        self.galleryView.collectionView.transform = CGAffineTransform.identity
    })
  }

  func cameraNotAvailable() {
    topView.flashButton.isHidden = true
    topView.rotateCamera.isHidden = true
    bottomContainer.pickerButton.isEnabled = false
  }

  // MARK: - Rotation

  open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }

  @objc public func handleRotation(_ note: Notification?) {
    applyOrientationTransforms()
  }

  func applyOrientationTransforms() {
    UIView.animate(withDuration: 0.25, animations: {
      self.galleryView.collectionViewLayout.invalidateLayout()
    })
  }
}

// MARK: - TopView delegate methods

extension ImagePickerController: TopViewDelegate {

  func flashButtonDidPress(_ title: String) {
    cameraController.flashCamera(title)
  }

  func rotateDeviceDidPress() {
    cameraController.rotateCamera()
  }
}
