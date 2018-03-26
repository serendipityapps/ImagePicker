import Foundation
import AVFoundation
import PhotosUI

protocol CameraManDelegate: class {
  func cameraManNotAvailable(_ cameraMan: CameraMan)
  func cameraManDidStart(_ cameraMan: CameraMan)
	func cameraManDidStop(_ cameraMan: CameraMan)
  func cameraMan(_ cameraMan: CameraMan, didChangeInput input: AVCaptureDeviceInput)
}

class CameraMan {
  weak var delegate: CameraManDelegate?

  let session = AVCaptureSession()
  let queue = DispatchQueue(label: "no.hyper.ImagePicker.Camera.SessionQueue")

  var backCamera: AVCaptureDeviceInput?
  var frontCamera: AVCaptureDeviceInput?
  var stillImageOutput: AVCaptureStillImageOutput?
  var startOnFrontCamera: Bool = false

  deinit {
    stop()
  }

  // MARK: - Setup

  func setup(_ startOnFrontCamera: Bool = false) {
    self.startOnFrontCamera = startOnFrontCamera
  }

  func setupDevices() {
    // Input
    AVCaptureDevice
    .devices()
    .filter {
      return $0.hasMediaType(AVMediaType.video)
    }.forEach {
      switch $0.position {
      case .front:
        self.frontCamera = try? AVCaptureDeviceInput(device: $0)
      case .back:
        self.backCamera = try? AVCaptureDeviceInput(device: $0)
      default:
        break
      }
    }

    // Output
    stillImageOutput = AVCaptureStillImageOutput()
    stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
  }

  func addInput(_ input: AVCaptureDeviceInput) {
    configurePreset(input)

    if session.canAddInput(input) {
      session.addInput(input)

      DispatchQueue.main.async {
        self.delegate?.cameraMan(self, didChangeInput: input)
      }
    }
  }

  // MARK: - Permission

  func checkPermission() {
    let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)

