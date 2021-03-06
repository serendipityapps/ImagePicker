import UIKit

// MARK: - BottomContainer autolayout

extension BottomContainerView {

  func setupConstraints() {

    for attribute: NSLayoutAttribute in [.centerX, .centerY] {
      addConstraint(NSLayoutConstraint(item: pickerButton, attribute: attribute,
        relatedBy: .equal, toItem: self, attribute: attribute,
        multiplier: 1, constant: 0))

      addConstraint(NSLayoutConstraint(item: borderPickerButton, attribute: attribute,
        relatedBy: .equal, toItem: self, attribute: attribute,
        multiplier: 1, constant: 0))
    }

    for attribute: NSLayoutAttribute in [.width, .left, .top] {
      addConstraint(NSLayoutConstraint(item: topSeparator, attribute: attribute,
        relatedBy: .equal, toItem: self, attribute: attribute,
        multiplier: 1, constant: 0))
    }

    for attribute: NSLayoutAttribute in [.width, .height] {
      addConstraint(NSLayoutConstraint(item: pickerButton, attribute: attribute,
        relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
        multiplier: 1, constant: ButtonPicker.Dimensions.buttonSize))

      addConstraint(NSLayoutConstraint(item: borderPickerButton, attribute: attribute,
        relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
        multiplier: 1, constant: ButtonPicker.Dimensions.buttonBorderSize))

			if attribute == .width {
				addConstraint(NSLayoutConstraint(item: stackView, attribute: attribute,
																				 relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
																				 multiplier: 1, constant: configuration.stackViewImageSize.width))
			}
			if attribute == .height {
				addConstraint(NSLayoutConstraint(item: stackView, attribute: attribute,
																				 relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
																				 multiplier: 1, constant: configuration.stackViewImageSize.height))
			}
    }

    addConstraint(NSLayoutConstraint(item: actionButton, attribute: .centerY,
      relatedBy: .equal, toItem: self, attribute: .centerY,
      multiplier: 1, constant: 0))
		
		addConstraint(NSLayoutConstraint(item: actionButton, attribute: .width,
																		 relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute,
																		 multiplier: 1, constant: 86))

    addConstraint(NSLayoutConstraint(item: stackView, attribute: .centerY,
      relatedBy: .equal, toItem: self, attribute: .centerY,
      multiplier: 1, constant: -2))

    let screenSize = Helper.screenSizeForOrientation()

		let actionButtonX = NSLayoutConstraint(item: actionButton, attribute: .centerX,
													 relatedBy: .equal, toItem: self, attribute: .right,
													 multiplier: 1, constant: -(screenSize.width - (ButtonPicker.Dimensions.buttonBorderSize + screenSize.width)/2)/2)
		actionButtonX.priority = UILayoutPriority(rawValue: 750)
    addConstraint(actionButtonX)

		let actionButtonToPickerMinimum = NSLayoutConstraint(item: actionButton, attribute: .left,
																												 relatedBy: .greaterThanOrEqual, toItem: pickerButton, attribute: .right,
																												 multiplier: 1, constant: 12)
		addConstraint(actionButtonToPickerMinimum)


		let stackViewX = NSLayoutConstraint(item: stackView, attribute: .centerX,
																				relatedBy: .equal, toItem: self, attribute: .left,
																				multiplier: 1, constant: screenSize.width/4 - ButtonPicker.Dimensions.buttonBorderSize/3)
		stackViewX.priority = UILayoutPriority(rawValue: 750)
    addConstraint(stackViewX)

		let stackViewToPickerMinimum = NSLayoutConstraint(item: stackView, attribute: .right,
																												 relatedBy: .lessThanOrEqual, toItem: pickerButton, attribute: .left,
																												 multiplier: 1, constant: -12)
		addConstraint(stackViewToPickerMinimum)

    addConstraint(NSLayoutConstraint(item: topSeparator, attribute: .height,
      relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
      multiplier: 1, constant: 1))
  }
}

// MARK: - TopView autolayout

extension TopView {

  func setupConstraints() {
    addConstraint(NSLayoutConstraint(item: flashButton, attribute: .leading,
      relatedBy: .equal, toItem: self, attribute: .leading,
      multiplier: 1, constant: Dimensions.leftOffset))

    addConstraint(NSLayoutConstraint(item: flashButton, attribute: .centerY,
      relatedBy: .equal, toItem: self, attribute: .centerY,
      multiplier: 1, constant: 0))

    addConstraint(NSLayoutConstraint(item: flashButton, attribute: .width,
      relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute,
      multiplier: 1, constant: 86))

		addConstraint(NSLayoutConstraint(item: infoLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0))
		let leading = NSLayoutConstraint(item: infoLabel, attribute: .leading, relatedBy: .greaterThanOrEqual, toItem: flashButton, attribute: .trailing, multiplier: 1.0, constant: 0)
		leading.priority = UILayoutPriority(rawValue: 999)
		addConstraint(leading)
		let trailing = NSLayoutConstraint(item: infoLabel, attribute: .trailing, relatedBy: .greaterThanOrEqual, toItem: rotateCamera, attribute: .leading, multiplier: 1.0, constant: 0)
		trailing.priority = UILayoutPriority(rawValue: 999)
		addConstraint(trailing)
		addConstraint(NSLayoutConstraint(item: infoLabel, attribute: .centerY,
																		 relatedBy: .equal, toItem: self, attribute: .centerY,
																		 multiplier: 1, constant: 0))

    if configuration.canRotateCamera {
      addConstraint(NSLayoutConstraint(item: self, attribute: .trailing,
        relatedBy: .equal, toItem: rotateCamera, attribute: .trailing,
        multiplier: 1, constant: Dimensions.rightOffset))

      addConstraint(NSLayoutConstraint(item: rotateCamera, attribute: .centerY,
        relatedBy: .equal, toItem: self, attribute: .centerY,
        multiplier: 1, constant: 0))

      addConstraint(NSLayoutConstraint(item: rotateCamera, attribute: .width,
        relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
        multiplier: 1, constant: 55))

      addConstraint(NSLayoutConstraint(item: rotateCamera, attribute: .height,
        relatedBy: .equal, toItem: nil, attribute: .notAnAttribute,
        multiplier: 1, constant: 55))
    }
  }
}

extension ImageGalleryViewCell {

  func setupConstraints() {

    for attribute: NSLayoutAttribute in [.width, .height, .centerX, .centerY] {
      addConstraint(NSLayoutConstraint(item: imageView, attribute: attribute,
        relatedBy: .equal, toItem: self, attribute: attribute,
        multiplier: 1, constant: 0))

      addConstraint(NSLayoutConstraint(item: selectedImageView, attribute: attribute,
        relatedBy: .equal, toItem: self, attribute: attribute,
        multiplier: 1, constant: 0))
    }
  }
}

extension ButtonPicker {

  func setupConstraints() {
    let attributes: [NSLayoutAttribute] = [.centerX, .centerY]

    for attribute in attributes {
      addConstraint(NSLayoutConstraint(item: numberLabel, attribute: attribute,
        relatedBy: .equal, toItem: self, attribute: attribute,
        multiplier: 1, constant: 0))
    }
  }
}
