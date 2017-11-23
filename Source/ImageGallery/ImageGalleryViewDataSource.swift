import UIKit

extension ImageGalleryView: UICollectionViewDataSource {

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    displayNoImagesMessage(assets.isEmpty)
    return assets.count
  }

  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return self.configuration.imageGalleryView(self, collectionView, cellForItemAt: indexPath)
  }
}
