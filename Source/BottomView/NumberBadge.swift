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

	var numberLabel: UILabel!

	func updateCount(count: Int, animated: Bool) {
		if badgeValue == 0 {
			if count > 0 {
				self.numberLabel.text = "\(count)"
				badgeValue = count
				numberLabel.invalidateIntrinsicContentSize()
				self.invalidateIntrinsicContentSize()
				self.layoutIfNeeded()
				if animated {
					self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
					UIView.animate(withDuration: 0.3, animations: {
						self.transform = CGAffineTransform.identity
						self.alpha = 1
					})

				} else {
					self.transform = CGAffineTransform.identity
					self.alpha = 1
				}
			}
		} else {
			if count == 0 {
				if animated {
					self.transform = CGAffineTransform.identity
					UIView.animate(withDuration: 0.3, animations: {
						self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
						self.alpha = 0
					}) { (success) in
						self.badgeValue = count
						self.numberLabel.text = ""
						self.numberLabel.invalidateIntrinsicContentSize()
						self.layoutIfNeeded()
					}
				} else {
					self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
					self.alpha = 0
					badgeValue = count
					self.numberLabel.text = ""
					numberLabel.invalidateIntrinsicContentSize()
					self.layoutIfNeeded()
				}
			} else {
				self.badgeValue = count
				self.numberLabel.text = "\(count)"
				numberLabel.invalidateIntrinsicContentSize()
				self.layoutIfNeeded()
			}
		}
	}
	var badgeValue: Int = 0

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

	override init(frame: CGRect) {
		super.init(frame: frame)

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
		newSize.width += 10.0

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
