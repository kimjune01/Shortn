//
//  TimelineScroller.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit

class TimelineScroller: UIViewController, TimelineControl {
  static let defaultHeight: CGFloat = 80
  var delegate: TimelineControlDelegate?
  unowned var composition: SpliceComposition
  var scrubbingState: ScrubbingState = .notScrubbing
  
  var thumbnailsViewController: ThumbnailsViewController!
  
  init(composition: SpliceComposition) {
    self.composition = composition
    self.thumbnailsViewController = ThumbnailsViewController(composition: composition)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(thumbnailsViewController.view)
    thumbnailsViewController.scrollDelegate = self
  }
  
  func appearIncluding() {
    
  }
  
  func appearNeutral() {
    
  }
  
  func renderFreshAssets() {
      
  }
  
  func startExpandingSegment() {
      
  }
  
  func expandingSegment() -> UIView? {
    return UIView()
  }
  
  func firstSegment() -> UIView? {
    return UIView()
  }
  
  func stopExpandingSegment() {
    
  }
  
  func updateSegmentsForSplices() {
    
  }
  
}

extension TimelineScroller: UIScrollViewDelegate {
  
}
