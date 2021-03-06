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

	open static func fetch(allowVideoSelection: Bool, _ completion: @escaping (_ fetchResult: PHFetchResult<PHAsset>?) -> Void) {    guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }

		DispatchQueue.global(qos: .userInitiated).async {

			let fetchOptions = PHFetchOptions()
			let sort = NSSortDescriptor(key: "creationDate", ascending: false)
			fetchOptions.sortDescriptors = [sort]
			fetchOptions.includeAssetSourceTypes = [.typeUserLibrary]

			let fetchResult = allowVideoSelection ? PHAsset.fetchAssets(with: fetchOptions) : PHAsset.fetchAssets(with: .image, options: fetchOptions)

			DispatchQueue.main.async {
				completion(fetchResult)
			}
		}
	}

    open static func resolveAsset(_ asset: PHAsset, size: CGSize = CGSize(width: 720, height: 1280), resizeMode: PHImageRequestOptionsResizeMode = .fast, completion: @escaping (_ image: ImagePickerImage?, _ assetLocalIdentifier: String) -> Void) {

		DispatchQueue.global(qos: .userInitiated).async {
			let imageManager = PHImageManager.default()
			let requestOptions = PHImageRequestOptions()
			requestOptions.deliveryMode = .highQualityFormat
			requestOptions.isNetworkAccessAllowed = true
			requestOptions.resizeMode = resizeMode
			requestOptions.version = .current
			requestOptions.isSynchronous = true

			let location = asset.location
			let localIdentifier = asset.localIdentifier

			imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, info in
				DispatchQueue.main.async(execute: {

					if let image = image {
						let imagePickerImage = ImagePickerImage(image: image, location: location)
						completion(imagePickerImage, localIdentifier)
					} else {
						completion(nil, localIdentifier)
					}
				})
			}
		}
	}
}
