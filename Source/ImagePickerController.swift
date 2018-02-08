import UIKit
import MediaPlayer
import Photos

@objc public class ImagePickerImage: NSObject {

	public let image: UIImage
	public var cllocation: CLLocation?

	public init(image: UIImage, location: CLLocation?) {
		self.image = image
		self.cllocation = location
	}
}

@objc public protocol ImagePickerDelegate: class {

  func wrapperDidPress(_ imagePicker: ImagePickerController, images: [ImagePickerImage])
  func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [ImagePickerImage])
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

  lazy var cameraController: CameraView = {
    let controller = CameraView(configuration: self.configuration)
    controller.delegate = self
    controller.startOnFrontCamera = self.startOnFrontCamera
    return controller
    }()

  open weak var delegate: ImagePickerDelegate?
  open var stack = ImageStack()
  open var imageLimit = 0
  open var preferredImageSize: CGSize?
	open var resizeModeIfPreferredImageSize: PHImageRequestOptionsResizeMode = .fast
  open var startOnFrontCamera = false
	open var loadWithoutAccessingCameraOrPhotos = true
	open var isStatusBarHidden = false

	public func activate() {
			self.cameraController.startCamera()
			self.checkPhotoAccessStatus()
	}

	public func deactivate() {
			self.cameraController.stopCamera()
			self.resetAssets()
			self.galleryView.stopBeingInterestedInPhotos()
			self.galleryView.collectionView.alpha = 0
			self.isTakingPicture = false
			topView.alpha = 0
			cameraController.overlayView.alpha = 0
	}

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
		galleryView.imageGalleryUpdateDelegate = self

		bottomContainer.configuration = self.configuration
		bottomContainer.configure()
		bottomContainer.backgroundColor = self.configuration.bottomContainerColor
		bottomContainer.delegate = self

		topView.configuration = self.configuration
		topView.configure()
		topView.backgroundColor = UIColor.clear
		topView.delegate = self
		topView.alpha = 0

		cameraController.configuration = self.configuration
		self.addChildViewController(cameraController)
		cameraController.view.frame = cameraBaseView.bounds
		cameraController.view.translatesAutoresizingMaskIntoConstraints = false
		cameraBaseView.addSubview(cameraController.view)

		cameraController.overlayView.alpha = 0

		let top = NSLayoutConstraint(item: cameraController.view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: cameraBaseView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0)
		let leading = NSLayoutConstraint(item: cameraController.view, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: cameraBaseView, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0)
		let trailing = NSLayoutConstraint(item: cameraController.view, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: cameraBaseView, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0)
		let bottom = NSLayoutConstraint(item: cameraController.view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: cameraBaseView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)
		
		NSLayoutConstraint.activate([trailing, bottom, top, leading])

		cameraController.didMove(toParentViewController: self)

    view.backgroundColor = UIColor.white
    view.backgroundColor = configuration.backgroundColor

    subscribe()
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
		
		applyOrientationTransforms()

		self.view.layoutIfNeeded()
		
		let galleryHeight: CGFloat = min(GestureConstants.maximumHeight, max(GestureConstants.minimumHeight, configuration.galleryHeight))
		constraintGalleryHeight.constant = galleryHeight

		galleryView.updateFrames()
		galleryView.collectionViewLayout.invalidateLayout()
		galleryView.layoutIfNeeded()
		self.updateGalleryViewFrames()
		self.galleryView.collectionView.transform = CGAffineTransform.identity
		self.galleryView.collectionView.contentInset = UIEdgeInsets.zero
		self.view.layoutIfNeeded()		
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

		applyOrientationTransforms()

		if loadWithoutAccessingCameraOrPhotos == false {
			activate()
		}

		self.isStatusBarHidden = true
		UIView.animate(withDuration: 0.1, delay: 0, options: UIViewAnimationOptions(), animations: {
			self.setNeedsStatusBarAppearanceUpdate()
		}, completion: { (_) in

		})

		UIView.animate(withDuration: 0.25, delay: 0.3, options: UIViewAnimationOptions(), animations: {
			self.topView.alpha = 1
			self.cameraController.overlayView.alpha = 1
		}, completion: { (_) in

		})
  }

  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
		
		self.isStatusBarHidden = false

		UIView.animate(withDuration: 0.25, animations: {
			self.topView.alpha = 0
			self.cameraController.overlayView.alpha = 0
		})
  }

	open override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		galleryView.updateFrames()
		galleryView.collectionViewLayout.invalidateLayout()
		galleryView.layoutIfNeeded()
		self.updateGalleryViewFrames()
		self.galleryView.collectionView.transform = CGAffineTransform.identity
		self.galleryView.collectionView.contentInset = UIEdgeInsets.zero
	}

  open func resetAssets() {
    self.stack.resetAssets([])
  }

  func checkPhotoAccessStatus() {
    let currentStatus = PHPhotoLibrary.authorizationStatus()
    guard currentStatus != .authorized else {
			self.permissionGrantedForGallery()
			return
		}

    if currentStatus == .notDetermined { hideViews() }

    PHPhotoLibrary.requestAuthorization { (authorizationStatus) -> Void in
      DispatchQueue.main.async {
        if authorizationStatus == .denied {
					self.galleryView.collectionView.alpha = 0
					self.galleryView.updateNoImagesLabel()
					self.presentAskPermissionAlert()
        } else if authorizationStatus == .authorized {
          self.permissionGrantedForGallery()
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

  func permissionGrantedForGallery() {
		galleryView.fetchPhotos({

		})
    enableGestures(true)
  }

  // MARK: - Notifications

  deinit {
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
      selector: #selector(handleRotation(_:)),
      name: NSNotification.Name.UIDeviceOrientationDidChange,
      object: nil)
  }

  @objc func didReloadAssets(_ notification: Notification) {
    adjustButtonTitle(notification)
    galleryView.collectionView.reloadData()
    galleryView.collectionView.setContentOffset(CGPoint.zero, animated: false)
  }

  @objc func adjustButtonTitle(_ notification: Notification) {
    guard let sender = notification.object as? ImageStack else { return }

		bottomContainer.configureActionButton(!sender.assets.isEmpty)
  }

  // MARK: - Helpers

  open override var prefersStatusBarHidden: Bool {
    return isStatusBarHidden
  }
	
	open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
		return .slide
	}
	
  func updateGalleryViewFrames() {
		
		let galleryHeight: CGFloat = min(GestureConstants.maximumHeight, max(GestureConstants.minimumHeight, configuration.galleryHeight))
		
    constraintTopGalleryToTopOfBottomContainer.constant = galleryHeight
    constraintGalleryHeight.constant = galleryHeight

		cameraController.overlayTopConstraint?.constant = topView.frame.maxY
		cameraController.overlayBottomConstraint?.constant = -galleryHeight
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

	public func takePicture() {
    guard isBelowImageLimit() && !isTakingPicture else { return }
    isTakingPicture = true
    bottomContainer.pickerButton.isEnabled = false
    bottomContainer.stackView.startLoader()
		self.cameraController.takePicture { [weak self] in
			self?.isTakingPicture = false
			self?.bottomContainer.pickerButton.isEnabled = true
		}
  }
}

extension ImagePickerController: ImageGalleryUpdatedDelegate {

	func imageGalleryDidUpdate(_ changes: PHFetchResultChangeDetails<PHAsset>?) {
		guard let changes = changes else {
			return
		}
		if changes.hasIncrementalChanges {
			if let inserted = changes.insertedIndexes, inserted.count > 0 {
				if let asset = self.galleryView.fetchResult?.objects(at: inserted).first {
					if self.configuration.allowMultiplePhotoSelection == false {
						self.stack.assets.removeAll()
					}
					self.stack.pushAsset(asset)
				}
			}
			if let removed = changes.removedIndexes, removed.count > 0 {
				for asset in changes.fetchResultBeforeChanges.objects(at: removed) {
					if self.stack.assets.contains(asset) {
						self.stack.dropAsset(asset)
					}
				}
			}
		}
	}
}

// MARK: - Action methods

extension ImagePickerController: BottomContainerViewDelegate {

  func pickerButtonDidPress() {
    takePicture()
  }

  func doneButtonDidPress() {
    let images: [ImagePickerImage]
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
    let images: [ImagePickerImage]
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
			self.updateGalleryViewFrames()
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
