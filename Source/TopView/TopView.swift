import UIKit
import AVFoundation

protocol TopViewDelegate: class {

  func flashDidChange(_ mode: AVCaptureDevice.FlashMode)
  func rotateDeviceDidPress()
}

open class TopView: UIView {

  struct Dimensions {
    static let leftOffset: CGFloat = 8
    static let rightOffset: CGFloat = 8
    static let height: CGFloat = 34
  }

  var configuration = Configuration()

  var currentFlashIndex = 0
	lazy var flashButtonTitles: [String] = {
		return [self.configuration.flashButtonTitleAUTO, self.configuration.flashButtonTitleON, self.configuration.flashButtonTitleOFF]
	}()

  open lazy var flashButton: UIButton = {
    let button = UIButton()
    button.setImage(self.configuration.flashButtonImageAUTO, for: UIControlState())
    button.setTitle("AUTO", for: UIControlState())
    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
    button.setTitleColor(self.configuration.cameraControlTintColor, for: UIControlState())
    button.setTitleColor(self.configuration.cameraControlTintColor, for: .highlighted)
    button.titleLabel?.font = self.configuration.flashButtonFont
    button.addTarget(self, action: #selector(flashButtonDidPress(_:)), for: .touchUpInside)
    button.contentHorizontalAlignment = .left
    return button
    }()

  open lazy var rotateCamera: UIButton = {
    let button = UIButton()
    button.setImage(self.configuration.cameraRotationIconImage, for: UIControlState())
    button.addTarget(self, action: #selector(rotateCameraButtonDidPress(_:)), for: .touchUpInside)
    button.imageView?.contentMode = .center
    return button
    }()

	open lazy var infoLabel: UILabel = {
		let label = UILabel(frame: CGRect.zero)
		label.textColor = self.configuration.infoLabelTextColor
		label.font = self.configuration.infoTextLabelFont
		label.shadowColor = self.configuration.infoLabelShadowTextColor
		label.textAlignment = .center
		label.lineBreakMode = .byTruncatingTail
		label.numberOfLines = 0
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()

  weak var delegate: TopViewDelegate?

  // MARK: - Initializers

  public init(configuration: Configuration? = nil) {
    if let configuration = configuration {
      self.configuration = configuration
    }
    super.init(frame: .zero)
    configure()
  }

  override public init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }

  required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
  }

	public func updateInfoLabelText(text: String) {
		infoLabel.text = text
	}

  func configure() {
    var buttons: [UIButton] = [flashButton]

    if configuration.canRotateCamera {
      buttons.append(rotateCamera)
    }

    for button in buttons {
      button.layer.shadowColor = UIColor.black.cgColor
      button.layer.shadowOpacity = 0.5
      button.layer.shadowOffset = CGSize(width: 0, height: 1)
      button.layer.shadowRadius = 1
      button.translatesAutoresizingMaskIntoConstraints = false
      addSubview(button)
    }

		addSubview(infoLabel)

    flashButton.isHidden = configuration.flashButtonAlwaysHidden

    setupConstraints()
  }

  // MARK: - Action methods

  @objc func flashButtonDidPress(_ button: UIButton) {
    currentFlashIndex += 1
		if currentFlashIndex > 2 {
			currentFlashIndex = 0
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

		setFlashState(mode: mode)
		UserDefaults.standard.set(mode.rawValue, forKey: "com.app.ImagePickerCameraFlashMode")

    delegate?.flashDidChange(mode)
  }

	private func setFlashState(mode: AVCaptureDevice.FlashMode) {

		switch mode {
		case .auto:
			flashButton.setTitleColor(UIColor.white, for: UIControlState())
			flashButton.setTitleColor(UIColor.white, for: .highlighted)
			flashButton.setImage(self.configuration.flashButtonImageAUTO, for: UIControlState())
			flashButton.setTitle(self.configuration.flashButtonTitleAUTO, for: UIControlState())

		case .on:
			flashButton.setTitleColor(UIColor(red: 0.98, green: 0.98, blue: 0.45, alpha: 1), for: UIControlState())
			flashButton.setTitleColor(UIColor(red: 0.52, green: 0.52, blue: 0.24, alpha: 1), for: .highlighted)
			flashButton.setImage(self.configuration.flashButtonImageON, for: UIControlState())
			flashButton.setTitle(self.configuration.flashButtonTitleON, for: UIControlState())

		case .off:
			flashButton.setTitleColor(UIColor.white, for: UIControlState())
			flashButton.setTitleColor(UIColor.white, for: .highlighted)
			flashButton.setImage(self.configuration.flashButtonImageOFF, for: UIControlState())
			flashButton.setTitle(self.configuration.flashButtonTitleOFF, for: UIControlState())
		}
	}

  @objc func rotateCameraButtonDidPress(_ button: UIButton) {
    delegate?.rotateDeviceDidPress()
  }
}
