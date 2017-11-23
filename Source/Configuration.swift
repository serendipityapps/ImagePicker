import AVFoundation
import UIKit

public struct Configuration {

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
	public var cameraShutterControlTextColor = UIColor.black
	public var photosToUseBackgroundColor = UIColor.white
	public var photosToUseBorderColor = UIColor.white
	public var photosToUseTextColor = UIColor.white
	public var cancelButtonTextColor = UIColor.white
	public var cancelButtonBackgroundColor = UIColor.black
	public var doneButtonTextColor = UIColor.white
	public var doneButtonBackgroundColor = UIColor.black

  // MARK: Fonts

  public var numberLabelFont = UIFont.systemFont(ofSize: 19, weight: UIFont.Weight.bold)
  public var doneButtonFont = UIFont.systemFont(ofSize: 19, weight: UIFont.Weight.medium)
  public var flashButtonFont = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
  public var noImagesFont = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
  public var noCameraFont = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.medium)
  public var settingsFont = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)

  // MARK: Titles

  public var OKButtonTitle = "OK"
  public var cancelButtonTitle = "Cancel"
  public var doneButtonTitle = "Done"
  public var noImagesTitle = "No images available"
  public var noCameraTitle = "Camera is not available"
  public var settingsTitle = "Settings"
  public var requestPermissionTitle = "Permission denied"
  public var requestPermissionMessage = "Please, allow the application to access to your photo library."

  // MARK: Dimensions

  public var cellSpacing: CGFloat = 2
  public var indicatorWidth: CGFloat = 41
  public var indicatorHeight: CGFloat = 8
	public var galleryHeight: CGFloat = 160
	public var galleryBarHeight: CGFloat = 24

  // MARK: Custom behaviour

  public var canRotateCamera = true
  public var collapseCollectionViewWhileShot = true
  public var recordLocation = true
  public var allowMultiplePhotoSelection = true
  public var allowVideoSelection = false
  public var showsImageCountLabel = true
  public var flashButtonAlwaysHidden = false
  public var managesAudioSession = true
  public var allowPinchToZoom = true
  public var allowedOrientations = UIInterfaceOrientationMask.all

  // MARK: Images
  public var indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.white.withAlphaComponent(0.6)
    view.layer.cornerRadius = 4
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

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
