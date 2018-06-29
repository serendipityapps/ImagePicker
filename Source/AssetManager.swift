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

			DispatchQueue.global(qos: .background).async {

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

			DispatchQueue.global(qos: .userInteractive).async {
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

  open static func resolveAssets(_ assets: [PHAsset], size: CGSize = CGSize(width: 720, height: 1280), resizeMode: PHImageRequestOptionsResizeMode = .fast) -> [ImagePickerImage] {
    let imageManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.isSynchronous = true
		requestOptions.resizeMode = resizeMode

    var images = [ImagePickerImage]()
    for asset in assets {
			let location = asset.location
      imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: requestOptions) { image, _ in
        if let image = image {
					let imagePickerImage = ImagePickerImage(image: image, location: location)
          images.append(imagePickerImage)
        }
      }
    }
    return images
  }

	open static func resolveAssets(_ assets: [PHAsset], imagesClosers: @escaping ([ImagePickerImage])->()) {

		let imageManager = PHImageManager.default()
		   let requestOptions = PHImageRequestOptions()
		   requestOptions.isSynchronous = true

		   var imagesData = [ImagePickerImage]()

		   if !assets.isEmpty {
				for asset in assets {
						let options = PHContentEditingInputRequestOptions()
				     options.isNetworkAccessAllowed = true
						asset.requestContentEditingInput(with: options) { (contentEditingInput: PHContentEditingInput?, _) -> Void in

				        let optionsRequest = PHImageRequestOptions()
								optionsRequest.version = .original
								optionsRequest.isSynchronous = true

				       if asset.location == nil {
				           //Image without location and exif data (like screenshots)
				            let targetSize = ImagePickerController.photoQuality == AVCaptureSession.Preset.photo ? PHImageManagerMaximumSize : CGSize(width: 720, height: 1280)
				           imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: optionsRequest) { image, _ in
				             if let image = image {
			                imagesData.append((image, asset.location))
				                if (imagesData.count == assets.count) {
				                 imagesClosers(imagesData)
				                }
				              }
				            }
				         } else {
				           ////Image with location and exif data
				           imageManager.requestImageData(for: asset, options: optionsRequest, resultHandler: { (data, string, orientation, info) in
				             if let data = data, let image = UIImage(data: data) {

											let imagePickerImage = ImagePickerImage(image: image, location: contentEditingInput!.location)
				               imagesData.append(imagePickerImage)
				               if (imagesData.count == assets.count) {
				                 imagesClosers(imagesData)
				                }
				              }
				           })
				         }
				       }
				     }
		   } else {
		     imagesClosers(imagesData)
			    }
		  }
}