    switch status {
    case .authorized:
      start()
    case .notDetermined:
      requestPermission()
    default:
      delegate?.cameraManNotAvailable(self)
    }
  }

  func requestPermission() {
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
      DispatchQueue.main.async {
        if granted {
          self.start()
        } else {
          self.delegate?.cameraManNotAvailable(self)
        }
      }
    }
  }

  // MARK: - Session

  var currentInput: AVCaptureDeviceInput? {
    return session.inputs.first as? AVCaptureDeviceInput
  }

  fileprivate func start() {
    // Devices
    setupDevices()

    guard let input = (self.startOnFrontCamera) ? frontCamera ?? backCamera : backCamera, let output = stillImageOutput else { return }

    addInput(input)

    if session.canAddOutput(output) {
      session.addOutput(output)
    }

    queue.async {
      self.session.startRunning()

      DispatchQueue.main.async {
        self.delegate?.cameraManDidStart(self)
      }
    }

		let currentFlashIndex: Int
		if UserDefaults.standard.object(forKey: "com.app.ImagePickerCameraFlashMode") == nil {
			currentFlashIndex = 2
			UserDefaults.standard.set(2, forKey: "com.app.ImagePickerCameraFlashMode")
		} else {
			currentFlashIndex = UserDefaults.standard.integer(forKey: "com.app.ImagePickerCameraFlashMode")
		}

		let mode: AVCaptureDevice.FlashMode
		switch currentFlashIndex {
		case 0:
			mode = .off
		case 1:
			mode = .on
		case 2:
			mode = .auto
		default:
			mode = .auto
		}
		flash(mode)
  }

  func stop() {
		self.configure {
			for input in session.inputs {
				session.removeInput(input)
			}
			for output in session.outputs {
				session.removeOutput(output)
			}
		}
		self.frontCamera = nil
		self.backCamera = nil
		self.stillImageOutput = nil
		queue.async {
			self.session.stopRunning()
			DispatchQueue.main.async {
				self.delegate?.cameraManDidStop(self)
			}
		}
  }

  func switchCamera(_ completion: (() -> Void)? = nil) {
    guard let currentInput = currentInput
      else {
        completion?()
        return
    }

    queue.async {
      guard let input = (currentInput == self.backCamera) ? self.frontCamera : self.backCamera
        else {
          DispatchQueue.main.async {
            completion?()
          }
          return
      }

      self.configure {
        self.session.removeInput(currentInput)
        self.addInput(input)
      }

      DispatchQueue.main.async {
        completion?()
      }
    }
  }

    func takePhoto(_ previewLayer: AVCaptureVideoPreviewLayer, videoOrientation: AVCaptureVideoOrientation, location: CLLocation?, cropRect: CGRect?, completion: (() -> Void)? = nil) {    guard let connection = stillImageOutput?.connection(with: AVMediaType.video) else {
			completion?()
			return
		}

        connection.videoOrientation = videoOrientation

    queue.async {
      self.stillImageOutput?.captureStillImageAsynchronously(from: connection) { buffer, error in
        guard let buffer = buffer, error == nil && CMSampleBufferIsValid(buffer),
          let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer),
          let image = UIImage(data: imageData)
          else {
            DispatchQueue.main.async {
              completion?()
            }
            return
        }

				func fixImageOrientation(image: UIImage) -> UIImage? {

					guard image.imageOrientation != .up else {
						return image
					}

					var transform = CGAffineTransform.identity

					switch image.imageOrientation {

					case .down, .downMirrored:

						transform = transform.translatedBy(x: image.size.width, y: image.size.height)
						transform = transform.rotated(by: CGFloat.pi)

					case .left, .leftMirrored:

						transform = transform.translatedBy(x: image.size.width, y: 0)
						transform = transform.rotated(by: CGFloat.pi / 2)

					case .right, .rightMirrored:

						transform = transform.translatedBy(x: 0, y: image.size.height)
						transform = transform.rotated(by: -(CGFloat.pi / 2))

					default:
						break
					}

					switch image.imageOrientation {

					case .upMirrored, .downMirrored:

						transform.translatedBy(x: image.size.width, y: 0)
						transform.scaledBy(x: -1, y: 1)

					case .leftMirrored, .rightMirrored:

						transform.translatedBy(x: image.size.height, y: 0)
						transform.scaledBy(x: -1, y: 1)

					default:
						break
					}

					guard let cgImage = image.cgImage else {
						return nil
					}

					let ctx: CGContext = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

					ctx.concatenate(transform)

					switch image.imageOrientation {
					case .left, .leftMirrored, .right, .rightMirrored:
						ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
					default:
						ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
					}

					guard let newCGImage = ctx.makeImage() else {
						return nil
					}

					return UIImage(cgImage: newCGImage)
				}

				if let cropRect = cropRect {
					
					let originalSize: CGSize
					let outputRect = previewLayer.metadataOutputRectConverted(fromLayerRect: cropRect)
					
					if (image.imageOrientation == UIImageOrientation.left || image.imageOrientation == UIImageOrientation.right) {
						originalSize = CGSize(width: image.size.height, height: image.size.width)
					} else {
						originalSize = image.size
					}
					
					let visualCropRect: CGRect = CGRect(x: outputRect.origin.x * originalSize.width, y: outputRect.origin.y * originalSize.height, width: outputRect.size.width * originalSize.width, height: outputRect.size.height * originalSize.height).integral
					
					if let visualCgImage = image.cgImage?.cropping(to: visualCropRect) {
						let visualImage = UIImage(cgImage: visualCgImage, scale: 1.0, orientation: image.imageOrientation)
						
						if let fixedForOrientation = fixImageOrientation(image: visualImage) {
							self.savePhoto(fixedForOrientation, location: location, completion: completion)
						} else {
							fatalError("oops")
						}
					} else {
						fatalError("oops")
					}
				} else {
					if let fixedForOrientation = fixImageOrientation(image: image) {
						self.savePhoto(fixedForOrientation, location: location, completion: completion)
					} else {
						fatalError("oops")
					}
				}
      }
    }
  }

  func savePhoto(_ image: UIImage, location: CLLocation?, completion: (() -> Void)? = nil) {
    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
      request.creationDate = Date()
      request.location = location
      }, completionHandler: { (_, _) in
        DispatchQueue.main.async {
          completion?()
        }
    })
  }

  func flash(_ mode: AVCaptureDevice.FlashMode) {
    guard let device = currentInput?.device, device.isFlashModeSupported(mode) else { return }

    queue.async {
      self.lock {
        device.flashMode = mode
      }
    }
  }

  func focus(_ point: CGPoint) {
    guard let device = currentInput?.device, device.isFocusModeSupported(AVCaptureDevice.FocusMode.locked), device.isFocusPointOfInterestSupported else { return }

    queue.async {
      self.lock {
        device.focusPointOfInterest = point
				device.focusMode = .autoFocus
      }
    }
  }

  func zoom(_ zoomFactor: CGFloat) {
    guard let device = currentInput?.device, device.position == .back else { return }

    queue.async {
      self.lock {
        device.videoZoomFactor = zoomFactor
      }
    }
  }

  // MARK: - Lock

  func lock(_ block: () -> Void) {
    if let device = currentInput?.device, (try? device.lockForConfiguration()) != nil {
      block()
      device.unlockForConfiguration()
    }
  }

  // MARK: - Configure
  func configure(_ block: () -> Void) {
    session.beginConfiguration()
    block()
    session.commitConfiguration()
  }

  // MARK: - Preset

  func configurePreset(_ input: AVCaptureDeviceInput) {
    for asset in preferredPresets() {
      if input.device.supportsSessionPreset(AVCaptureSession.Preset(rawValue: asset)) && self.session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: asset)) {
        self.session.sessionPreset = AVCaptureSession.Preset(rawValue: asset)
        return
      }
    }
  }

  func preferredPresets() -> [String] {
    return [
      AVCaptureSession.Preset.photo.rawValue,
      AVCaptureSession.Preset.high.rawValue,
      AVCaptureSession.Preset.low.rawValue
    ]
  }
}
