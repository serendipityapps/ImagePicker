import UIKit

protocol ButtonPickerDelegate: class {

  func buttonDidPress()
}

class ButtonPicker: UIButton {

  struct Dimensions {
    static let borderWidth: CGFloat = 2
    static let buttonSize: CGFloat = 58
    static let buttonBorderSize: CGFloat = 68
  }

	let configuration: Configuration

  lazy var numberLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = self.configuration.numberLabelFont
    return label
    }()

  weak var delegate: ButtonPickerDelegate?

  // MARK: - Initializers

  public init(configuration: Configuration? = nil) {
    if let configuration = configuration {
      self.configuration = configuration
		} else {
			self.configuration = Configuration()
		}
    super.init(frame: .zero)
    configure()
  }

  override init(frame: CGRect) {
		self.configuration = Configuration()
    super.init(frame: frame)
    configure()
  }

  func configure() {
    addSubview(numberLabel)

		numberLabel.alpha = 0

    subscribe()
    setupButton()
    setupConstraints()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func subscribe() {
    NotificationCenter.default.addObserver(self,
      selector: #selector(recalculatePhotosCount(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.imageDidPush),
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(recalculatePhotosCount(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.imageDidDrop),
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(recalculatePhotosCount(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.stackDidReload),
      object: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Configuration

  func setupButton() {
    setBackgroundColor(self.configuration.cameraShutterControlBackgroundColor, for: .normal)
		setBackgroundColor(self.configuration.cameraShutterControlHighlightBackgroundColor, for: .highlighted)
		setTitleColor(self.configuration.cameraShutterControlTextColor, for: .normal)
		numberLabel.textColor = self.configuration.cameraShutterControlTextColor
    layer.cornerRadius = Dimensions.buttonSize / 2
		self.clipsToBounds = true
    accessibilityLabel = "Take photo"
    addTarget(self, action: #selector(pickerButtonDidPress(_:)), for: .touchUpInside)
    addTarget(self, action: #selector(pickerButtonDidHighlight(_:)), for: .touchDown)
		addTarget(self, action: #selector(pickerButtonDidCancel(_:)), for: .touchUpOutside)
		addTarget(self, action: #selector(pickerButtonDidCancel(_:)), for: .touchCancel)
		addTarget(self, action: #selector(pickerButtonDidCancel(_:)), for: .touchDragOutside)
  }

  // MARK: - Actions

  @objc func recalculatePhotosCount(_ notification: Notification) {
    guard let sender = notification.object as? ImageStack else { return }
    numberLabel.text = sender.assets.isEmpty ? "" : String(sender.assets.count)
  }

  @objc func pickerButtonDidPress(_ button: UIButton) {
    numberLabel.sizeToFit()
    delegate?.buttonDidPress()
  }

  @objc func pickerButtonDidHighlight(_ button: UIButton) {
		
  }
	
	@objc func pickerButtonDidCancel(_ button: UIButton) {
		
	}
}
