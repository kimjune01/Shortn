//
//  ThumbnailCollectionView.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit
import AVFoundation


// A horizontal thumbnail collection view with un-interactable cells.
// responsible for generating the thumbnails and reporting its scrollable position.
class ThumbnailsViewController: UIViewController {
  static let defaultHeight: CGFloat = 60
  var collectionView: UICollectionView!
  weak var scrollDelegate: UIScrollViewDelegate?
  unowned var composition: SpliceComposition
  var clipsThumbnails: [[Thumbnail]] = []
  var estimatedWidth: CGFloat {
    let estimatedWindowWidth = UIScreen.main.bounds.width
    return estimatedWindowWidth - UIView.defaultEdgeMargin * 2
  }
  fileprivate let cellRegistration = UICollectionView.CellRegistration<ThumbnailCell, Thumbnail>{
    cell, _, item in
    cell.image = item.image
//    cell.constraints.forEach{$0.isActive = false}
    let width = 0.1 * ThumbnailCell.defaultWidth
    let widthConstraint = cell.widthAnchor.constraint(equalToConstant: width)
    widthConstraint.priority = .defaultHigh
    widthConstraint.isActive = true
  }
  fileprivate lazy var dataSource = {
    return UICollectionViewDiffableDataSource<Int, Thumbnail>(collectionView: collectionView) {
      collectionView, indexPath, item -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(
        using: self.cellRegistration, for: indexPath, item: item)
    }
  }()
  lazy var layout: UICollectionViewCompositionalLayout = {
    let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(ThumbnailCell.defaultWidth),
                                          heightDimension: .absolute(ThumbnailsViewController.defaultHeight))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                           heightDimension: .absolute(ThumbnailsViewController.defaultHeight))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                   subitems: [item])
    group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    let section = NSCollectionLayoutSection(group: group)
    let config = UICollectionViewCompositionalLayoutConfiguration()
    config.scrollDirection = .horizontal
    config.interSectionSpacing = 0
    let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
    return layout
  }()

  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addCollectionView()
    generateThumbnails()
    refreshSnapshot()
  }
  
  func addCollectionView() {
    collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
    collectionView.alwaysBounceVertical = false
    collectionView.alwaysBounceHorizontal = false
    collectionView.backgroundColor = .white
    collectionView.delegate = self
    view.addSubview(collectionView)
    collectionView.fillWidthOfParent()
    collectionView.pinBottomToParent()
    collectionView.centerXInParent()
    collectionView.set(height: ThumbnailsViewController.defaultHeight)
    collectionView.contentInset = UIEdgeInsets(top: 0, left: estimatedWidth / 2, bottom: 0, right: 0)
  }
  
  func pixelWidth(for asset: AVAsset) -> CGFloat {
    return asset.duration.seconds / TimelineScrollConfig.secondsPerSpan * estimatedWidth
  }
  
  func numberOfCells(for asset: AVAsset) -> Int {
    let cellsCount = pixelWidth(for: asset) / ThumbnailCell.defaultWidth
    return Int(cellsCount.rounded(.up))
  }
  
  func thumbnailsPerSpan() -> CGFloat {
    return estimatedWidth / ThumbnailCell.defaultWidth
  }
  
  func generateThumbnails() {
    func makeThumbnails(for asset: AVAsset) -> [Thumbnail] {
      let sampleInterval = TimelineScrollConfig.secondsPerSpan / thumbnailsPerSpan()
      return asset.makeThumbnails(every:sampleInterval)
    }
    clipsThumbnails = composition.assets.map{makeThumbnails(for:$0)}
  }
  
  func refreshSnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Thumbnail>()
    snapshot.appendSections(Array(0..<clipsThumbnails.count))
    for i in 0..<clipsThumbnails.count {
      let thumbnails = clipsThumbnails[i]
      snapshot.appendItems(thumbnails, toSection: i)
    }
    dataSource.apply(snapshot, animatingDifferences: false)
  }
  
  
  func calculateContentWidth() -> CGFloat {
    // seconds / (seconds / span) * (pixels/span)
    return CGFloat(composition.totalDuration) / TimelineScrollConfig.secondsPerSpan * estimatedWidth
  }
  
  func numberOfCells(for section: Int) -> Int {
    let asset = composition.assets[section]
    let sectionWidth = CGFloat(asset.duration.seconds / TimelineScrollConfig.secondsPerSpan * estimatedWidth)
    let cellsPerSection = sectionWidth / ThumbnailCell.defaultWidth
    return Int(cellsPerSection.rounded(.up))
  }
}

extension ThumbnailsViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let asset = composition.assets[indexPath.section]
    let sectionWidth = CGFloat(asset.duration.seconds / TimelineScrollConfig.secondsPerSpan * estimatedWidth)
    let cellsPerSection = sectionWidth / ThumbnailCell.defaultWidth
    let isFullWidth = indexPath.row <= Int(cellsPerSection.rounded(.down))
    if isFullWidth {
      return CGSize(width: ThumbnailCell.defaultWidth, height: collectionView.height)
    } else {
      let remainder = cellsPerSection - cellsPerSection.rounded(.down)
      return CGSize(width: ThumbnailCell.defaultWidth * remainder, height: collectionView.height)
    }
  }
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
}

class ThumbnailCell: UICollectionViewCell {
  static let defaultWidth: CGFloat = 30
  private let imageView = UIImageView()
  var image: UIImage? {
    didSet {
      imageView.image = image
    }
  }
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(imageView)
    imageView.fillParent()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    backgroundColor = .systemYellow
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
