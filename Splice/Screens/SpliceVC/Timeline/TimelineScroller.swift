//
//  TimelineScroller.swift
//  Shortn
//
//  Created by June Kim on 11/20/21.
//

import UIKit
import Combine

class TimelineScroller: UIViewController, TimelineControl {
  static let defaultHeight: CGFloat = 80
  var delegate: TimelineControlDelegate?
  unowned var composition: SpliceComposition
  var scrubbingState: ScrubbingState = .notScrubbing
  var thumbnailsViewController: ThumbnailsViewController!
  var intervalsViewController: IntervalsViewController!
  var spliceState: SpliceState = .initial {
    didSet {
      
    }
  }
  var displayLink: CADisplayLink!

  let seekerBar = UIView()
  var subscriptions = Set<AnyCancellable>()

  init(composition: SpliceComposition) {
    self.composition = composition
    self.thumbnailsViewController = ThumbnailsViewController(composition: composition)
    self.intervalsViewController = IntervalsViewController(composition: composition)
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addThumbnailsVC()
    addIntervalsVC()
    addSeekerBar()
    observeTimer()
    subscribeToDisplayLink()
  }
  
  func addThumbnailsVC() {
    thumbnailsViewController.delegate = self
    addChild(thumbnailsViewController)
    view.addSubview(thumbnailsViewController.view)
    thumbnailsViewController.didMove(toParent: self)
    thumbnailsViewController.view.pinBottomToParent()
    thumbnailsViewController.view.fillWidthOfParent()
    thumbnailsViewController.view.set(height: ThumbnailsViewController.defaultHeight)
  }
  
  func addIntervalsVC() {
    // !!
    thumbnailsViewController.scrollView.addSubview(intervalsViewController.view)
    addChild(intervalsViewController)
    intervalsViewController.didMove(toParent: self)
  }
  
  func addSeekerBar() {
    seekerBar.backgroundColor = .white.withAlphaComponent(0.8)
    view.addSubview(seekerBar)
    seekerBar.centerXInParent()
    seekerBar.centerYAnchor.constraint(equalTo: thumbnailsViewController.view.centerYAnchor).isActive = true
    seekerBar.set(width: 3)
    seekerBar.set(height: 70)
    seekerBar.roundCorner(radius: 2, cornerCurve: .continuous)
    seekerBar.isUserInteractionEnabled = false
  }
  
  func observeTimer() {
    composition.timeSubject
      .receive(on: DispatchQueue.main)
      .sink { timeInterval in
        self.thumbnailsViewController.scrollTime(to: timeInterval)
      }.store(in: &self.subscriptions)
  }
  
  func subscribeToDisplayLink() {
    displayLink = CADisplayLink(target: self, selector: #selector(displayStep))
    displayLink.isPaused = false
    displayLink.add(to: .main, forMode: .common)
    spliceState = .neutral
  }
  
  @objc func displayStep(_ displaylink: CADisplayLink) {
    switch spliceState {
    case .including:
      let actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp)
//      currentFps = actualFramesPerSecond.rounded()
//      intervalsVC.expand(from:  rate: advanceRate)
      delegate?.synchronizePlaybackTime()
    default: break
    }
  }
  
  func appearIncluding() {
//    scrubber.isEnabled = false
//    scrubber.alpha = 0.6

  }
  
  func appearNeutral() {
//    scrubber.isEnabled = true
//    scrubber.alpha = 1
  }
  
  func renderFreshAssets() {
//    scrubber.maximumValue = Float(composition.totalDuration)
//    scrubber.setNeedsLayout()
//    scrubber.layoutIfNeeded()
//
//    segmentsVC.composition = composition
//    segmentsVC.renderFreshAssets()
//
//    waveVC.composition = composition
//    waveVC.renderFreshAssets()

  }
  
  func startExpandingSegment(startTime: TimeInterval) {
    spliceState = .including(startTime)
//    isCurrentlyExpanding = true
//    if let delegate = delegate {
//      segmentsVC.startExpandingSegment(time: delegate.currentTimeForDisplay())
//    }
    
  }
  
  func expandingSegment() -> UIView? {
    return UIView()
  }
  
  func firstSegment() -> UIView? {
    return UIView()
  }
  
  func stopExpandingSegment() {
    spliceState = .neutral

//    isCurrentlyExpanding = false
//    segmentsVC.stopExpandingSegment()
    
  }
  
  func updateSegmentsForSplices() {
    thumbnailsViewController.updateSegmentsForSplices()
  }
  
}

extension TimelineScroller: ThumbnailsViewControllerDelegate {
  func thumbnailsVCWillBeginDragging(_ thumbnailsVC: ThumbnailsViewController) {
    delegate?.timelineVCWillBeginScrubbing()
  }
  
  func thumbnailsVCDidEndDragging(_ thumbnailsVC: ThumbnailsViewController) {
    delegate?.timelineVCDidFinishScrubbing()
  }
  
  func thumbnailsVCDidScroll(_ thumbnailsVC: ThumbnailsViewController, to time: TimeInterval) {
    // send scrub event only if user initiated.
    if thumbnailsVC.scrollView.isDragging {
      delegate?.scrubberScrubbed(to: time)
    }
  }
  
  
}
