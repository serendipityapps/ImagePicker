//
//  OverlayView.swift
//  ImagePicker-iOS
//
//  Created by David Roberts on 24/11/2017.
//  Copyright © 2017 Hyper Interaktiv AS. All rights reserved.
//

import Foundation
import UIKit

class OverlayView: UIView {

	@IBOutlet weak var viewPortContainerView: UIView!
	@IBOutlet weak var topleftImageView: UIImageView!
	@IBOutlet weak var topRightImageView: UIImageView!
	@IBOutlet weak var bottomleftImageView: UIImageView!
	@IBOutlet weak var bottomRightImageView: UIImageView!

	override func awakeFromNib() {
		super.awakeFromNib()

		self.setup()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	private func setup() {

		topRightImageView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
		bottomleftImageView.transform = CGAffineTransform(rotationAngle: -CGFloat(Double.pi/2))
		bottomRightImageView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
	}
}
