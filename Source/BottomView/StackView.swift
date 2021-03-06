import UIKit
import Photos

protocol ImageStackViewDelegate: class {
  func imageStackViewDidPress()
}

class ImageStackView: UIView {

  weak var delegate: ImageStackViewDelegate?
	let configuration: Configuration

  lazy var activityView: UIActivityIndicatorView = {
    let view = UIActivityIndicatorView()
    view.alpha = 0.0

    return view
    }()

	var numberBadgeXConstraint: NSLayoutConstraint!
	var numberBadgeYConstraint: NSLayoutConstraint!

  lazy var views: [UIImageView] = {
    var array = [UIImageView]()
    for _ in 0...self.configuration.numberOfImagesAllowedInStackView {
      let view = UIImageView()
      view.layer.cornerRadius = self.configuration.stackViewCornerRadius
      view.layer.borderColor = self.configuration.photosToUseBorderColor.cgColor
      view.layer.borderWidth = self.configuration.stackViewBorderWidth
      view.contentMode = .scaleAspectFill
      view.clipsToBounds = true
      view.alpha = 0
      array.append(view)
    }
    return array
    }()

	lazy var imageCountBadge: NumberBadge = {

		let badge = NumberBadge(frame: CGRect.zero)
		badge.badgeBackgroundColor = self.configuration.numberBadgeBackgroundColor
		badge.badgeFont = self.configuration.numberBadgeFont
		badge.badgeTextColor = self.configuration.numberBadgeTextColor
		return badge
	}()

  // MARK: - Initializers


	required init(frame: CGRect, configuration: Configuration = Configuration()) {
		self.configuration = configuration
    super.init(frame: frame)

    subscribe()

    views.forEach { addSubview($0) }

		imageCountBadge.translatesAutoresizingMaskIntoConstraints = false
		addSubview(imageCountBadge)
		numberBadgeXConstraint = NSLayoutConstraint(item: imageCountBadge, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: -5)
		addConstraint(numberBadgeXConstraint)
		numberBadgeYConstraint = NSLayoutConstraint(item: imageCountBadge, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -self.configuration.stackViewImageSize.height)
		addConstraint(numberBadgeYConstraint)

    addSubview(activityView)
    views.first?.alpha = 1
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Helpers

  func subscribe() {
    NotificationCenter.default.addObserver(self,
      selector: #selector(imageDidPush(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.imageDidPush),
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(imageStackDidChangeContent(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.imageDidDrop),
      object: nil)

    NotificationCenter.default.addObserver(self,
      selector: #selector(imageStackDidChangeContent(_:)),
      name: NSNotification.Name(rawValue: ImageStack.Notifications.stackDidReload),
      object: nil)
  }

  override func layoutSubviews() {
    let step: CGFloat = configuration.stackViewStepOffset
    let scale: CGFloat = 0.8
    let viewSize = CGSize(width: frame.width * scale,
      height: frame.height * scale)

    let offset = -step * CGFloat(views.count)
    var origin = CGPoint(x: offset, y: offset)

    for view in views {
      origin.x += step
      origin.y += step
      view.frame = CGRect(origin: origin, size: viewSize)
    }
  }

  func startLoader() {
    if let firstVisibleView = views.filter({ $0.alpha == 1.0 }).last {
      activityView.frame.origin.x = firstVisibleView.center.x
      activityView.frame.origin.y = firstVisibleView.center.y
    }

    activityView.startAnimating()
    UIView.animate(withDuration: 0.3, animations: {
      self.activityView.alpha = 1.0
    })
  }
}

extension ImageStackView {

  @objc func imageDidPush(_ notification: Notification) {
    let emptyView = views.filter { $0.image == nil }.first

    if let emptyView = emptyView {
      animateImageView(emptyView)
    }

    if let sender = notification.object as? ImageStack {
      renderViews(sender.assets)
			imageCountBadge.updateCount(count: sender.assets.count, animated: true)
			if let firstView = views.first {
				numberBadgeYConstraint.constant = -firstView.bounds.size.height
			}
      activityView.stopAnimating()
    }

  }

  @objc func imageStackDidChangeContent(_ notification: Notification) {
    if let sender = notification.object as? ImageStack {
      renderViews(sender.assets)
			imageCountBadge.updateCount(count: sender.assets.count, animated: true)
			if let firstView = views.first {
				numberBadgeYConstraint.constant = -firstView.bounds.size.height
			}
      activityView.stopAnimating()
    }
  }

  @objc func renderViews(_ assets: [PHAsset]) {
    if let firstView = views.first, assets.isEmpty {
      views.forEach {
        $0.image = nil
        $0.alpha = 0
      }

      firstView.alpha = 1
      return
    }

    let photos = Array(assets.suffix(self.configuration.numberOfImagesAllowedInStackView))

    for (index, view) in views.enumerated() {
      if index <= photos.count - 1 {
        AssetManager.resolveAsset(photos[index], size: configuration.stackViewImageSize) { (image, localIdentifier) in
					view.image = image?.image
        }
        view.alpha = 1
      } else {
        view.image = nil
        view.alpha = 0
      }

      if index == photos.count {
        UIView.animate(withDuration: 0.3, animations: {
          self.activityView.frame.origin = CGPoint(x: view.center.x + 3, y: view.center.x + 3)
        })
      }
    }
  }

  fileprivate func animateImageView(_ imageView: UIImageView) {
    imageView.transform = CGAffineTransform(scaleX: 0, y: 0)

    UIView.animate(withDuration: 0.3, animations: {
      imageView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
      }, completion: { _ in
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
          self.activityView.alpha = 0.0
          imageView.transform = CGAffineTransform.identity
          }, completion: { _ in
            self.activityView.stopAnimating()
        })
    })
  }
}
