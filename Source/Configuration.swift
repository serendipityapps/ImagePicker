import AVFoundation
import UIKit

open class Configuration {

  // MARK: Colors

  public var backgroundColor = UIColor(red: 0.15, green: 0.19, blue: 0.24, alpha: 1)
  public var gallerySeparatorColor = UIColor.black.withAlphaComponent(0.6)
	public var galleryBackgroundColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
  public var mainColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
  public var noImagesTextColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1)
  public var noCameraTextColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1)
  public var settingsColor = UIColor.white
	
	public var cameraControlTintColor = UIColor.white

	public var bottomContainerColor = UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1)
	public var cameraShutterControlBackgroundColor = UIColor.white
	public var cameraShutterControlHighlightBackgroundColor = UIColor.gray
	public var cameraShutterControlTextColor = UIColor.black
	public var photosToUseBorderColor = UIColor.white
	public var cancelButtonTextColor = UIColor.gray
	public var cancelButtonBackgroundColor = UIColor.black
	public var cancelButtonHighlightBackgroundColor = UIColor.gray
	public var doneButtonTextColor = UIColor.white
	public var doneButtonBackgroundColor = UIColor.black
	public var doneButtonHighlightBackgroundColor = UIColor.gray
	public var infoLabelTextColor = UIColor.white
	public var infoLabelShadowTextColor = UIColor.darkGray
	public var numberBadgeBackgroundColor = UIColor.red
	public var numberBadgeTextColor = UIColor.white

  // MARK: Fonts

  public var numberLabelFont = UIFont.systemFont(ofSize: 19, weight: UIFont.Weight.bold)
  public var doneButtonFont = UIFont.systemFont(ofSize: 19, weight: UIFont.Weight.medium)
  public var flashButtonFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
  public var noImagesFont = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
  public var noCameraFont = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
  public var settingsFont = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
	public var infoTextLabelFont = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
	public var numberBadgeFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.bold)

  // MARK: Titles

  public var OKButtonTitle = "OK"
  public var cancelButtonTitle = "Cancel"
  public var doneButtonTitle = "Done"
  public var noImagesTitle = "No images available"
  public var noCameraTitle = "Camera is not available"
  public var settingsTitle = "Settings"
  public var requestPermissionTitle = "Permission denied"
  public var requestPermissionMessage = "Please, allow the application to access to your photo library."
	
	public var flashButtonTitleAUTO = "AUTO"
	public var flashButtonTitleON = "ON"
	public var flashButtonTitleOFF = "OFF"

	public var infoLabelText = ""

  // MARK: Dimensions

  public var cellSpacing: CGFloat = 2
  public var indicatorWidth: CGFloat = 41
  public var indicatorHeight: CGFloat = 8
	public var galleryHeight: CGFloat = 160
	public var galleryBarHeight: CGFloat = 24
	public var stackViewStepOffset: CGFloat = -3.0
	public var stackViewImageSize: CGSize = CGSize(width: 78, height: 78)
	public var stackViewBorderWidth: CGFloat = 1.0
	public var stackViewCornerRadius: CGFloat = 3.0

  // MARK: Custom behaviour

  public var canRotateCamera = true
  public var recordLocation = true
  public var allowMultiplePhotoSelection = true
  public var allowVideoSelection = false
  public var showsImageCountLabel = true
  public var flashButtonAlwaysHidden = false
  public var allowPinchToZoom = true
  public var allowedOrientations = UIInterfaceOrientationMask.all
	public var cameraHasOverlay = true

	public var cancelButtonHandler: (() -> Void)?
	public var doneButtonHandler: (() -> Void)?

	public var numberOfImagesAllowedInStackView: Int = 3
	
  // MARK: Images
  public var indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.white.withAlphaComponent(0.6)
    view.layer.cornerRadius = 4
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

	public var flashButtonImageAUTO = AssetManager.getImage("AUTO")
	public var flashButtonImageON = AssetManager.getImage("ON")
	public var flashButtonImageOFF = AssetManager.getImage("OFF")
	
	public var cameraRotationIconImage = AssetManager.getImage("cameraIcon")

	public var overlayTopLeftCornerPiece = AssetManager.getImage("cameraIcon")
	
	private let collectionCellReuseIdentifier = "CollectionViewReusableIdentifier"
	
	/// Override these methods to provide custom cells and selection
	open func registerCollectionViewCell(in collectionView: UICollectionView) {
		collectionView.register(ImageGalleryViewCell.self,
														forCellWithReuseIdentifier: collectionCellReuseIdentifier)
	}
	
	open func imageGalleryView(_ imageGalleryView: ImageGalleryView, _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionCellReuseIdentifier,
																												for: indexPath) as? ImageGalleryViewCell else { return UICollectionViewCell() }
		
		guard let asset = imageGalleryView.fetchResult?.object(at: (indexPath as NSIndexPath).row) else {
			return cell
		}

		AssetManager.resolveAsset(asset, size: CGSize(width: 160, height: 240)) { image in
			if let image = image {
				cell.configureCell(image.image)
				
				if (indexPath as NSIndexPath).row == 0 && imageGalleryView.shouldTransform {
					cell.transform = CGAffineTransform(scaleX: 0, y: 0)
					
					UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions(), animations: {
						cell.transform = CGAffineTransform.identity
					}) { _ in }
					
					imageGalleryView.shouldTransform = false
				}
				
				if imageGalleryView.selectedStack.containsAsset(asset) {
					cell.selectedImageView.image = AssetManager.getImage("selectedImageGallery")
					cell.selectedImageView.alpha = 1
					cell.selectedImageView.transform = CGAffineTransform.identity
				} else {
					cell.selectedImageView.image = nil
				}
				cell.duration = asset.duration
			}
		}
		
		return cell
	}

	open func imageGalleryView(_ imageGalleryView: ImageGalleryView, _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		
		guard let cell = collectionView.cellForItem(at: indexPath)
			as? ImageGalleryViewCell else { return }
		if self.allowMultiplePhotoSelection == false {
			// Clear selected photos array
			for asset in imageGalleryView.selectedStack.assets {
				imageGalleryView.selectedStack.dropAsset(asset)
			}
			// Animate deselecting photos for any selected visible cells
			guard let visibleCells = collectionView.visibleCells as? [ImageGalleryViewCell] else { return }
			for cell in visibleCells where cell.selectedImageView.image != nil {
				UIView.animate(withDuration: 0.2, animations: {
					cell.selectedImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
				}, completion: { _ in
					cell.selectedImageView.image = nil
				})
			}
		}
		
		guard let asset = imageGalleryView.fetchResult?.object(at: (indexPath as NSIndexPath).row) else {
			return
		}
		
		AssetManager.resolveAsset(asset, size: CGSize(width: 100, height: 100)) { image in
			guard image != nil else { return }
			
			if cell.selectedImageView.image != nil {
				UIView.animate(withDuration: 0.2, animations: {
					cell.selectedImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
				}, completion: { _ in
					cell.selectedImageView.image = nil
				})
				imageGalleryView.selectedStack.dropAsset(asset)
			} else if imageGalleryView.imageLimit == 0 || imageGalleryView.imageLimit > imageGalleryView.selectedStack.assets.count {
				cell.selectedImageView.image = AssetManager.getImage("selectedImageGallery")
				cell.selectedImageView.transform = CGAffineTransform(scaleX: 0, y: 0)
				UIView.animate(withDuration: 0.2, animations: {
					cell.selectedImageView.transform = CGAffineTransform.identity
				})
				imageGalleryView.selectedStack.pushAsset(asset)
			}
		}
	}
	
  public init() {}
}

