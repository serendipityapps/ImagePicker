import UIKit

enum ActionButtonState: Int {
	case cancel
	case done
}

protocol BottomContainerViewDelegate: class {

  func pickerButtonDidPress()
  func doneButtonDidPress()
  func cancelButtonDidPress()
  func imageStackViewDidPress()
}

open class BottomContainerView: UIView {

  struct Dimensions {
    static let height: CGFloat = 101
  }

  var configuration = Configuration()

  lazy var pickerButton: ButtonPicker = { [unowned self] in
    let pickerButton = ButtonPicker(configuration: self.configuration)
    pickerButton.setTitleColor(self.configuration.cameraShutterControlTextColor, for: UIControlState())
    pickerButton.delegate = self
    pickerButton.numberLabel.isHidden = !self.configuration.showsImageCountLabel

    return pickerButton
    }()

  lazy var borderPickerButton: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.clear
    view.layer.borderColor = self.configuration.cameraShutterControlBackgroundColor.cgColor
    view.layer.borderWidth = ButtonPicker.Dimensions.borderWidth
    view.layer.cornerRadius = ButtonPicker.Dimensions.buttonBorderSize / 2
    return view
    }()
	
	open lazy var actionButton: UIButton = { [unowned self] in
		let button = UIButton()
		button.setTitle(self.configuration.cancelButtonTitle, for: UIControlState())
		button.setTitleColor(self.configuration.cancelButtonTextColor, for: UIControlState())
		button.titleLabel?.font = self.configuration.doneButtonFont
		button.addTarget(self, action: #selector(actionButtonDidPress(_:)), for: .touchUpInside)
		button.backgroundColor = self.configuration.cancelButtonBackgroundColor
		button.tintColor = self.configuration.cancelButtonTextColor
		button.tag = ActionButtonState.cancel.rawValue
		button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
		button.clipsToBounds = true
		return button
		}()

	lazy var stackView = ImageStackView(frame: CGRect(x: 0, y: 0, width: 80, height: 80), configuration: self.configuration)

  lazy var topSeparator: UIView = { [unowned self] in
    let view = UIView()
    view.backgroundColor = self.configuration.backgroundColor

    return view
    }()

  lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(handleTapGestureRecognizer(_:)))

    return gesture
    }()

  weak var delegate: BottomContainerViewDelegate?
  var pastCount = 0

  // MARK: Initializers

  public init(configuration: Configuration? = nil) {
    if let configuration = configuration {
      self.configuration = configuration
    }
    super.init(frame: .zero)
    configure()
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure() {
    [borderPickerButton, pickerButton, actionButton, stackView, topSeparator].forEach {
      addSubview($0)
      $0.translatesAutoresizingMaskIntoConstraints = false
    }

    backgroundColor = configuration.backgroundColor
    stackView.accessibilityLabel = "Image stack"
    stackView.addGestureRecognizer(tapGestureRecognizer)

    setupConstraints()
  }
	
	func configureActionButton(_ isDoneButton: Bool) {
		if isDoneButton {
			actionButton.setTitle(self.configuration.doneButtonTitle, for: UIControlState())
			actionButton.setTitleColor(self.configuration.doneButtonTextColor, for: UIControlState())
			actionButton.backgroundColor = self.configuration.doneButtonBackgroundColor
			actionButton.tintColor = self.configuration.doneButtonTextColor
			actionButton.tag = ActionButtonState.done.rawValue
		} else {
			actionButton.setTitle(self.configuration.cancelButtonTitle, for: UIControlState())
			actionButton.setTitleColor(self.configuration.cancelButtonTextColor, for: UIControlState())
			actionButton.backgroundColor = self.configuration.cancelButtonBackgroundColor
			actionButton.tintColor = self.configuration.cancelButtonTextColor
			actionButton.tag = ActionButtonState.cancel.rawValue
		}
	}

  // MARK: - Action methods

  @objc func actionButtonDidPress(_ button: UIButton) {
		if button.tag == ActionButtonState.cancel.rawValue {
			delegate?.cancelButtonDidPress()
		} else if button.tag == ActionButtonState.done.rawValue {
			delegate?.doneButtonDidPress()
		}
  }
	
  @objc func handleTapGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
    delegate?.imageStackViewDidPress()
  }

  fileprivate func animateImageView(_ imageView: UIImageView) {
    imageView.transform = CGAffineTransform(scaleX: 0, y: 0)

    UIView.animate(withDuration: 0.3, animations: {
      imageView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
      }, completion: { _ in
        UIView.animate(withDuration: 0.2, animations: {
          imageView.transform = CGAffineTransform.identity
        })
    })
  }
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		actionButton.layer.cornerRadius = actionButton.bounds.size.height/2
	}
}

// MARK: - ButtonPickerDelegate methods

extension BottomContainerView: ButtonPickerDelegate {

  func buttonDidPress() {
    delegate?.pickerButtonDidPress()
  }
}
