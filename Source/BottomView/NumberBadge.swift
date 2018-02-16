//
//  NumberView.swift
//  ImagePicker-iOS
//
//  Created by David Roberts on 16/02/2018.
//  Copyright © 2018 Hyper Interaktiv AS. All rights reserved.
//

import Foundation
import UIKit

class NumberBadge: UIView {

	var forceHidden = false {
		didSet {
			setOwnState()
		}
	}

	var numberLabel: UILabel!

	var badgeValue: Int = 0 {
		didSet {
			overrideBadgeWithString = self.numberFormatter.string(from: NSNumber(value: Int32(badgeValue)))
		}
	}

	var overrideBadgeWithString: String? {
		didSet {
			if let overrideString = overrideBadgeWithString {
				numberLabel.text = overrideString
			} else {
				numberLabel.text = ""
			}
			setOwnState()
		}
	}

	func setOwnState() {

		if (((self.numberLabel.text?.characters.count)! > 0 && self.numberLabel.text != "0") && !self.forceHidden) == true {
			self.alpha = 1
		} else {
				self.alpha = 0
		}

		numberLabel.invalidateIntrinsicContentSize()
		self.invalidateIntrinsicContentSize()
		self.layoutIfNeeded()
	}

	var badgeTextColor : UIColor? {
		didSet {
			if let textColor = badgeTextColor {
				numberLabel.textColor = textColor
			} else {
				numberLabel.textColor = UIColor.white
			}
		}
	}

	var badgeBackgroundColor : UIColor? {
		didSet {
			if let badgeBackgroundColor = badgeBackgroundColor {
				self.backgroundColor = badgeBackgroundColor
			} else {
				self.backgroundColor = UIColor.red
			}
		}
	}

	var badgeFont : UIFont? {
		didSet {
			if let badgeFont = badgeFont {
				numberLabel.font = badgeFont
			} else {
				numberLabel.font = UIFont.boldSystemFont(ofSize: defaultTextSize)
			}
		}
	}

	fileprivate let defaultTextSize : CGFloat = 13

	fileprivate var numberFormatter : NumberFormatter!

	override init(frame: CGRect) {
		super.init(frame: frame)

		self.numberFormatter = NumberFormatter()
		self.numberFormatter.groupingSeparator = ","
		self.numberFormatter.usesGroupingSeparator = true

		self.setup()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

	}

	fileprivate func setup() {

		self.numberLabel = UILabel(frame: CGRect.zero)
		self.numberLabel.numberOfLines = 1
		numberLabel.textAlignment = .center
		numberLabel.frame = self.bounds
		numberLabel.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(numberLabel)

		let top = NSLayoutConstraint(item: numberLabel, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0)
		let leading = NSLayoutConstraint(item: numberLabel, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0)

		let trailing = NSLayoutConstraint(item: numberLabel, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0)
		let bottom = NSLayoutConstraint(item: numberLabel, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0)

		NSLayoutConstraint.activate([trailing, bottom, top, leading])

		self.clipsToBounds = true
		self.alpha = 0

		self.badgeBackgroundColor = nil
		self.badgeTextColor = nil
		self.badgeFont = nil

		self.backgroundColor = UIColor.clear

		self.layer.cornerRadius = self.bounds.size.height/2
	}

	override var intrinsicContentSize : CGSize {

			let size = numberLabel.intrinsicContentSize

			var newSize = size
			newSize.width += 8.0

			if newSize.width < 22 {
				newSize.width = 22
			}
			if newSize.height < 22 {
				newSize.height = 22
			}
			return newSize
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		self.layer.cornerRadius = self.bounds.size.height/2
	}
}