// MARK: - Orientation
extension Configuration {

  public var rotationTransform: CGAffineTransform {
    let currentOrientation = UIDevice.current.orientation

    // check if current orientation is allowed
    switch currentOrientation {
    case .portrait:
      if allowedOrientations.contains(.portrait) {
        Helper.previousOrientation = currentOrientation
      }
    case .portraitUpsideDown:
      if allowedOrientations.contains(.portraitUpsideDown) {
        Helper.previousOrientation = currentOrientation
      }
    case .landscapeLeft:
      if allowedOrientations.contains(.landscapeLeft) {
        Helper.previousOrientation = currentOrientation
      }
    case .landscapeRight:
      if allowedOrientations.contains(.landscapeRight) {
        Helper.previousOrientation = currentOrientation
      }
    default: break
    }

    // set default orientation if current orientation is not allowed
    if Helper.previousOrientation == .unknown {
      if allowedOrientations.contains(.portrait) {
        Helper.previousOrientation = .portrait
      } else if allowedOrientations.contains(.landscapeLeft) {
        Helper.previousOrientation = .landscapeLeft
      } else if allowedOrientations.contains(.landscapeRight) {
        Helper.previousOrientation = .landscapeRight
      } else if allowedOrientations.contains(.portraitUpsideDown) {
        Helper.previousOrientation = .portraitUpsideDown
      }
    }

    return Helper.getTransform(fromDeviceOrientation: Helper.previousOrientation)
}

}
