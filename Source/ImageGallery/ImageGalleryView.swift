import UIKit
import Photos
private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

protocol ImageGalleryUpdatedDelegate: class {
	func imageGalleryDidUpdate(_ changes: PHFetchResultChangeDetails<PHAsset>?)
}

open class ImageGalleryView: UIView, PHPhotoLibraryChangeObserver {

	var configuration = Configuration()

	weak var imageGalleryUpdateDelegate: ImageGalleryUpdatedDelegate?

  lazy open var collectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: CGRect.zero,
      collectionViewLayout: self.collectionViewLayout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = self.configuration.galleryBackgroundColor
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.dataSource = self
    collectionView.delegate = self
    return collectionView
    }()

  lazy var collectionViewLayout: UICollectionViewLayout = {
    let layout = ImageGalleryLayout(configuration: self.configuration)
    layout.scrollDirection = .horizontal
    layout.minimumInteritemSpacing = self.configuration.cellSpacing
    layout.minimumLineSpacing = self.configuration.cellSpacing
    layout.sectionInset = UIEdgeInsets(top: 0, left: configuration.cellSpacing, bottom: 0, right: configuration.cellSpacing)
    return layout
    }()

  lazy var topSeparator: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = self.configuration.gallerySeparatorColor
    return view
    }()

  open lazy var noImagesLabel: UILabel = {
    let label = UILabel()
    label.font = self.configuration.noImagesFont
    label.textColor = self.configuration.noImagesTextColor
    label.text = self.configuration.noImagesTitle
    label.alpha = 0
    label.sizeToFit()
    self.addSubview(label)
    return label
    }()

  open lazy var selectedStack = ImageStack()
  public lazy var assets = [PHAsset]()

  var collectionSize: CGSize?
  var shouldTransform = false
	public var fetchResult: PHFetchResult<PHAsset>?
  public var imageLimit = 0

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

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  func configure() {
    backgroundColor = configuration.galleryBackgroundColor

		self.configuration.registerCollectionViewCell(in: collectionView)

    [collectionView, topSeparator].forEach { addSubview($0) }

    topSeparator.addSubview(configuration.indicatorView)
  }

  // MARK: - Layout

  open override func layoutSubviews() {
    super.layoutSubviews()
    updateNoImagesLabel()
  }

  func updateFrames() {
    topSeparator.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: configuration.galleryBarHeight)
    topSeparator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleWidth]
    configuration.indicatorView.frame = CGRect(x: (self.bounds.size.width - configuration.indicatorWidth) / 2, y: (topSeparator.frame.height - configuration.indicatorHeight) / 2,
      width: configuration.indicatorWidth, height: configuration.indicatorHeight)
    collectionView.frame = CGRect(x: 0, y: topSeparator.frame.height, width: self.bounds.size.width, height: self.bounds.size.height - topSeparator.frame.height)
    collectionSize = CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
    noImagesLabel.center = CGPoint(x: bounds.width / 2, y: (bounds.height + configuration.galleryBarHeight) / 2)

    collectionView.reloadData()
  }

	func updateNoImagesLabel() {
		let height = bounds.height
		let threshold = configuration.galleryBarHeight * 2

		UIView.animate(withDuration: 0.25, animations: {
			if threshold > height || self.collectionView.alpha != 0 {
				self.noImagesLabel.alpha = 0
			} else {
				self.noImagesLabel.alpha = 1
				self.noImagesLabel.center = CGPoint(x: self.bounds.width / 2, y: (height + self.configuration.galleryBarHeight) / 2)
				self.noImagesLabel.alpha = (height > threshold) ? 1 : (height - self.configuration.galleryBarHeight) / threshold
			}
		})
	}

	// MARK: - Photos handler

	func stopBeingInterestedInPhotos() {
		PHPhotoLibrary.shared().unregisterChangeObserver(self)
		self.fetchResult = nil
		self.collectionView.reloadData()
		self.collectionView.alpha = 0
		self.noImagesLabel.alpha = 0
	}

	func fetchPhotos(_ completion: (() -> Void)? = nil) {

		AssetManager.fetch(withConfiguration: configuration) { [weak self] (fetchResult) in

			guard let strongSelf = self, let fetchResult = fetchResult else { return }

			strongSelf.fetchResult = fetchResult

			strongSelf.collectionView.reloadData()

			if fetchResult.count == 0 {
				strongSelf.updateNoImagesLabel()
			} else {
				UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: {
					strongSelf.collectionView.alpha = 1
					strongSelf.updateNoImagesLabel()
				}, completion: { (_) in

				})
			}

			PHPhotoLibrary.shared().register(strongSelf)

			completion?()
		}
	}

	func checkIfNoImagesLabelShouldBeDisplayed() {

		guard let fetchResult = fetchResult else {
			collectionView.alpha = 0
			updateNoImagesLabel()
			return
		}

		if fetchResult.count > 0 {
			collectionView.alpha = 1
		} else {
			collectionView.alpha = 0
		}
		updateNoImagesLabel()
	}

	public func photoLibraryDidChange(_ changeInstance: PHChange) {

		guard let fetchResult = fetchResult else {
			return
		}

		DispatchQueue.main.sync {
			// Check for changes to the list of assets (insertions, deletions, moves, or updates).
			if let changes = changeInstance.changeDetails(for: fetchResult) {
				// Keep the new fetch result for future use.
				self.fetchResult = changes.fetchResultAfterChanges
				if changes.hasIncrementalChanges {
					// If there are incremental diffs, animate them in the collection view.
					collectionView.performBatchUpdates({
						// For indexes to make sense, updates must be in this order:
						// delete, insert, reload, move
						if let removed = changes.removedIndexes, removed.count > 0 {
							collectionView.deleteItems(at: removed.map { IndexPath(item: $0, section:0) })
						}
						if let inserted = changes.insertedIndexes, inserted.count > 0 {
							collectionView.insertItems(at: inserted.map { IndexPath(item: $0, section:0) })
						}
						if let changed = changes.changedIndexes, changed.count > 0 {
							collectionView.reloadItems(at: changed.map { IndexPath(item: $0, section:0) })
						}
						changes.enumerateMoves { fromIndex, toIndex in
							self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
																					 to: IndexPath(item: toIndex, section: 0))
						}
					})
				} else {
					// Reload the collection view if incremental diffs are not available.
					collectionView.reloadData()
				}

				imageGalleryUpdateDelegate?.imageGalleryDidUpdate(changes)
				checkIfNoImagesLabelShouldBeDisplayed()
			}
		}
	}
}

// MARK: CollectionViewFlowLayout delegate methods

extension ImageGalleryView: UICollectionViewDelegateFlowLayout {

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
      guard let collectionSize = collectionSize else { return CGSize.zero }

      return collectionSize
  }
}

// MARK: CollectionView delegate methods

extension ImageGalleryView: UICollectionViewDelegate {

  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
   	self.configuration.imageGalleryView(self, collectionView, didSelectItemAt: indexPath)
  }
}
