import Foundation
import UIKit
import Photos

open class AssetManager {

  open static func getImage(_ name: String) -> UIImage {
    let traitCollection = UITraitCollection(displayScale: 3)
    var bundle = Bundle(for: AssetManager.self)

    if let resource = bundle.resourcePath, let resourceBundle = Bundle(path: resource + "/ImagePicker.bundle") {
      bundle = resourceBundle
    }

    return UIImage(named: name, in: bundle, compatibleWith: traitCollection) ?? UIImage()
  }

    open static func fetch(withConfiguration configuration: Configuration, _ completion: @escaping (_ fetchResult: PHFetchResult<PHAsset>?) -> Void) {    guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }

			DispatchQueue.global(qos: .background).async {

				let fetchOptions = PHFetchOptions()
				let sort = NSSortDescriptor(key: "creationDate", ascending: false)
				fetchOptions.sortDescriptors = [sort]
				fetchOptions.includeAssetSourceTypes = [.typeUserLibrary]

				let fetchResult = configuration.allowVideoSelection ? PHAsset.fetchAssets(with: fetchOptions) : PHAsset.fetchAssets(with: .image, options: fetchOptions)

				DispatchQueue.main.async {
					completion(fetchResult)
				}
			}
  }

  open static func resolveAsset(_ asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), resizeMode: PHImageRequestOptionsResizeMode = .fast, completion: @escaping (_ image: UIImage?) -> Void) {
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .highQualityFormat
    requestOptions.isNetworkAccessAllowed = true
		requestOptions.resizeMode = resizeMode

    imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, info in
      if let info = info, info["PHImageFileUTIKey"] == nil {
        DispatchQueue.main.async(execute: {
          completion(image)
        })
      }
    }
  }

  open static func resolveAssets(_ assets: [PHAsset], size: CGSize = CGSize(width: 720, height: 1280), resizeMode: PHImageRequestOptionsResizeMode = .fast) -> [UIImage] {
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = true
		requestOptions.resizeMode = resizeMode

    var images = [UIImage]()
    for asset in assets {
      imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
        if let image = image {
          images.append(image)
        }
      }
    }
    return images
  }
}
