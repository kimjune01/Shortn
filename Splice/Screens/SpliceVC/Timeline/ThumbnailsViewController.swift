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
  var scrollView: UIScrollView!
  weak var scrollDelegate: UIScrollViewDelegate?
  unowned var composition: SpliceComposition
  var clipsThumbnails: [[Thumbnail]] = []
  var defaultThumbnailSize: CGSize {
    return CGSize(width: ThumbnailCell.defaultWidth,
                  height: ThumbnailsViewController.defaultHeight)
  }
  var estimatedWidth: CGFloat {
    let estimatedWindowWidth = UIScreen.main.bounds.width
    return estimatedWindowWidth - UIView.defaultEdgeMargin * 2
  }
  var totalScrollableWidth: CGFloat = 0
  init(composition: SpliceComposition) {
    self.composition = composition
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addScrollView()
    generateThumbnails()
  }
  
  func addScrollView() {
    scrollView = UIScrollView()
    scrollView.alwaysBounceVertical = false
    scrollView.alwaysBounceHorizontal = false
    scrollView.bounces = false
    scrollView.backgroundColor = .white
    scrollView.delegate = self
    view.addSubview(scrollView)
    scrollView.fillWidthOfParent()
    scrollView.pinBottomToParent()
    scrollView.centerXInParent()
    scrollView.set(height: ThumbnailsViewController.defaultHeight)
    scrollView.contentInset = UIEdgeInsets(top: 0, left: estimatedWidth / 2,
                                           bottom: 0, right: estimatedWidth / 2)
  }
  
  func refreshImageViews() {
    for eachSubview in scrollView.subviews {
      eachSubview.removeFromSuperview()
    }
    var currentX: CGFloat = 0
    for thumbnails in clipsThumbnails {
      for thumb in thumbnails {
        let width = ThumbnailCell.defaultWidth * thumb.widthPortion
        let imageView = UIImageView(frame: CGRect(x: currentX, y: 0,
                                                  width: width,
                                                  height: ThumbnailsViewController.defaultHeight))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = thumb.image
        scrollView.addSubview(imageView)
        currentX += width
      }
    }
    totalScrollableWidth = currentX
    scrollView.contentSize = CGSize(width: currentX, height: ThumbnailsViewController.defaultHeight)
    scrollView.contentOffset = CGPoint(x: -scrollView.contentInset.left, y: 0)
  }
  
  func currentPixelPosition() -> CGFloat {
    return scrollView.contentOffset.x + scrollView.contentInset.left
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
      return asset.makeThumbnails(every:sampleInterval, size: defaultThumbnailSize)
    }
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      self.clipsThumbnails = self.composition.assets.map{makeThumbnails(for:$0)}
      DispatchQueue.main.async {
        self.refreshImageViews()
      }
    }
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

extension ThumbnailsViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    print(currentPixelPosition())
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
