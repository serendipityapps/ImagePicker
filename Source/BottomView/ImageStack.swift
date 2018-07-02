import UIKit
import Photos

open class ImageStack {

  public struct Notifications {
    public static let imageDidPush = "imageDidPush"
    public static let imageDidDrop = "imageDidDrop"
    public static let stackDidReload = "stackDidReload"
  }

	let cachingImageManager = PHCachingImageManager()
	open var assets: [PHAsset] = [] {
		willSet {
			cachingImageManager.stopCachingImagesForAllAssets()
		}
		didSet {
			let requestOptions = PHImageRequestOptions()
			requestOptions.isNetworkAccessAllowed = true
			requestOptions.deliveryMode = .highQualityFormat
			requestOptions.version = .current
			cachingImageManager.startCachingImages(for: self.assets,
																											targetSize: PHImageManagerMaximumSize,
																											contentMode: .aspectFit,
																											options: requestOptions
			)
		}
	}

  fileprivate let imageKey = "image"

  open func pushAsset(_ asset: PHAsset) {
    assets.append(asset)
    NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.imageDidPush), object: self, userInfo: [imageKey: asset])
  }

  open func dropAsset(_ asset: PHAsset) {
    assets = assets.filter {$0 != asset}
    NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.imageDidDrop), object: self, userInfo: [imageKey: asset])
  }

  open func resetAssets(_ assetsArray: [PHAsset]) {
    assets = assetsArray
    NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.stackDidReload), object: self, userInfo: nil)
  }

  open func containsAsset(_ asset: PHAsset) -> Bool {
    return assets.contains(asset)
  }
}
